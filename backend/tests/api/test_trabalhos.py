from datetime import date

import pytest

from app.core.config import settings
from app.models.trabalhos import Trabalho
from app.services.trabalhos import TAMANHO_MAX_BYTES

pytestmark = pytest.mark.api

URL = "/trabalhos"

# Cabeçalhos mínimos de cada formato aceito (o resto do conteúdo não importa para a validação).
JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 100
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 100
WEBP = b"RIFF" + b"\x00\x00\x00\x00" + b"WEBPVP8 " + b"\x00" * 100


@pytest.fixture
def pasta_uploads(tmp_path, monkeypatch):
    """Redireciona os uploads para uma pasta temporária, para não sujar o projeto."""
    monkeypatch.setattr(settings, "upload_dir", tmp_path)
    return tmp_path


def enviar(client, conteudo=JPEG, nome="foto.jpg", **campos):
    return client.post(
        URL,
        files={"imagem": (nome, conteudo, "application/octet-stream")},
        data=campos,
    )


# ---------------------------------------------------------------------------
# Autenticação
# ---------------------------------------------------------------------------
class TestAutenticacao:
    @pytest.mark.parametrize(("metodo", "caminho"), [("post", URL), ("put", f"{URL}/1"), ("delete", f"{URL}/1")])
    def test_escrita_sem_token_retorna_401(self, client_sem_token, metodo, caminho):
        resposta = client_sem_token.request(metodo, caminho)

        assert resposta.status_code == 401

    def test_listagem_e_publica(self, client_sem_token):
        resposta = client_sem_token.get(URL)

        assert resposta.status_code == 200
        assert resposta.json() == []


# ---------------------------------------------------------------------------
# Enviar foto (POST /trabalhos)
# ---------------------------------------------------------------------------
class TestEnviar:
    @pytest.mark.parametrize(("conteudo", "extensao"), [(JPEG, ".jpg"), (PNG, ".png"), (WEBP, ".webp")])
    def test_aceita_formatos_permitidos(self, client, pasta_uploads, conteudo, extensao):
        resposta = enviar(client, conteudo=conteudo, nome=f"foto{extensao}")

        assert resposta.status_code == 201
        assert resposta.json()["imagem_url"].endswith(extensao)
        assert (pasta_uploads / resposta.json()["imagem_url"].split("/arquivos/", 1)[1]).read_bytes() == conteudo

    def test_grava_os_campos_de_texto(self, client, pasta_uploads):
        resposta = enviar(
            client, titulo="Vitrificação", descricao="Carro preto", categoria="Carro", data="2030-01-05"
        )

        corpo = resposta.json()
        assert corpo["titulo"] == "Vitrificação"
        assert corpo["descricao"] == "Carro preto"
        assert corpo["categoria"] == "Carro"
        assert corpo["data"] == "2030-01-05"

    def test_campos_de_texto_sao_opcionais(self, client, pasta_uploads):
        resposta = enviar(client)

        corpo = resposta.json()
        assert corpo["titulo"] is None
        assert corpo["data"] is None

    def test_recusa_arquivo_que_nao_e_imagem_mesmo_com_extensao_jpg(self, client, pasta_uploads):
        resposta = enviar(client, conteudo=b"<html>nao sou foto</html>", nome="foto.jpg")

        assert resposta.status_code == 422
        assert list(pasta_uploads.rglob("*.jpg")) == []

    def test_recusa_formato_gif(self, client, pasta_uploads):
        resposta = enviar(client, conteudo=b"GIF89a" + b"\x00" * 50, nome="foto.gif")

        assert resposta.status_code == 422

    def test_recusa_arquivo_maior_que_5_mb(self, client, pasta_uploads):
        conteudo = JPEG + b"\x00" * (TAMANHO_MAX_BYTES + 1)

        resposta = enviar(client, conteudo=conteudo)

        assert resposta.status_code == 422
        assert "5 MB" in resposta.json()["detail"]

    def test_aceita_arquivo_exatamente_no_limite(self, client, pasta_uploads):
        conteudo = JPEG + b"\x00" * (TAMANHO_MAX_BYTES - len(JPEG))

        resposta = enviar(client, conteudo=conteudo)

        assert resposta.status_code == 201

    def test_falha_no_banco_nao_deixa_foto_no_disco(self, client, pasta_uploads, monkeypatch):
        from app.repositories import trabalhos as repo

        def falhar(db, trabalho):
            raise RuntimeError("banco fora do ar")

        monkeypatch.setattr(repo, "salvar", falhar)
        with pytest.raises(RuntimeError):
            enviar(client)

        assert list(pasta_uploads.rglob("*.jpg")) == []

    def test_campo_imagem_obrigatorio(self, client):
        resposta = client.post(URL, data={"titulo": "Sem foto"})

        assert resposta.status_code == 422


# ---------------------------------------------------------------------------
# Listar (GET /trabalhos, público)
# ---------------------------------------------------------------------------
class TestListar:
    def test_mais_recentes_primeiro(self, client, client_sem_token, pasta_uploads):
        enviar(client, titulo="Antigo", data="2030-01-01")
        enviar(client, titulo="Novo", data="2030-06-01")
        enviar(client, titulo="Sem data")

        titulos = [t["titulo"] for t in client_sem_token.get(URL).json()]

        assert titulos == ["Novo", "Antigo", "Sem data"]

    def test_imagem_url_aponta_para_a_pasta_servida(self, client, client_sem_token, pasta_uploads):
        enviar(client)

        imagem_url = client_sem_token.get(URL).json()[0]["imagem_url"]

        assert imagem_url.startswith("/arquivos/trabalhos/")


# ---------------------------------------------------------------------------
# Atualizar (PUT /trabalhos/{id})
# ---------------------------------------------------------------------------
class TestAtualizar:
    def test_altera_so_os_campos_enviados(self, client, pasta_uploads):
        criado = enviar(client, titulo="Antes", categoria="Carro").json()

        resposta = client.put(f"{URL}/{criado['id']}", json={"titulo": "Depois"})

        corpo = resposta.json()
        assert corpo["titulo"] == "Depois"
        assert corpo["categoria"] == "Carro"
        assert corpo["imagem_url"] == criado["imagem_url"]

    def test_inexistente_retorna_404(self, client):
        resposta = client.put(f"{URL}/9999", json={"titulo": "X"})

        assert resposta.status_code == 404
        assert resposta.json()["detail"] == "Trabalho não encontrado"


# ---------------------------------------------------------------------------
# Remover (DELETE /trabalhos/{id})
# ---------------------------------------------------------------------------
class TestRemover:
    def test_remove_registro_e_foto(self, client, pasta_uploads):
        criado = enviar(client).json()
        arquivo = pasta_uploads / criado["imagem_url"].split("/arquivos/", 1)[1]
        assert arquivo.exists()

        resposta = client.delete(f"{URL}/{criado['id']}")

        assert resposta.status_code == 204
        assert not arquivo.exists()
        assert client.get(URL).json() == []

    def test_inexistente_retorna_404(self, client):
        resposta = client.delete(f"{URL}/9999")

        assert resposta.status_code == 404

