import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# CORS fixo nos testes, para não depender do .env de cada pessoa. Precisa vir antes de importar
# o app: o CORS é lido uma única vez, quando o app é criado (variável de ambiente vence o .env).
os.environ["CORS_ORIGIN_REGEX"] = r"http://localhost:\d+"
os.environ["CORS_ORIGINS"] = '["https://site-teste.com.br"]'

import app.models  # noqa: E402, F401  (registra os models no Base.metadata)
from app.core.config import settings  # noqa: E402
from app.core.database import Base, get_db  # noqa: E402
from app.core.rate_limit import limiter  # noqa: E402
from app.core.security import criar_token, gerar_hash_senha  # noqa: E402
from app.integrations.google_agenda import get_agenda  # noqa: E402
from app.main import app  # noqa: E402
from app.models.usuarios import Usuario  # noqa: E402

JWT_SECRET_TESTE = "segredo-de-teste-com-pelo-menos-32-bytes"
EMAIL_TESTE = "admin@teste.com"
SENHA_TESTE = "senha-de-teste-123"
# O argon2 é lento de propósito: gera o hash uma vez só, e não a cada teste.
SENHA_HASH_TESTE = gerar_hash_senha(SENHA_TESTE)


@pytest.fixture(autouse=True)
def rate_limit_desligado(monkeypatch):
    """Desliga o rate limit em todos os testes: muitos fazem vários logins/agendamentos seguidos.

    Os testes do limite (test_rate_limit.py) religam com a fixture `rate_limit_ligado`.
    """
    monkeypatch.setattr(limiter, "enabled", False)
    limiter.reset()


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
def usuario(db_session):
    """Usuário ativo do painel, com e-mail EMAIL_TESTE e senha SENHA_TESTE."""
    usuario = Usuario(nome="Admin Teste", email=EMAIL_TESTE, senha_hash=SENHA_HASH_TESTE)
    db_session.add(usuario)
    db_session.commit()
    return usuario


@pytest.fixture
def client(db_session, agenda, usuario, monkeypatch):
    """Cliente HTTP autenticado (JWT do `usuario`), usando o banco de teste (SQLite em memória)."""
    monkeypatch.setattr(settings, "jwt_secret", JWT_SECRET_TESTE)
    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[get_agenda] = lambda: agenda
    yield TestClient(app, headers={"Authorization": f"Bearer {criar_token(usuario.id)}"})
    app.dependency_overrides.clear()


@pytest.fixture
def client_sem_token(db_session, agenda, monkeypatch):
    """Cliente HTTP sem header de autenticação."""
    monkeypatch.setattr(settings, "jwt_secret", JWT_SECRET_TESTE)
    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[get_agenda] = lambda: agenda
    yield TestClient(app)
    app.dependency_overrides.clear()
