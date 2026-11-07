import pytest
from google.auth.exceptions import TransportError

from app.core.config import settings

pytestmark = pytest.mark.api

# Mesmo e-mail do usuario de teste (conftest.py).
EMAIL_ADMIN = "admin@teste.com"
CLIENT_ID = "cliente-teste.apps.googleusercontent.com"
MENSAGEM_NAO_AUTORIZADA = "Conta Google não autorizada"


@pytest.fixture
def google_configurado(monkeypatch):
    """Client ID e lista fixa de e-mails definidos só para o teste."""
    monkeypatch.setattr(settings, "google_client_id", CLIENT_ID)
    monkeypatch.setattr(settings, "google_admin_emails", [EMAIL_ADMIN])


@pytest.fixture
def google_responde(monkeypatch):
    """Troca a verificação do Google por uma resposta fixa (ou um erro)."""

    def preparar(retorno=None, erro=None):
        def falso_verify(token, request, audience):
            assert audience == CLIENT_ID
            if erro is not None:
                raise erro
            return retorno

        monkeypatch.setattr("google.oauth2.id_token.verify_oauth2_token", falso_verify)

    return preparar


def entrar(client, token="id-token-de-teste"):
    return client.post("/auth/google", json={"id_token": token})


class TestLoginGoogle:
    def test_admin_da_lista_recebe_token_e_usuario(
        self, client_sem_token, usuario, google_configurado, google_responde
    ):
        google_responde({"email": EMAIL_ADMIN, "email_verified": True})

        resposta = entrar(client_sem_token)

        assert resposta.status_code == 200
        corpo = resposta.json()
        assert corpo["token_type"] == "bearer"
        assert corpo["access_token"]
        assert corpo["usuario"]["email"] == EMAIL_ADMIN

    def test_token_gerado_serve_nas_rotas_protegidas(
        self, client_sem_token, usuario, google_configurado, google_responde
    ):
        google_responde({"email": EMAIL_ADMIN, "email_verified": True})
        token = entrar(client_sem_token).json()["access_token"]

        resposta = client_sem_token.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

        assert resposta.status_code == 200
        assert resposta.json()["email"] == EMAIL_ADMIN

    def test_lista_do_env_e_normalizada_para_minusculas(self):
        # O validador do Settings roda ao ler o .env: é ele que deixa a comparação justa.
        from app.core.config import Settings

        assert Settings.normalizar_google_admin_emails([" Admin@Teste.com ", ""]) == [
            "admin@teste.com"
        ]

    def test_email_fora_da_lista_e_recusado(
        self, client_sem_token, usuario, google_configurado, google_responde
    ):
        google_responde({"email": "estranho@gmail.com", "email_verified": True})

        resposta = entrar(client_sem_token)

        assert resposta.status_code == 401
        assert resposta.json()["detail"] == MENSAGEM_NAO_AUTORIZADA

    def test_email_nao_verificado_e_recusado(
        self, client_sem_token, usuario, google_configurado, google_responde
    ):
        google_responde({"email": EMAIL_ADMIN, "email_verified": False})

        assert entrar(client_sem_token).status_code == 401

    def test_na_lista_mas_sem_usuario_cadastrado_e_recusado(
        self, client_sem_token, google_configurado, google_responde
    ):
        # Sem a fixture `usuario`: o e-mail está na lista, mas não existe em cadusu.
        google_responde({"email": EMAIL_ADMIN, "email_verified": True})

        resposta = entrar(client_sem_token)

        assert resposta.status_code == 401
        assert resposta.json()["detail"] == MENSAGEM_NAO_AUTORIZADA

    def test_usuario_inativo_e_recusado(
        self, client_sem_token, usuario, db_session, google_configurado, google_responde
    ):
        usuario.ativo = False
        db_session.commit()
        google_responde({"email": EMAIL_ADMIN, "email_verified": True})

        assert entrar(client_sem_token).status_code == 401

    def test_token_invalido_ou_de_outro_client_id_e_recusado(
        self, client_sem_token, usuario, google_configurado, google_responde
    ):
        google_responde(erro=ValueError("Token expirado ou de outro cliente"))

        resposta = entrar(client_sem_token)

        assert resposta.status_code == 401
        assert resposta.json()["detail"] == MENSAGEM_NAO_AUTORIZADA

    def test_sem_client_id_configurado_nao_entra(
        self, client_sem_token, usuario, monkeypatch, google_responde
    ):
        monkeypatch.setattr(settings, "google_client_id", "")
        monkeypatch.setattr(settings, "google_admin_emails", [EMAIL_ADMIN])
        google_responde({"email": EMAIL_ADMIN, "email_verified": True})

        resposta = entrar(client_sem_token)

        assert resposta.status_code == 401
        assert "não está configurado" in resposta.json()["detail"]

    def test_falha_de_rede_com_o_google_vira_502(
        self, client_sem_token, usuario, google_configurado, google_responde
    ):
        google_responde(erro=TransportError("sem conexão"))

        assert entrar(client_sem_token).status_code == 502

    def test_corpo_sem_id_token_vira_422(self, client_sem_token, google_configurado):
        resposta = client_sem_token.post("/auth/google", json={})

        assert resposta.status_code == 422

    def test_login_por_senha_continua_funcionando(self, client_sem_token, usuario):
        resposta = client_sem_token.post(
            "/auth/login", json={"email": EMAIL_ADMIN, "senha": "senha-de-teste-123"}
        )

        assert resposta.status_code == 200
