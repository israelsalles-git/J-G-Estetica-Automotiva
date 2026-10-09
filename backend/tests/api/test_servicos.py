import pytest

pytestmark = pytest.mark.api

URL = "/servicos"


def criar_servico(client, nome="Lavagem", duracao_min=60, preco="50.00"):
    """Atalho: cria um serviço e devolve a resposta."""
    return client.post(URL, json={"nome": nome, "duracao_min": duracao_min, "preco": preco})


# ---------------------------------------------------------------------------
# Autenticação (leitura é pública; escrita exige token)
# ---------------------------------------------------------------------------
class TestAutenticacao:
    def test_leitura_nao_exige_token(self, client_sem_token):
        resposta = client_sem_token.get(URL)

        assert resposta.status_code == 200

    def test_criar_sem_token_retorna_401(self, client_sem_token):
        resposta = criar_servico(client_sem_token)

        assert resposta.status_code == 401

    def test_criar_com_token_invalido_retorna_401(self, client_sem_token):
        resposta = client_sem_token.post(
            URL,
            json={"nome": "Lavagem", "duracao_min": 60, "preco": "50.00"},
            headers={"Authorization": "Bearer errado"},
        )

        assert resposta.status_code == 401

    def test_atualizar_sem_token_retorna_401(self, client_sem_token):
        resposta = client_sem_token.put(f"{URL}/1", json={"nome": "X"})

        assert resposta.status_code == 401

    def test_desativar_sem_token_retorna_401(self, client_sem_token):
        resposta = client_sem_token.delete(f"{URL}/1")

        assert resposta.status_code == 401


# ---------------------------------------------------------------------------
# Criar (POST /servicos)
# ---------------------------------------------------------------------------
class TestCriar:
    def test_cria_servico(self, client):
        resposta = criar_servico(client)

        assert resposta.status_code == 201
        corpo = resposta.json()
        assert corpo["id"] > 0
        assert corpo["nome"] == "Lavagem"
        assert corpo["duracao_min"] == 60
        assert corpo["preco"] == "50.00"
        assert corpo["ativo"] is True

    def test_preco_zero_e_valido(self, client):
        resposta = criar_servico(client, preco="0")

        assert resposta.status_code == 201

    def test_sem_preco_retorna_422(self, client):
        resposta = client.post(URL, json={"nome": "Sem preço", "duracao_min": 30})

        assert resposta.status_code == 422

    def test_sem_duracao_retorna_422(self, client):
        resposta = client.post(URL, json={"nome": "Sem duração", "preco": "10.00"})

        assert resposta.status_code == 422

    def test_nome_vazio_retorna_422(self, client):
        resposta = criar_servico(client, nome="")

        assert resposta.status_code == 422

    def test_nome_maior_que_120_retorna_422(self, client):
        resposta = criar_servico(client, nome="a" * 121)

        assert resposta.status_code == 422

    @pytest.mark.parametrize("duracao", [0, -10])
    def test_duracao_nao_positiva_retorna_422(self, client, duracao):
        resposta = criar_servico(client, duracao_min=duracao)

        assert resposta.status_code == 422

    def test_preco_negativo_retorna_422(self, client):
        resposta = criar_servico(client, preco="-1.00")

        assert resposta.status_code == 422

    def test_preco_com_mais_de_2_casas_retorna_422(self, client):
        resposta = criar_servico(client, preco="10.999")

        assert resposta.status_code == 422


# ---------------------------------------------------------------------------
# Listar (GET /servicos)
# ---------------------------------------------------------------------------
class TestListar:
    def test_lista_vazia(self, client):
        resposta = client.get(URL)

        assert resposta.status_code == 200
        assert resposta.json() == []

    def test_lista_ordenada_por_nome(self, client):
        criar_servico(client, nome="Polimento")
        criar_servico(client, nome="Lavagem")

        resposta = client.get(URL)

        assert [s["nome"] for s in resposta.json()] == ["Lavagem", "Polimento"]

    def test_oculta_inativos_por_padrao(self, client):
        ativo = criar_servico(client, nome="Ativo").json()
        inativo = criar_servico(client, nome="Inativo").json()
        client.delete(f"{URL}/{inativo['id']}")

        resposta = client.get(URL)

        assert [s["id"] for s in resposta.json()] == [ativo["id"]]

    def test_incluir_inativos(self, client):
        criar_servico(client, nome="Ativo")
        inativo = criar_servico(client, nome="Inativo").json()
        client.delete(f"{URL}/{inativo['id']}")

        resposta = client.get(URL, params={"incluir_inativos": True})

        assert len(resposta.json()) == 2


