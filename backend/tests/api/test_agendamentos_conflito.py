import pytest

pytestmark = pytest.mark.api

URL = "/agendamentos"
# Serviço de 60 min usado em todos os testes: 10:00 -> 11:00
INICIO = "2030-01-10T10:00:00"


def criar_servico(client, nome="Lavagem", duracao_min=60):
    return client.post("/servicos", json={"nome": nome, "duracao_min": duracao_min, "preco": "50.00"}).json()


def criar_agendamento(client, servico_id, data=INICIO, nome_cliente="João da Silva"):
    return client.post(
        URL, json={"data": data, "nome_cliente": nome_cliente, "servico_id": servico_id}
    )


@pytest.fixture
def servico(client):
    return criar_servico(client, nome="Lavagem", duracao_min=60)


class TestConflitoAoCriar:
    def test_horario_igual_retorna_409(self, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        resposta = criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="B")

        assert resposta.status_code == 409
        assert "indisponível" in resposta.json()["detail"]

    def test_horario_que_comeca_no_meio_do_outro_retorna_409(self, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        resposta = criar_agendamento(client, servico["id"], data="2030-01-10T10:30:00", nome_cliente="B")

        assert resposta.status_code == 409

    def test_servico_longo_que_engole_outro_retorna_409(self, client):
        curto = criar_servico(client, nome="Curto", duracao_min=30)
        longo = criar_servico(client, nome="Longo", duracao_min=180)
        criar_agendamento(client, curto["id"], data="2030-01-10T11:00:00", nome_cliente="A")

        # 10:00 às 13:00 engole o agendamento das 11:00
        resposta = criar_agendamento(client, longo["id"], data=INICIO, nome_cliente="B")

        assert resposta.status_code == 409

    def test_encostado_depois_do_fim_do_outro_e_permitido(self, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        # A termina às 11:00; B começa exatamente às 11:00
        resposta = criar_agendamento(client, servico["id"], data="2030-01-10T11:00:00", nome_cliente="B")

        assert resposta.status_code == 201

    def test_encostado_antes_do_inicio_do_outro_e_permitido(self, client, servico):
        criar_agendamento(client, servico["id"], data="2030-01-10T11:00:00", nome_cliente="A")

        resposta = criar_agendamento(client, servico["id"], data="2030-01-10T09:00:00", nome_cliente="B")

        assert resposta.status_code == 201

    def test_conflito_com_fuso_diferente_e_detectado(self, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        # 13:00 UTC = 10:00 em Brasília
        resposta = criar_agendamento(client, servico["id"], data="2030-01-10T13:00:00Z", nome_cliente="B")

        assert resposta.status_code == 409

    def test_conflito_nao_impede_agendamento_em_outro_dia(self, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        resposta = criar_agendamento(client, servico["id"], data="2030-01-11T10:00:00", nome_cliente="B")

        assert resposta.status_code == 201

    def test_agendamento_inativo_nao_bloqueia_mais_o_horario(self, client, servico):
        # O horário fica livre quando o agendamento é removido.
        criado = criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A").json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="B")

        assert resposta.status_code == 201


class TestConflitoAoAtualizar:
    def test_mudar_para_horario_ocupado_retorna_409(self, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")
        b = criar_agendamento(client, servico["id"], data="2030-01-10T14:00:00", nome_cliente="B").json()

        resposta = client.put(f"{URL}/{b['id']}", json={"data": INICIO})

        assert resposta.status_code == 409

    def test_conflito_ao_atualizar_nao_altera_o_registro(self, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")
        b = criar_agendamento(client, servico["id"], data="2030-01-10T14:00:00", nome_cliente="B").json()

        client.put(f"{URL}/{b['id']}", json={"data": INICIO})

        assert client.get(f"{URL}/{b['id']}").json()["data"] == "2030-01-10T14:00:00-03:00"

    def test_mantem_o_proprio_horario_sem_conflito(self, client, servico):
        a = criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A").json()

        resposta = client.put(f"{URL}/{a['id']}", json={"nome_cliente": "A2"})

        assert resposta.status_code == 200

    def test_trocar_servico_que_passa_a_conflitar_retorna_409(self, client, servico):
        # A ocupa 12:00-13:00; B (60 min) começa às 10:00 e não conflita
        criar_agendamento(client, servico["id"], data="2030-01-10T12:00:00", nome_cliente="A")
        b = criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="B").json()
        # Com 180 min, B passa a ocupar 10:00-13:00 e engole o A
        longo = criar_servico(client, nome="Longo", duracao_min=180)

        resposta = client.put(f"{URL}/{b['id']}", json={"servico_id": longo["id"]})

        assert resposta.status_code == 409


class TestHorariosOcupadosPublico:
    PATH = f"{URL}/ocupados"

    def test_lista_periodos_no_intervalo(self, client_sem_token, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        resposta = client_sem_token.get(
            self.PATH,
            params={"data_inicio": "2030-01-10T00:00:00", "data_fim": "2030-01-10T23:59:59"},
        )

        assert resposta.status_code == 200
        assert resposta.json() == [
            {"inicio": "2030-01-10T10:00:00-03:00", "fim": "2030-01-10T11:00:00-03:00"}
        ]

    def test_nao_expoe_dados_pessoais(self, client_sem_token, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="Maria Secreta")

        resposta = client_sem_token.get(
            self.PATH,
            params={"data_inicio": "2030-01-10T00:00:00", "data_fim": "2030-01-10T23:59:59"},
        )

        assert "Maria" not in resposta.text
        assert set(resposta.json()[0]) == {"inicio", "fim"}

    def test_ignora_periodos_fora_do_intervalo(self, client_sem_token, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        resposta = client_sem_token.get(
            self.PATH,
            params={"data_inicio": "2030-01-11T00:00:00", "data_fim": "2030-01-11T23:59:59"},
        )

        assert resposta.json() == []


class TestAgendamentoPublico:
    PATH = f"{URL}/publico"

    def test_cria_sem_token(self, client_sem_token, servico, agenda):
        resposta = client_sem_token.post(
            self.PATH,
            json={"data": INICIO, "nome_cliente": "João", "servico_id": servico["id"]},
        )

        assert resposta.status_code == 201
        corpo = resposta.json()
        assert corpo["nome_cliente"] == "João"
        assert corpo["servico"]["nome"] == "Lavagem"
        assert "google_event_id" not in corpo
        assert len(agenda.eventos) == 1

    def test_conflito_retorna_409(self, client_sem_token, client, servico):
        criar_agendamento(client, servico["id"], data=INICIO, nome_cliente="A")

        resposta = client_sem_token.post(
            self.PATH,
            json={"data": INICIO, "nome_cliente": "B", "servico_id": servico["id"]},
        )

        assert resposta.status_code == 409

    def test_data_passada_retorna_422(self, client_sem_token, servico):
        resposta = client_sem_token.post(
            self.PATH,
            json={"data": "2020-01-10T10:00:00", "nome_cliente": "B", "servico_id": servico["id"]},
        )

        assert resposta.status_code == 422

    def test_rota_do_painel_continua_exigindo_token(self, client_sem_token, servico):
        resposta = client_sem_token.get(URL)

        assert resposta.status_code == 401
