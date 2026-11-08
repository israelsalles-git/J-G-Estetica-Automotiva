from collections.abc import Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import commit
from app.models.trabalhos import Trabalho


def listar(db: Session) -> Sequence[Trabalho]:
    """Mais recentes primeiro (pela data do trabalho e, em empate, pelo cadastro)."""
    query = select(Trabalho).order_by(Trabalho.data.desc().nulls_last(), Trabalho.id.desc())
    return db.scalars(query).all()


def obter(db: Session, trabalho_id: int) -> Trabalho | None:
    return db.get(Trabalho, trabalho_id)


def salvar(db: Session, trabalho: Trabalho) -> Trabalho:
    """Insere ou atualiza o trabalho e devolve o registro atualizado do banco."""
    db.add(trabalho)
    commit(db)
    db.refresh(trabalho)
    return trabalho


def remover(db: Session, trabalho: Trabalho) -> None:
    db.delete(trabalho)
    commit(db)
