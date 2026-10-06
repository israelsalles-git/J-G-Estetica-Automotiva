from collections.abc import Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.servicos import Servico


def listar(db: Session, incluir_inativos: bool = False) -> Sequence[Servico]:
    query = select(Servico).order_by(Servico.nome)
    if not incluir_inativos:
        query = query.where(Servico.ativo.is_(True))
    return db.scalars(query).all()


def obter(db: Session, servico_id: int) -> Servico | None:
    return db.get(Servico, servico_id)


def salvar(db: Session, servico: Servico) -> Servico:
    """Insere ou atualiza o serviço e devolve o registro atualizado do banco."""
    db.add(servico)
    db.commit()
    db.refresh(servico)
    return servico
