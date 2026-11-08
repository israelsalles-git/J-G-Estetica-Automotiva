from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

engine = create_engine(
    settings.database_url,
    echo=settings.debug,
    pool_pre_ping=True,
    connect_args={
        # Sem timeout, uma porta bloqueada deixa cada requisição pendurada.
        "connect_timeout": 10,
        # Compatível com o pooler em modo transação do Supabase (porta 6543).
        "prepare_threshold": None,
    },
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    expire_on_commit=False
)


class Base(DeclarativeBase):
    """Classe base de todos os models do SQLAlchemy."""


def get_db() -> Generator[Session, None, None]:
    """Dependência do FastAPI: abre uma sessão por requisição e fecha ao final."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def commit(db: Session) -> None:
    """Commit que limpa a sessão se o banco recusar (UNIQUE, CHECK, FK).

    Sem o rollback, a sessão fica inutilizável (PendingRollbackError) até o fim da requisição.
    O erro é relançado e vira HTTP 409 no handler do main.py.
    """
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise
