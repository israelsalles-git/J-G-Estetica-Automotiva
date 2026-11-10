from collections.abc import Sequence
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.integrations.google_agenda import Agenda, EventoAgenda
from app.models.agendamentos import Agendamento
from app.models.servicos import Servico
from app.repositories import agendamentos as agendamentos_repository
from app.schemas.agendamentos import AgendamentoCreate, AgendamentoUpdate, para_fuso_local
from app.services import servicos as servicos_service
from app.services.exceptions import ConflitoError, NaoEncontradoError


def _obter_servico_ativo(db: Session, servico_id: int) -> Servico:
    servico = servicos_service.obter(db, servico_id)
    if not servico.ativo:
        raise ConflitoError("Serviço inativo não pode ser agendado")
    return servico


def _intervalo(inicio: datetime, servico: Servico) -> tuple[datetime, datetime]:
    """Período que o atendimento ocupa: começa na data e dura o tempo do serviço."""
    inicio = para_fuso_local(inicio)
    return inicio, inicio + timedelta(minutes=servico.duracao_min)


def _formatar_telefone(telefone: str) -> str:
    """11912345678 -> (11) 91234-5678 | 1132345678 -> (11) 3234-5678."""
    return f"({telefone[:2]}) {telefone[2:-4]}-{telefone[-4:]}"


def _descricao_evento(agendamento: Agendamento, servico: Servico) -> str:
    linhas = [f"Cliente: {agendamento.nome_cliente}"]
    # Agendamentos anteriores à inclusão do campo não têm telefone.
    if agendamento.telefone:
        linhas.append(f"Telefone: {_formatar_telefone(agendamento.telefone)}")
        linhas.append(f"WhatsApp: https://wa.me/55{agendamento.telefone}")
    linhas.append(f"Serviço: {servico.nome}")
    return "\n".join(linhas)


def _montar_evento(agendamento: Agendamento, servico: Servico) -> EventoAgenda:
    """Evento do Google Agenda: começa na data do agendamento e dura o tempo do serviço."""
    inicio, fim = _intervalo(agendamento.data, servico)
    return EventoAgenda(
        titulo=f"{servico.nome} - {agendamento.nome_cliente}",
        inicio=inicio,
        fim=fim,
        descricao=_descricao_evento(agendamento, servico),
    )


def _ocupados_no_periodo(
    db: Session, data_inicio: datetime, data_fim: datetime, ignorar_id: int | None = None
) -> list[tuple[datetime, datetime]]:
    """Períodos (início, fim) dos agendamentos que se sobrepõem a [data_inicio, data_fim)."""
    ocupados = []
    for existente in agendamentos_repository.listar_que_podem_sobrepor(db, data_inicio, data_fim):
        if existente.id == ignorar_id:
            continue
        inicio, fim = _intervalo(existente.data, existente.servico)
        if inicio < data_fim and fim > data_inicio:
            ocupados.append((inicio, fim))
    return ocupados


def _garantir_horario_livre(
    db: Session,
    inicio: datetime,
    servico: Servico,
    ignorar_id: int | None = None,
) -> None:
    """Um atendimento por vez: recusa o horário se ele se sobrepõe a outro agendamento."""
    inicio, fim = _intervalo(inicio, servico)
    if _ocupados_no_periodo(db, inicio, fim, ignorar_id):
        raise ConflitoError("Horário indisponível: já existe um agendamento nesse período")


def listar_ocupados(
    db: Session, data_inicio: datetime, data_fim: datetime
) -> list[tuple[datetime, datetime]]:
    """Períodos ocupados no intervalo pedido, sem nenhum dado pessoal do cliente."""
    return _ocupados_no_periodo(db, data_inicio, data_fim)


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
    _garantir_horario_livre(db, dados.data, servico)
    agendamento = Agendamento(**dados.model_dump())
    agendamento.google_event_id = agenda.criar_evento(_montar_evento(agendamento, servico))
    try:
        return agendamentos_repository.salvar(db, agendamento)
    except Exception:
        # Não deixa evento solto na agenda se o banco falhar.
        if agendamento.google_event_id:
            agenda.remover_evento(agendamento.google_event_id)
        raise


def atualizar(
    db: Session, agenda: Agenda, agendamento_id: int, dados: AgendamentoUpdate
) -> Agendamento:
    """Altera só os campos enviados e realiza a mudança no Google Agenda."""
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
    # Confere o horário novo antes de mexer no registro (o próprio agendamento não conta).
    _garantir_horario_livre(
        db, alteracoes.get("data", agendamento.data), servico, ignorar_id=agendamento.id
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
