import pytest

from app.core.rate_limit import limiter

pytestmark = pytest.mark.api

MENSAGEM_429 = "Muitas tentativas. Aguarde um pouco e tente novamente."
EMAIL = "admin@teste.com"  # mesmo usuário da fixture `usuario` do conftest.py
SENHA = "senha-de-teste-123"


@pytest.fixture
def rate_limit_ligado(monkeypatch):
    """Religa o limite (o conftest desliga em todos os testes) com os contadores zerados."""
    monkeypatch.setattr(limiter, "enabled", True)
    limiter.reset()
    yield
    limiter.reset()


@pytest.fixture
def servico(client):
    return client.post(
        "/servicos", json={"nome": "Lavagem", "duracao_min": 30, "preco": "50.00"}
    ).json()


def agendar(client, servico_id, hora):
    """Cada chamada em um horário diferente, para não esbarrar no conflito de horário (409)."""
    return client.post(
        "/agendamentos/publico",
        json={
            "data": f"2030-01-10T{hora:02d}:00:00",
            "nome_cliente": "Cliente do site",
            "servico_id": servico_id,
        },
    )


def logar(client, senha=SENHA):
    return client.post("/auth/login", json={"email": EMAIL, "senha": senha})


# ---------------------------------------------------------------------------
# POST /agendamentos/publico: 5/minute;20/hour
# ---------------------------------------------------------------------------
class TestAgendamentoPublico:
    def test_sexta_chamada_no_minuto_retorna_429(self, client_sem_token, servico, rate_limit_ligado):
        respostas = [agendar(client_sem_token, servico["id"], hora) for hora in range(8, 14)]

        assert [r.status_code for r in respostas[:5]] == [201] * 5
        assert respostas[5].status_code == 429
        assert respostas[5].json() == {"detail": MENSAGEM_429}

    def test_429_nao_grava_o_agendamento(self, client, client_sem_token, servico, rate_limit_ligado):
        for hora in range(8, 14):
            agendar(client_sem_token, servico["id"], hora)

        assert len(client.get("/agendamentos").json()) == 5

    def test_429_tem_header_cors(self, client_sem_token, servico, rate_limit_ligado):
        """Sem o header, o site não conseguiria ler a mensagem do 429."""
        origem = "http://localhost:53421"
        for hora in range(8, 13):
            agendar(client_sem_token, servico["id"], hora)

        resposta = client_sem_token.post(
            "/agendamentos/publico",
            json={"data": "2030-01-10T14:00:00", "nome_cliente": "X", "servico_id": servico["id"]},
            headers={"Origin": origem},
        )

        assert resposta.status_code == 429
        assert resposta.headers["access-control-allow-origin"] == origem

    def test_rotas_do_painel_nao_tem_limite(self, client, servico, rate_limit_ligado):
        """O limite vale só para a rota pública; o painel (com token) não é afetado."""
        respostas = [
            client.post(
                "/agendamentos",
                json={
                    "data": f"2030-01-11T{hora:02d}:00:00",
                    "nome_cliente": "Cliente do painel",
                    "servico_id": servico["id"],
                },
            )
            for hora in range(8, 15)
        ]

        assert [r.status_code for r in respostas] == [201] * 7


# ---------------------------------------------------------------------------
# POST /auth/login: 5/minute
# ---------------------------------------------------------------------------
class TestLogin:
    def test_sexta_tentativa_errada_retorna_429(self, client_sem_token, usuario, rate_limit_ligado):
        respostas = [logar(client_sem_token, senha="senha-errada") for _ in range(6)]

        assert [r.status_code for r in respostas[:5]] == [401] * 5
        assert respostas[5].status_code == 429
        assert respostas[5].json() == {"detail": MENSAGEM_429}

    def test_bloqueia_ate_a_senha_certa_depois_do_limite(
        self, client_sem_token, usuario, rate_limit_ligado
    ):
        """Depois de 5 tentativas, nem a senha correta passa: é isso que freia a força bruta."""
        for _ in range(5):
            logar(client_sem_token, senha="senha-errada")

        assert logar(client_sem_token).status_code == 429

    def test_logins_validos_tambem_contam(self, client_sem_token, usuario, rate_limit_ligado):
        respostas = [logar(client_sem_token) for _ in range(6)]

        assert [r.status_code for r in respostas[:5]] == [200] * 5
        assert respostas[5].status_code == 429


# ---------------------------------------------------------------------------
# POST /auth/google: 10/minute
# ---------------------------------------------------------------------------
class TestLoginGoogle:
    def test_decima_primeira_chamada_retorna_429(self, client_sem_token, rate_limit_ligado):
        # Corpo inválido (422) não chega na rota, então não conta; um id_token qualquer conta.
        respostas = [
            client_sem_token.post("/auth/google", json={"id_token": "token-qualquer"})
            for _ in range(11)
        ]

        assert all(r.status_code != 429 for r in respostas[:10])
        assert respostas[10].status_code == 429
        assert respostas[10].json() == {"detail": MENSAGEM_429}


# ---------------------------------------------------------------------------
# Isolamento entre testes
# ---------------------------------------------------------------------------
def test_limite_desligado_por_padrao_nos_outros_testes(client_sem_token, usuario):
    """Garante que o conftest desliga o limite: sem `rate_limit_ligado`, não há 429."""
    respostas = [logar(client_sem_token, senha="senha-errada") for _ in range(7)]

    assert all(r.status_code == 401 for r in respostas)
