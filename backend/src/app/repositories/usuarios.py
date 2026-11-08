from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import commit
from app.models.usuarios import Usuario


def obter(db: Session, usuario_id: int) -> Usuario | None:
    return db.get(Usuario, usuario_id)


def obter_por_email(db: Session, email: str) -> Usuario | None:
    return db.scalars(select(Usuario).where(Usuario.email == email)).first()


def salvar(db: Session, usuario: Usuario) -> Usuario:
    """Insere ou atualiza o usuário e devolve o registro atualizado do banco."""
    db.add(usuario)
    commit(db)
    db.refresh(usuario)
    return usuario
