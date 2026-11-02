from datetime import datetime, timedelta, timezone

import jwt
import pytest

from app.core.config import settings

pytestmark = pytest.mark.api

# Mesmos valores definidos no topo do conftest.py
EMAIL = "admin@teste.com"
SENHA = "senha-de-teste-123"
MENSAGEM_GENERICA = "E-mail ou senha incorretos"


def login(client, email=EMAIL, senha=SENHA):
    """Atalho: faz o login e devolve a resposta."""
    return client.post("/auth/login", json={"email": email, "senha": senha})


def gerar_token(payload, segredo=None, algoritmo="HS256"):
    """Monta um JWT à mão, para simular tokens expirados, adulterados etc."""
    return jwt.encode(payload, segredo or settings.jwt_secret, algorithm=algoritmo)


def daqui_a(minutos):
    return datetime.now(timezone.utc) + timedelta(minutes=minutos)


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Login (POST /auth/login)
# ---------------------------------------------------------------------------
class TestLogin:
    def test_login_correto_retorna_token_e_usuario(self, client_sem_token, usuario):
        resposta = login(client_sem_token)

        assert resposta.status_code == 200
        corpo = resposta.json()
        assert corpo["token_type"] == "bearer"
        assert corpo["access_token"]
        assert corpo["usuario"] == {"id": usuario.id, "nome": "Admin Teste", "email": EMAIL}

    def test_token_do_login_acessa_rota_protegida(self, client_sem_token, usuario):
        token = login(client_sem_token).json()["access_token"]

        resposta = client_sem_token.get("/clientes", headers=bearer(token))

        assert resposta.status_code == 200

    def test_email_ignora_maiusculas_e_espacos(self, client_sem_token, usuario):
        resposta = login(client_sem_token, email="  Admin@Teste.COM ")

        assert resposta.status_code == 200

    def test_senha_errada_retorna_401(self, client_sem_token, usuario):
        resposta = login(client_sem_token, senha="senha-errada")

        assert resposta.status_code == 401
        assert resposta.json()["detail"] == MENSAGEM_GENERICA
        assert resposta.headers["www-authenticate"] == "Bearer"

    def test_email_inexistente_retorna_401_com_mesma_mensagem(self, client_sem_token, usuario):
        resposta = login(client_sem_token, email="ninguem@teste.com")

        assert resposta.status_code == 401
        assert resposta.json()["detail"] == MENSAGEM_GENERICA

    def test_usuario_inativo_retorna_401_com_mesma_mensagem(
        self, client_sem_token, usuario, db_session
    ):
        usuario.ativo = False
        db_session.commit()

        resposta = login(client_sem_token)

        assert resposta.status_code == 401
        assert resposta.json()["detail"] == MENSAGEM_GENERICA

    @pytest.mark.parametrize(
        "corpo",
        [{}, {"email": EMAIL}, {"senha": SENHA}, {"email": "", "senha": SENHA}],
    )
    def test_campos_faltando_retorna_422(self, client_sem_token, corpo):
        resposta = client_sem_token.post("/auth/login", json=corpo)

        assert resposta.status_code == 422


# ---------------------------------------------------------------------------
# Usuário logado (GET /auth/me)
# ---------------------------------------------------------------------------
class TestMe:
    def test_retorna_usuario_logado(self, client, usuario):
        resposta = client.get("/auth/me")

        assert resposta.status_code == 200
        assert resposta.json() == {"id": usuario.id, "nome": "Admin Teste", "email": EMAIL}

    def test_sem_token_retorna_401(self, client_sem_token):
        resposta = client_sem_token.get("/auth/me")

        assert resposta.status_code == 401


# ---------------------------------------------------------------------------
# Validação do token (require_auth)
# ---------------------------------------------------------------------------
class TestToken:
    def test_token_expirado_retorna_401(self, client_sem_token, usuario):
        token = gerar_token({"sub": str(usuario.id), "exp": daqui_a(-1)})

        resposta = client_sem_token.get("/auth/me", headers=bearer(token))

        assert resposta.status_code == 401

    def test_token_expirado_bloqueia_rota_existente(self, client_sem_token, usuario):
        token = gerar_token({"sub": str(usuario.id), "exp": daqui_a(-1)})

        resposta = client_sem_token.get("/clientes", headers=bearer(token))

        assert resposta.status_code == 401

    def test_token_assinado_com_outro_segredo_retorna_401(self, client_sem_token, usuario):
        token = gerar_token(
            {"sub": str(usuario.id), "exp": daqui_a(10)},
            segredo="outro-segredo-com-pelo-menos-32-bytes!!",
        )

        resposta = client_sem_token.get("/auth/me", headers=bearer(token))

        assert resposta.status_code == 401

    def test_token_malformado_retorna_401(self, client_sem_token):
        resposta = client_sem_token.get("/auth/me", headers=bearer("isso-nao-e-um-jwt"))

        assert resposta.status_code == 401

    def test_token_sem_assinatura_retorna_401(self, client_sem_token, usuario):
        token = jwt.encode({"sub": str(usuario.id), "exp": daqui_a(10)}, None, algorithm="none")

        resposta = client_sem_token.get("/auth/me", headers=bearer(token))

        assert resposta.status_code == 401

    def test_token_sem_expiracao_retorna_401(self, client_sem_token, usuario):
        token = gerar_token({"sub": str(usuario.id)})

        resposta = client_sem_token.get("/auth/me", headers=bearer(token))

        assert resposta.status_code == 401

    @pytest.mark.parametrize("sub", ["9999", "nao-e-numero"])
    def test_token_de_usuario_inexistente_retorna_401(self, client_sem_token, sub):
        token = gerar_token({"sub": sub, "exp": daqui_a(10)})

        resposta = client_sem_token.get("/auth/me", headers=bearer(token))

        assert resposta.status_code == 401

    def test_usuario_desativado_perde_acesso_com_token_valido(self, client, usuario, db_session):
        usuario.ativo = False
        db_session.commit()

        resposta = client.get("/auth/me")

        assert resposta.status_code == 401

    def test_jwt_secret_vazio_bloqueia_tudo(self, client, monkeypatch):
        monkeypatch.setattr(settings, "jwt_secret", "")

        resposta = client.get("/auth/me")

        assert resposta.status_code == 401
