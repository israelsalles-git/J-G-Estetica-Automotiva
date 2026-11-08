import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.core.config import Settings, settings
from app.main import app

pytestmark = pytest.mark.api

# Mesmos valores definidos no topo do conftest.py
LOCALHOST = "http://localhost:53421"
SITE = "https://site-teste.com.br"


def preflight(client, url, origem, metodo="POST", headers="authorization,content-type"):
    """Simula a consulta prévia (OPTIONS) que o navegador faz antes da requisição real."""
    return client.options(
        url,
        headers={
            "Origin": origem,
            "Access-Control-Request-Method": metodo,
            "Access-Control-Request-Headers": headers,
        },
    )


# ---------------------------------------------------------------------------
# Preflight (OPTIONS)
# ---------------------------------------------------------------------------
class TestPreflight:
    @pytest.mark.parametrize("porta", [3000, 5000, 53421])
    def test_localhost_em_qualquer_porta_e_liberado(self, client_sem_token, porta):
        origem = f"http://localhost:{porta}"

        resposta = preflight(client_sem_token, "/servicos", origem)

        assert resposta.status_code == 200
        assert resposta.headers["access-control-allow-origin"] == origem

    def test_rota_protegida_nao_exige_token_no_preflight(self, client_sem_token):
        resposta = preflight(client_sem_token, "/clientes", LOCALHOST)

        assert resposta.status_code == 200
        assert resposta.headers["access-control-allow-origin"] == LOCALHOST
        assert "authorization" in resposta.headers["access-control-allow-headers"].lower()

    def test_origem_cadastrada_e_liberada(self, client_sem_token):
        resposta = preflight(client_sem_token, "/servicos", SITE)

        assert resposta.status_code == 200
        assert resposta.headers["access-control-allow-origin"] == SITE

    @pytest.mark.parametrize(
        "origem",
        [
            "https://malicioso.com",
            "http://localhost",  # sem porta não bate com o regex
            "http://localhost:5000.malicioso.com",
            "https://site-teste.com.br.malicioso.com",
        ],
    )
    def test_origem_nao_liberada_retorna_400(self, client_sem_token, origem):
        resposta = preflight(client_sem_token, "/servicos", origem)

        assert resposta.status_code == 400
        assert "access-control-allow-origin" not in resposta.headers

    @pytest.mark.parametrize("metodo", ["GET", "POST", "PUT", "DELETE"])
    def test_metodos_usados_pelo_site_sao_liberados(self, client_sem_token, metodo):
        resposta = preflight(client_sem_token, "/servicos", LOCALHOST, metodo=metodo)

        assert resposta.status_code == 200
        assert metodo in resposta.headers["access-control-allow-methods"]

    def test_metodo_nao_usado_e_recusado(self, client_sem_token):
        resposta = preflight(client_sem_token, "/servicos", LOCALHOST, metodo="PATCH")

        assert resposta.status_code == 400

    def test_header_fora_da_lista_e_recusado(self, client_sem_token):
        resposta = preflight(client_sem_token, "/servicos", LOCALHOST, headers="x-qualquer-coisa")

        assert resposta.status_code == 400

    def test_upload_multipart_e_liberado(self, client_sem_token):
        """O envio de fotos (POST /trabalhos) manda Authorization + Content-Type multipart."""
        resposta = preflight(client_sem_token, "/trabalhos", LOCALHOST)

        assert resposta.status_code == 200
        assert resposta.headers["access-control-allow-origin"] == LOCALHOST


