from collections.abc import Sequence
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.agendamentos import Agendamento


def listar(
    db: Session, data_inicio: datetime | None = None, data_fim: datetime | None = None
) -> Sequence[Agendamento]:
    query = select(Agendamento).order_by(Agendamento.data)
    if data_inicio is not None:
        query = query.where(Agendamento.data >= data_inicio)
    if data_fim is not None:
        query = query.where(Agendamento.data <= data_fim)
    return db.scalars(query).all()


def obter(db: Session, agendamento_id: int) -> Agendamento | None:
    return db.get(Agendamento, agendamento_id)


def salvar(db: Session, agendamento: Agendamento) -> Agendamento:
    """Insere ou atualiza o agendamento e devolve o registro atualizado do banco."""
    db.add(agendamento)
    db.commit()
    db.refresh(agendamento)
    return agendamento


def remover(db: Session, agendamento: Agendamento) -> None:
    db.delete(agendamento)
    db.commit()
