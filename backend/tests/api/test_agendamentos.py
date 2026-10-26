from datetime import datetime

import pytest

from app.models.agendamentos import Agendamento
from app.services.exceptions import IntegracaoError

pytestmark = pytest.mark.api

URL = "/agendamentos"
DATA = "2030-01-10T10:00:00"  # sem fuso: interpretada como horário de Brasília


def criar_servico(client, nome="Lavagem", duracao_min=60):
    return client.post("/servicos", json={"nome": nome, "duracao_min": duracao_min, "preco": "50.00"}).json()


def criar_agendamento(client, servico_id, data=DATA, nome_cliente="João da Silva"):
    """Atalho: cria um agendamento e devolve a resposta."""
    return client.post(
        URL, json={"data": data, "nome_cliente": nome_cliente, "servico_id": servico_id}
    )


@pytest.fixture
def servico(client):
    return criar_servico(client)


# ---------------------------------------------------------------------------
# Autenticação (todas as rotas exigem token)
# ---------------------------------------------------------------------------
class TestAutenticacao:
    @pytest.mark.parametrize(
        ("metodo", "caminho"),
        [("get", URL), ("get", f"{URL}/1"), ("post", URL), ("put", f"{URL}/1"), ("delete", f"{URL}/1")],
    )
    def test_sem_token_retorna_401(self, client_sem_token, metodo, caminho):
        resposta = client_sem_token.request(metodo, caminho, json={})

        assert resposta.status_code == 401


# ---------------------------------------------------------------------------
# Criar (POST /agendamentos)
# ---------------------------------------------------------------------------
class TestCriar:
    def test_cria_agendamento(self, client, servico):
        resposta = criar_agendamento(client, servico["id"])

        assert resposta.status_code == 201
        corpo = resposta.json()
        assert corpo["id"] > 0
        assert corpo["data"] == "2030-01-10T10:00:00-03:00"
        assert corpo["nome_cliente"] == "João da Silva"
        assert corpo["servico_id"] == servico["id"]
        assert corpo["servico"]["nome"] == "Lavagem"
        assert corpo["google_event_id"] == "evento-1"

    def test_cria_evento_na_agenda_com_duracao_do_servico(self, client, agenda):
        servico = criar_servico(client, nome="Polimento", duracao_min=90)

        criar_agendamento(client, servico["id"])

        evento = agenda.eventos["evento-1"]
        assert evento.titulo == "Polimento - João da Silva"
        assert evento.inicio.isoformat() == "2030-01-10T10:00:00-03:00"
        assert evento.fim.isoformat() == "2030-01-10T11:30:00-03:00"

    def test_data_com_outro_fuso_e_convertida(self, client, servico):
        resposta = criar_agendamento(client, servico["id"], data="2030-01-10T13:00:00Z")

        assert resposta.json()["data"] == "2030-01-10T10:00:00-03:00"

    def test_data_passada_retorna_422(self, client, servico):
        resposta = criar_agendamento(client, servico["id"], data="2020-01-10T10:00:00")

        assert resposta.status_code == 422

    def test_data_invalida_retorna_422(self, client, servico):
        resposta = criar_agendamento(client, servico["id"], data="10/01/2030")

        assert resposta.status_code == 422

    def test_nome_vazio_retorna_422(self, client, servico):
        resposta = criar_agendamento(client, servico["id"], nome_cliente="")

        assert resposta.status_code == 422

    def test_nome_maior_que_120_retorna_422(self, client, servico):
        resposta = criar_agendamento(client, servico["id"], nome_cliente="a" * 121)

        assert resposta.status_code == 422

    @pytest.mark.parametrize("campo", ["data", "nome_cliente", "servico_id"])
    def test_campo_obrigatorio_ausente_retorna_422(self, client, servico, campo):
        dados = {"data": DATA, "nome_cliente": "João", "servico_id": servico["id"]}
        del dados[campo]

        resposta = client.post(URL, json=dados)

        assert resposta.status_code == 422

    def test_servico_inexistente_retorna_404(self, client, agenda):
        resposta = criar_agendamento(client, 9999)

        assert resposta.status_code == 404
        assert resposta.json()["detail"] == "Serviço não encontrado"
        assert agenda.eventos == {}

    def test_servico_inativo_retorna_409(self, client, servico):
        client.delete(f"/servicos/{servico['id']}")

        resposta = criar_agendamento(client, servico["id"])

        assert resposta.status_code == 409

    def test_falha_na_agenda_retorna_502_e_nao_grava(self, client, agenda, servico, monkeypatch):
        def falhar(_):
            raise IntegracaoError("Não foi possível criar o evento no Google Agenda")

        monkeypatch.setattr(agenda, "criar_evento", falhar)

        resposta = criar_agendamento(client, servico["id"])

        assert resposta.status_code == 502
        assert client.get(URL).json() == []