# ---------------------------------------------------------------------------
# Requisições reais (header CORS na resposta)
# ---------------------------------------------------------------------------
class TestRespostas:
    def test_get_publico_tem_header(self, client_sem_token):
        resposta = client_sem_token.get("/health", headers={"Origin": LOCALHOST})

        assert resposta.status_code == 200
        assert resposta.headers["access-control-allow-origin"] == LOCALHOST

    def test_erro_404_tem_header(self, client):
        """O site precisa do header para conseguir ler a mensagem de erro."""
        resposta = client.get("/clientes/9999", headers={"Origin": LOCALHOST})

        assert resposta.status_code == 404
        assert resposta.headers["access-control-allow-origin"] == LOCALHOST

    def test_erro_422_tem_header(self, client):
        resposta = client.post("/servicos", json={}, headers={"Origin": LOCALHOST})

        assert resposta.status_code == 422
        assert resposta.headers["access-control-allow-origin"] == LOCALHOST

    def test_erro_401_tem_header(self, client_sem_token):
        resposta = client_sem_token.get("/clientes", headers={"Origin": LOCALHOST})

        assert resposta.status_code == 401
        assert resposta.headers["access-control-allow-origin"] == LOCALHOST

    def test_origem_nao_liberada_nao_recebe_header(self, client_sem_token):
        resposta = client_sem_token.get("/health", headers={"Origin": "https://malicioso.com"})

        assert resposta.status_code == 200  # a API responde; quem bloqueia é o navegador
        assert "access-control-allow-origin" not in resposta.headers

    def test_sem_origin_nao_tem_header(self, client_sem_token):
        """Chamadas fora do navegador (curl, Postman, outro servidor) não são afetadas."""
        resposta = client_sem_token.get("/health")

        assert resposta.status_code == 200
        assert "access-control-allow-origin" not in resposta.headers


# ---------------------------------------------------------------------------
# Configuração: "*" recusado em qualquer ambiente
# ---------------------------------------------------------------------------
class TestValidacaoCorsOrigins:
    @pytest.mark.parametrize("origens", [["*"], [" * "], ["https://site.com.br", "*"]])
    def test_asterisco_e_recusado(self, origens):
        with pytest.raises(ValidationError, match="não aceita"):
            Settings(cors_origins=origens)

    def test_barra_final_e_espacos_sao_removidos(self):
        config = Settings(cors_origins=[" https://site.com.br/ ", ""])

        assert config.cors_origins == ["https://site.com.br"]


# ---------------------------------------------------------------------------
# Subida da API em produção (lifespan)
# ---------------------------------------------------------------------------
def subir_api():
    """Entrar no TestClient com `with` roda o lifespan, como na subida real da API."""
    with TestClient(app):
        pass


@pytest.fixture
def producao_ok(monkeypatch):
    """Configuração válida de produção; cada teste estraga um item."""
    monkeypatch.setattr(settings, "environment", "production")
    monkeypatch.setattr(settings, "jwt_secret", "segredo-de-producao-com-pelo-menos-32-bytes")
    monkeypatch.setattr(settings, "cors_origins", [SITE])
    monkeypatch.setattr(settings, "cors_origin_regex", None)


class TestSubidaEmProducao:
    def test_configuracao_completa_sobe(self, producao_ok):
        subir_api()

    def test_sem_cors_origins_nao_sobe(self, producao_ok, monkeypatch):
        monkeypatch.setattr(settings, "cors_origins", [])

        with pytest.raises(RuntimeError, match="CORS_ORIGINS"):
            subir_api()

    def test_com_regex_ligado_nao_sobe(self, producao_ok, monkeypatch):
        monkeypatch.setattr(settings, "cors_origin_regex", r"http://localhost:\d+")

        with pytest.raises(RuntimeError, match="CORS_ORIGIN_REGEX"):
            subir_api()

    def test_regex_vazio_e_tratado_como_desligado(self, producao_ok, monkeypatch):
        """`CORS_ORIGIN_REGEX=` no .env chega como texto vazio, não como None."""
        monkeypatch.setattr(settings, "cors_origin_regex", "")

        subir_api()

    def test_environment_sem_diferenciar_maiusculas(self, producao_ok, monkeypatch):
        monkeypatch.setattr(settings, "environment", " Production ")
        monkeypatch.setattr(settings, "cors_origins", [])

        with pytest.raises(RuntimeError, match="CORS_ORIGINS"):
            subir_api()

    def test_sem_jwt_secret_continua_nao_subindo(self, producao_ok, monkeypatch):
        monkeypatch.setattr(settings, "jwt_secret", "")

        with pytest.raises(RuntimeError, match="JWT_SECRET"):
            subir_api()

    def test_desenvolvimento_sobe_com_regex_e_sem_origins(self, monkeypatch):
        monkeypatch.setattr(settings, "environment", "development")
        monkeypatch.setattr(settings, "cors_origins", [])
        monkeypatch.setattr(settings, "cors_origin_regex", r"http://localhost:\d+")

        subir_api()
