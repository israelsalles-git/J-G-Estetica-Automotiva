from collections.abc import Sequence
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import commit
from app.models.agendamentos import Agendamento
from app.models.servicos import DURACAO_MAX_MIN

# Igual à duração máxima de um serviço: nenhum agendamento que começou antes disso
# pode ainda estar ocupando o período pedido.
MARGEM_SOBREPOSICAO = timedelta(minutes=DURACAO_MAX_MIN)


def listar(
    db: Session, data_inicio: datetime | None = None, data_fim: datetime | None = None
) -> Sequence[Agendamento]:
    query = select(Agendamento).order_by(Agendamento.data)
    if data_inicio is not None:
        query = query.where(Agendamento.data >= data_inicio)
    if data_fim is not None:
        query = query.where(Agendamento.data <= data_fim)
    return db.scalars(query).all()


def listar_que_podem_sobrepor(
    db: Session, data_inicio: datetime, data_fim: datetime
) -> Sequence[Agendamento]:
    """Agendamentos que começam antes de `data_fim` e não muito antes de `data_inicio`.

    A duração depende do serviço, então o filtro exato de sobreposição é feito no service.
    A margem é a duração máxima permitida para um serviço (DURACAO_MAX_MIN).
    """
    query = (
        select(Agendamento)
        .where(Agendamento.data < data_fim)
        .where(Agendamento.data >= data_inicio - MARGEM_SOBREPOSICAO)
        .order_by(Agendamento.data)
    )
    return db.scalars(query).all()


def obter(db: Session, agendamento_id: int) -> Agendamento | None:
    return db.get(Agendamento, agendamento_id)


def salvar(db: Session, agendamento: Agendamento) -> Agendamento:
    """Insere ou atualiza o agendamento e devolve o registro atualizado do banco."""
    db.add(agendamento)
    commit(db)
    db.refresh(agendamento)
    return agendamento


def remover(db: Session, agendamento: Agendamento) -> None:
    db.delete(agendamento)
    commit(db)