# ---------------------------------------------------------------------------
# Obter (GET /servicos/{id})
# ---------------------------------------------------------------------------
class TestObter:
    def test_obtem_servico_existente(self, client):
        criado = criar_servico(client).json()

        resposta = client.get(f"{URL}/{criado['id']}")

        assert resposta.status_code == 200
        assert resposta.json() == criado

    def test_inexistente_retorna_404(self, client):
        resposta = client.get(f"{URL}/9999")

        assert resposta.status_code == 404
        assert resposta.json()["detail"] == "Serviço não encontrado"

    def test_id_nao_numerico_retorna_422(self, client):
        resposta = client.get(f"{URL}/abc")

        assert resposta.status_code == 422

    def test_inativo_ainda_pode_ser_obtido_pelo_id(self, client):
        criado = criar_servico(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.get(f"{URL}/{criado['id']}")

        assert resposta.status_code == 200
        assert resposta.json()["ativo"] is False


# ---------------------------------------------------------------------------
# Atualizar (PUT /servicos/{id})
# ---------------------------------------------------------------------------
class TestAtualizar:
    def test_altera_so_o_nome(self, client):
        criado = criar_servico(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"nome": "Lavagem completa"})

        assert resposta.status_code == 200
        corpo = resposta.json()
        assert corpo["nome"] == "Lavagem completa"
        assert corpo["duracao_min"] == criado["duracao_min"]  # não enviado: permanece igual
        assert corpo["preco"] == criado["preco"]
        assert corpo["ativo"] is True

    def test_altera_preco(self, client):
        criado = criar_servico(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"preco": "100.00"})

        assert resposta.status_code == 200
        assert resposta.json()["preco"] == "100.00"

    def test_altera_duracao(self, client):
        criado = criar_servico(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"duracao_min": 90})

        assert resposta.status_code == 200
        assert resposta.json()["duracao_min"] == 90

    def test_reativa_servico_inativo(self, client):
        criado = criar_servico(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.put(f"{URL}/{criado['id']}", json={"ativo": True})

        assert resposta.status_code == 200
        assert resposta.json()["ativo"] is True

    def test_corpo_vazio_nao_altera_nada(self, client):
        criado = criar_servico(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={})

        assert resposta.status_code == 200
        assert resposta.json() == criado

    def test_inexistente_retorna_404(self, client):
        resposta = client.put(f"{URL}/9999", json={"nome": "X"})

        assert resposta.status_code == 404

    def test_nome_vazio_retorna_422(self, client):
        criado = criar_servico(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"nome": ""})

        assert resposta.status_code == 422

    def test_duracao_invalida_retorna_422(self, client):
        criado = criar_servico(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"duracao_min": 0})

        assert resposta.status_code == 422

    def test_preco_negativo_retorna_422(self, client):
        criado = criar_servico(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"preco": "-5.00"})

        assert resposta.status_code == 422


# ---------------------------------------------------------------------------
# Desativar (DELETE /servicos/{id}) - exclusão lógica
# ---------------------------------------------------------------------------
class TestDesativar:
    def test_desativa_servico(self, client):
        criado = criar_servico(client).json()

        resposta = client.delete(f"{URL}/{criado['id']}")

        assert resposta.status_code == 204
        assert resposta.content == b""

    def test_registro_continua_existindo_como_inativo(self, client):
        criado = criar_servico(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.get(f"{URL}/{criado['id']}")

        assert resposta.json()["ativo"] is False

    def test_desativar_duas_vezes_continua_204(self, client):
        criado = criar_servico(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.delete(f"{URL}/{criado['id']}")

        assert resposta.status_code == 204

    def test_inexistente_retorna_404(self, client):
        resposta = client.delete(f"{URL}/9999")

        assert resposta.status_code == 404