# ---------------------------------------------------------------------------
# Listar (GET /agendamentos)
# ---------------------------------------------------------------------------
class TestListar:
    def test_lista_vazia(self, client):
        resposta = client.get(URL)

        assert resposta.status_code == 200
        assert resposta.json() == []

    def test_lista_ordenada_por_data(self, client, servico):
        criar_agendamento(client, servico["id"], data="2030-01-12T10:00:00", nome_cliente="B")
        criar_agendamento(client, servico["id"], data="2030-01-11T10:00:00", nome_cliente="A")

        resposta = client.get(URL)

        assert [a["nome_cliente"] for a in resposta.json()] == ["A", "B"]

    def test_filtra_por_periodo(self, client, servico):
        for dia in (10, 11, 12):
            criar_agendamento(client, servico["id"], data=f"2030-01-{dia}T10:00:00", nome_cliente=str(dia))

        resposta = client.get(
            URL, params={"data_inicio": "2030-01-11T00:00:00", "data_fim": "2030-01-11T23:59:59"}
        )

        assert [a["nome_cliente"] for a in resposta.json()] == ["11"]


# ---------------------------------------------------------------------------
# Obter (GET /agendamentos/{id})
# ---------------------------------------------------------------------------
class TestObter:
    def test_obtem_agendamento_existente(self, client, servico):
        criado = criar_agendamento(client, servico["id"]).json()

        resposta = client.get(f"{URL}/{criado['id']}")

        assert resposta.status_code == 200
        assert resposta.json() == criado

    def test_inexistente_retorna_404(self, client):
        resposta = client.get(f"{URL}/9999")

        assert resposta.status_code == 404
        assert resposta.json()["detail"] == "Agendamento não encontrado"


# ---------------------------------------------------------------------------
# Atualizar (PUT /agendamentos/{id})
# ---------------------------------------------------------------------------
class TestAtualizar:
    def test_altera_so_a_data(self, client, agenda, servico):
        criado = criar_agendamento(client, servico["id"]).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"data": "2030-02-01T14:00:00"})

        assert resposta.status_code == 200
        corpo = resposta.json()
        assert corpo["data"] == "2030-02-01T14:00:00-03:00"
        assert corpo["nome_cliente"] == criado["nome_cliente"]  # não enviado: permanece igual
        assert agenda.eventos["evento-1"].inicio == datetime.fromisoformat(corpo["data"])

    def test_troca_servico_atualiza_duracao_do_evento(self, client, agenda, servico):
        criado = criar_agendamento(client, servico["id"]).json()
        outro = criar_servico(client, nome="Vitrificação", duracao_min=240)

        resposta = client.put(f"{URL}/{criado['id']}", json={"servico_id": outro["id"]})

        assert resposta.json()["servico"]["nome"] == "Vitrificação"
        evento = agenda.eventos["evento-1"]
        assert evento.titulo == "Vitrificação - João da Silva"
        assert (evento.fim - evento.inicio).total_seconds() == 240 * 60

    def test_sem_evento_na_agenda_cria_ao_atualizar(self, client, agenda, servico, db_session):
        criado = criar_agendamento(client, servico["id"]).json()
        # Simula um agendamento gravado enquanto a integração estava desligada.
        db_session.get(Agendamento, criado["id"]).google_event_id = None
        db_session.commit()
        agenda.eventos.clear()

        resposta = client.put(f"{URL}/{criado['id']}", json={"nome_cliente": "Maria"})

        assert resposta.json()["google_event_id"] == "evento-2"
        assert agenda.eventos["evento-2"].titulo == "Lavagem - Maria"

    def test_corpo_vazio_nao_altera_nada(self, client, servico):
        criado = criar_agendamento(client, servico["id"]).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={})

        assert resposta.status_code == 200
        assert resposta.json() == criado

    def test_data_passada_retorna_422(self, client, servico):
        criado = criar_agendamento(client, servico["id"]).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"data": "2020-01-01T10:00:00"})

        assert resposta.status_code == 422

    def test_servico_inexistente_retorna_404(self, client, servico):
        criado = criar_agendamento(client, servico["id"]).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"servico_id": 9999})

        assert resposta.status_code == 404

    def test_inexistente_retorna_404(self, client):
        resposta = client.put(f"{URL}/9999", json={"nome_cliente": "X"})

        assert resposta.status_code == 404


# ---------------------------------------------------------------------------
# Remover (DELETE /agendamentos/{id})
# ---------------------------------------------------------------------------
class TestRemover:
    def test_remove_agendamento_e_evento(self, client, agenda, servico):
        criado = criar_agendamento(client, servico["id"]).json()

        resposta = client.delete(f"{URL}/{criado['id']}")

        assert resposta.status_code == 204
        assert resposta.content == b""
        assert client.get(f"{URL}/{criado['id']}").status_code == 404
        assert agenda.eventos == {}

    def test_inexistente_retorna_404(self, client):
        resposta = client.delete(f"{URL}/9999")

        assert resposta.status_code == 404
