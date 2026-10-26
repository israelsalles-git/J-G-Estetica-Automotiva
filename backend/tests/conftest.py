import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import app.models  # noqa: F401  (registra os models no Base.metadata)
from app.core.config import settings
from app.core.database import Base, get_db
from app.integrations.google_agenda import get_agenda
from app.main import app

TOKEN_TESTE = "token-de-teste"


@pytest.fixture
def db_session():
    """Banco SQLite em memória, novo a cada teste (não toca no Postgres/Supabase)."""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,  # mantém a mesma conexão, senão o banco em memória some
    )

    # O CheckConstraint do model usa char_length (Postgres); no SQLite ela é `length`.
    @event.listens_for(engine, "connect")
    def _registrar_char_length(dbapi_conn, _):
        dbapi_conn.create_function("char_length", 1, lambda s: None if s is None else len(s))

    Base.metadata.create_all(engine)
    session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)()
    yield session
    session.close()
    engine.dispose()


class AgendaFake:
    """Substitui o Google Agenda nos testes, guardando os eventos em memória."""

    def __init__(self):
        self.eventos = {}
        self._proximo_id = 1

    def criar_evento(self, evento):
        evento_id = f"evento-{self._proximo_id}"
        self._proximo_id += 1
        self.eventos[evento_id] = evento
        return evento_id

    def atualizar_evento(self, evento_id, evento):
        self.eventos[evento_id] = evento

    def remover_evento(self, evento_id):
        self.eventos.pop(evento_id, None)


@pytest.fixture
def agenda():
    return AgendaFake()


@pytest.fixture
def client(db_session, agenda, monkeypatch):
    """Cliente HTTP autenticado, usando o banco de teste (SQLite em memória)."""
    monkeypatch.setattr(settings, "api_token", TOKEN_TESTE)
    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[get_agenda] = lambda: agenda
    yield TestClient(app, headers={"Authorization": f"Bearer {TOKEN_TESTE}"})
    app.dependency_overrides.clear()


@pytest.fixture
def client_sem_token(db_session, agenda, monkeypatch):
    """Cliente HTTP sem header de autenticação."""
    monkeypatch.setattr(settings, "api_token", TOKEN_TESTE)
    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[get_agenda] = lambda: agenda
    yield TestClient(app)
    app.dependency_overrides.clear()
