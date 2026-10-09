import pytest

pytestmark = pytest.mark.api

URL = "/clientes"
CPF = "12345678900"
CNPJ = "12345678000199"


def criar_cliente(client, nome="Maria", cpf_cnpj=CPF):
    """Atalho: cria um cliente e devolve a resposta."""
    return client.post(URL, json={"nome": nome, "cpf_cnpj": cpf_cnpj})


# ---------------------------------------------------------------------------
# Autenticação
# ---------------------------------------------------------------------------
class TestAutenticacao:
    def test_sem_token_retorna_401(self, client_sem_token):
        resposta = client_sem_token.get(URL)

        assert resposta.status_code == 401

    def test_token_invalido_retorna_401(self, client_sem_token):
        resposta = client_sem_token.get(URL, headers={"Authorization": "Bearer errado"})

        assert resposta.status_code == 401


# ---------------------------------------------------------------------------
# Criar (POST)
# ---------------------------------------------------------------------------
class TestCriar:
    def test_cria_cliente_com_cpf(self, client):
        resposta = criar_cliente(client)

        assert resposta.status_code == 201
        corpo = resposta.json()
        assert corpo["id"] > 0
        assert corpo["nome"] == "Maria"
        assert corpo["cpf_cnpj"] == CPF
        assert corpo["ativo"] is True

    def test_cria_cliente_com_cnpj(self, client):
        resposta = criar_cliente(client, cpf_cnpj=CNPJ)

        assert resposta.status_code == 201
        assert resposta.json()["cpf_cnpj"] == CNPJ

    def test_cria_cliente_sem_cpf_cnpj(self, client):
        resposta = client.post(URL, json={"nome": "Sem Documento"})

        assert resposta.status_code == 201
        assert resposta.json()["cpf_cnpj"] is None

    def test_remove_mascara_do_cpf(self, client):
        resposta = criar_cliente(client, cpf_cnpj="123.456.789-00")

        assert resposta.status_code == 201
        assert resposta.json()["cpf_cnpj"] == CPF

    def test_remove_mascara_do_cnpj(self, client):
        resposta = criar_cliente(client, cpf_cnpj="12.345.678/0001-99")

        assert resposta.status_code == 201
        assert resposta.json()["cpf_cnpj"] == CNPJ

    def test_cpf_duplicado_retorna_409(self, client):
        criar_cliente(client, nome="Maria")

        resposta = criar_cliente(client, nome="João")

        assert resposta.status_code == 409
        assert resposta.json()["detail"] == "Já existe um cliente com este CPF/CNPJ"

    def test_cpf_duplicado_com_mascara_diferente_retorna_409(self, client):
        criar_cliente(client, cpf_cnpj=CPF)

        resposta = criar_cliente(client, nome="João", cpf_cnpj="123.456.789-00")

        assert resposta.status_code == 409

    @pytest.mark.parametrize("cpf_cnpj", ["123", "1234567890", "123456789012", "abc"])
    def test_cpf_cnpj_com_tamanho_invalido_retorna_422(self, client, cpf_cnpj):
        resposta = criar_cliente(client, cpf_cnpj=cpf_cnpj)

        assert resposta.status_code == 422

    def test_nome_ausente_retorna_422(self, client):
        resposta = client.post(URL, json={"cpf_cnpj": CPF})

        assert resposta.status_code == 422

    def test_nome_vazio_retorna_422(self, client):
        resposta = criar_cliente(client, nome="")

        assert resposta.status_code == 422

    def test_nome_maior_que_120_retorna_422(self, client):
        resposta = criar_cliente(client, nome="a" * 121)

        assert resposta.status_code == 422


# ---------------------------------------------------------------------------
# Listar (GET /clientes)
# ---------------------------------------------------------------------------
class TestListar:
    def test_lista_vazia(self, client):
        resposta = client.get(URL)

        assert resposta.status_code == 200
        assert resposta.json() == []

    def test_lista_ordenada_por_nome(self, client):
        criar_cliente(client, nome="Carlos", cpf_cnpj=None)
        criar_cliente(client, nome="Ana", cpf_cnpj=None)
        criar_cliente(client, nome="Bruno", cpf_cnpj=None)

        resposta = client.get(URL)

        assert [c["nome"] for c in resposta.json()] == ["Ana", "Bruno", "Carlos"]

    def test_oculta_inativos_por_padrao(self, client):
        ativo = criar_cliente(client, nome="Ativo", cpf_cnpj=None).json()
        inativo = criar_cliente(client, nome="Inativo", cpf_cnpj=None).json()
        client.delete(f"{URL}/{inativo['id']}")

        resposta = client.get(URL)

        assert [c["id"] for c in resposta.json()] == [ativo["id"]]

    def test_incluir_inativos(self, client):
        criar_cliente(client, nome="Ativo", cpf_cnpj=None)
        inativo = criar_cliente(client, nome="Inativo", cpf_cnpj=None).json()
        client.delete(f"{URL}/{inativo['id']}")

        resposta = client.get(URL, params={"incluir_inativos": True})

        assert len(resposta.json()) == 2


