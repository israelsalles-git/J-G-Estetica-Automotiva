from collections.abc import Sequence
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.integrations.google_agenda import Agenda, EventoAgenda
from app.models.agendamentos import Agendamento
from app.models.servicos import Servico
from app.repositories import agendamentos as agendamentos_repository
from app.schemas.agendamentos import AgendamentoCreate, AgendamentoUpdate
from app.services import servicos as servicos_service
from app.services.exceptions import ConflitoError, NaoEncontradoError


def _obter_servico_ativo(db: Session, servico_id: int) -> Servico:
    servico = servicos_service.obter(db, servico_id)
    if not servico.ativo:
        raise ConflitoError("Serviço inativo não pode ser agendado")
    return servico


def _montar_evento(agendamento: Agendamento, servico: Servico) -> EventoAgenda:
    """Evento do Google Agenda: começa na data do agendamento e dura o tempo do serviço."""
    return EventoAgenda(
        titulo=f"{servico.nome} - {agendamento.nome_cliente}",
        inicio=agendamento.data,
        fim=agendamento.data + timedelta(minutes=servico.duracao_min),
        descricao=f"Cliente: {agendamento.nome_cliente}\nServiço: {servico.nome}",
    )


def listar(
    db: Session, data_inicio: datetime | None = None, data_fim: datetime | None = None
) -> Sequence[Agendamento]:
    """Lista os agendamentos por data, opcionalmente filtrando por período."""
    return agendamentos_repository.listar(db, data_inicio, data_fim)


def obter(db: Session, agendamento_id: int) -> Agendamento:
    agendamento = agendamentos_repository.obter(db, agendamento_id)
    if agendamento is None:
        raise NaoEncontradoError("Agendamento não encontrado")
    return agendamento


def criar(db: Session, agenda: Agenda, dados: AgendamentoCreate) -> Agendamento:
    """Cria o evento no Google Agenda e depois grava o agendamento com o ID do evento."""
    servico = _obter_servico_ativo(db, dados.servico_id)
    agendamento = Agendamento(**dados.model_dump())
    agendamento.google_event_id = agenda.criar_evento(_montar_evento(agendamento, servico))
    try:
        return agendamentos_repository.salvar(db, agendamento)
    except Exception:
        # Não deixa evento órfão na agenda se o banco falhar.
        if agendamento.google_event_id:
            agenda.remover_evento(agendamento.google_event_id)
        raise


def atualizar(
    db: Session, agenda: Agenda, agendamento_id: int, dados: AgendamentoUpdate
) -> Agendamento:
    """Altera só os campos enviados e reflete a mudança no Google Agenda."""
    agendamento = obter(db, agendamento_id)
    alteracoes = dados.model_dump(exclude_unset=True, exclude_none=True)
    if not alteracoes:
        return agendamento

    servico_id = alteracoes.get("servico_id", agendamento.servico_id)
    servico = (
        _obter_servico_ativo(db, servico_id)
        if servico_id != agendamento.servico_id
        else agendamento.servico
    )
    for campo, valor in alteracoes.items():
        setattr(agendamento, campo, valor)
    agendamento.servico = servico

    evento = _montar_evento(agendamento, servico)
    if agendamento.google_event_id:
        agenda.atualizar_evento(agendamento.google_event_id, evento)
    else:
        # Agendamento criado antes de a integração ser ligada: passa a existir na agenda.
        agendamento.google_event_id = agenda.criar_evento(evento)
    return agendamentos_repository.salvar(db, agendamento)


def remover(db: Session, agenda: Agenda, agendamento_id: int) -> None:
    """Exclui o agendamento e o evento correspondente no Google Agenda."""
    agendamento = obter(db, agendamento_id)
    if agendamento.google_event_id:
        agenda.remover_evento(agendamento.google_event_id)
    agendamentos_repository.remover(db, agendamento)
