from collections.abc import Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.clientes import Cliente


def listar(db: Session, incluir_inativos: bool = False) -> Sequence[Cliente]:
    query = select(Cliente).order_by(Cliente.nome)
    if not incluir_inativos:
        query = query.where(Cliente.ativo.is_(True))
    return db.scalars(query).all()


def obter(db: Session, cliente_id: int) -> Cliente | None:
    return db.get(Cliente, cliente_id)


def obter_por_cpf_cnpj(db: Session, cpf_cnpj: str) -> Cliente | None:
    return db.scalars(select(Cliente).where(Cliente.cpf_cnpj == cpf_cnpj)).first()


def salvar(db: Session, cliente: Cliente) -> Cliente:
    """Insere ou atualiza o cliente e devolve o registro atualizado do banco."""
    db.add(cliente)
    db.commit()
    db.refresh(cliente)
    return cliente