# ---------------------------------------------------------------------------
# Obter (GET /clientes/{id})
# ---------------------------------------------------------------------------
class TestObter:
    def test_obtem_cliente_existente(self, client):
        criado = criar_cliente(client).json()

        resposta = client.get(f"{URL}/{criado['id']}")

        assert resposta.status_code == 200
        assert resposta.json() == criado

    def test_inexistente_retorna_404(self, client):
        resposta = client.get(f"{URL}/9999")

        assert resposta.status_code == 404
        assert resposta.json()["detail"] == "Cliente não encontrado"

    def test_id_nao_numerico_retorna_422(self, client):
        resposta = client.get(f"{URL}/abc")

        assert resposta.status_code == 422

    def test_inativo_ainda_pode_ser_obtido_pelo_id(self, client):
        criado = criar_cliente(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.get(f"{URL}/{criado['id']}")

        assert resposta.status_code == 200
        assert resposta.json()["ativo"] is False


# ---------------------------------------------------------------------------
# Atualizar (PUT /clientes/{id})
# ---------------------------------------------------------------------------
class TestAtualizar:
    def test_altera_so_o_nome(self, client):
        criado = criar_cliente(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"nome": "Maria Silva"})

        assert resposta.status_code == 200
        corpo = resposta.json()
        assert corpo["nome"] == "Maria Silva"
        assert corpo["cpf_cnpj"] == CPF  # não enviado: permanece igual
        assert corpo["ativo"] is True

    def test_altera_cpf_cnpj_e_normaliza(self, client):
        criado = criar_cliente(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"cpf_cnpj": "12.345.678/0001-99"})

        assert resposta.status_code == 200
        assert resposta.json()["cpf_cnpj"] == CNPJ

    def test_reativa_cliente_inativo(self, client):
        criado = criar_cliente(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.put(f"{URL}/{criado['id']}", json={"ativo": True})

        assert resposta.status_code == 200
        assert resposta.json()["ativo"] is True

    def test_manter_o_proprio_cpf_nao_gera_conflito(self, client):
        criado = criar_cliente(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"cpf_cnpj": CPF})

        assert resposta.status_code == 200

    def test_cpf_de_outro_cliente_retorna_409(self, client):
        criar_cliente(client, nome="Maria", cpf_cnpj=CPF)
        outro = criar_cliente(client, nome="João", cpf_cnpj=CNPJ).json()

        resposta = client.put(f"{URL}/{outro['id']}", json={"cpf_cnpj": CPF})

        assert resposta.status_code == 409

    def test_corpo_vazio_nao_altera_nada(self, client):
        criado = criar_cliente(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={})

        assert resposta.status_code == 200
        assert resposta.json() == criado

    def test_inexistente_retorna_404(self, client):
        resposta = client.put(f"{URL}/9999", json={"nome": "X"})

        assert resposta.status_code == 404

    def test_nome_vazio_retorna_422(self, client):
        criado = criar_cliente(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"nome": ""})

        assert resposta.status_code == 422

    def test_cpf_cnpj_invalido_retorna_422(self, client):
        criado = criar_cliente(client).json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"cpf_cnpj": "123"})

        assert resposta.status_code == 422


# ---------------------------------------------------------------------------
# Desativar (DELETE /clientes/{id}) - exclusão lógica
# ---------------------------------------------------------------------------
class TestDesativar:
    def test_desativa_cliente(self, client):
        criado = criar_cliente(client).json()

        resposta = client.delete(f"{URL}/{criado['id']}")

        assert resposta.status_code == 204
        assert resposta.content == b""

    def test_registro_continua_existindo_como_inativo(self, client):
        criado = criar_cliente(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.get(f"{URL}/{criado['id']}")

        assert resposta.json()["ativo"] is False

    def test_desativar_duas_vezes_continua_204(self, client):
        criado = criar_cliente(client).json()
        client.delete(f"{URL}/{criado['id']}")

        resposta = client.delete(f"{URL}/{criado['id']}")

        assert resposta.status_code == 204

    def test_inexistente_retorna_404(self, client):
        resposta = client.delete(f"{URL}/9999")

        assert resposta.status_code == 404
