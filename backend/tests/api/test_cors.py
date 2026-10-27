import pytest

pytestmark = pytest.mark.api

# Mesmos valores definidos no topo do conftest.py
LOCALHOST = "http://localhost:53421"
SITE = "https://site-teste.com.br"


def preflight(client, url, origem):
    """Simula a consulta prévia (OPTIONS) que o navegador faz antes da requisição real."""
    return client.options(
        url,
        headers={
            "Origin": origem,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "authorization,content-type",
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
