import uuid
from collections.abc import Sequence
from datetime import date
from pathlib import Path

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.trabalhos import Trabalho
from app.repositories import trabalhos as trabalhos_repository
from app.schemas.trabalhos import TrabalhoUpdate
from app.services.exceptions import ArquivoInvalidoError, NaoEncontradoError

PASTA_TRABALHOS = "trabalhos"
TAMANHO_MAX_BYTES = 5 * 1024 * 1024

# Assinatura (magic bytes) de cada formato aceito. Não confiamos só na extensão do nome.
_FORMATOS = {
    ".jpg": lambda c: c.startswith(b"\xff\xd8\xff"),
    ".png": lambda c: c.startswith(b"\x89PNG\r\n\x1a\n"),
    ".webp": lambda c: c[:4] == b"RIFF" and c[8:12] == b"WEBP",
}


def _extensao_da_imagem(conteudo: bytes) -> str:
    """Devolve a extensão do formato detectado pelo conteúdo, ou recusa o arquivo."""
    if len(conteudo) > TAMANHO_MAX_BYTES:
        raise ArquivoInvalidoError("A foto deve ter no máximo 5 MB")
    for extensao, confere in _FORMATOS.items():
        if confere(conteudo):
            return extensao
    raise ArquivoInvalidoError("Formato de imagem não aceito. Use JPG, PNG ou WEBP")


def _caminho_completo(arquivo: str) -> Path:
    return Path(settings.upload_dir) / arquivo


def listar(db: Session) -> Sequence[Trabalho]:
    return trabalhos_repository.listar(db)


def obter(db: Session, trabalho_id: int) -> Trabalho:
    trabalho = trabalhos_repository.obter(db, trabalho_id)
    if trabalho is None:
        raise NaoEncontradoError("Trabalho não encontrado")
    return trabalho


def criar(
    db: Session,
    conteudo: bytes,
    titulo: str | None,
    descricao: str | None,
    categoria: str | None,
    data: date | None,
) -> Trabalho:
    """Valida a foto, grava no disco e registra o trabalho no banco."""
    extensao = _extensao_da_imagem(conteudo)
    arquivo = f"{PASTA_TRABALHOS}/{uuid.uuid4().hex}{extensao}"

    caminho = _caminho_completo(arquivo)
    caminho.parent.mkdir(parents=True, exist_ok=True)
    caminho.write_bytes(conteudo)
    try:
        return trabalhos_repository.salvar(
            db,
            Trabalho(
                titulo=titulo,
                descricao=descricao,
                categoria=categoria,
                data=data,
                arquivo=arquivo,
            ),
        )
    except Exception:
        # Não deixa foto solta no disco se o banco falhar.
        caminho.unlink(missing_ok=True)
        raise


def atualizar(db: Session, trabalho_id: int, dados: TrabalhoUpdate) -> Trabalho:
    """Altera só os campos de texto enviados."""
    trabalho = obter(db, trabalho_id)
    for campo, valor in dados.model_dump(exclude_unset=True).items():
        setattr(trabalho, campo, valor)
    return trabalhos_repository.salvar(db, trabalho)


def remover(db: Session, trabalho_id: int) -> None:
    """Exclui o trabalho e a foto correspondente."""
    trabalho = obter(db, trabalho_id)
    arquivo = trabalho.arquivo
    trabalhos_repository.remover(db, trabalho)
    _caminho_completo(arquivo).unlink(missing_ok=True)


def url_da_imagem(trabalho: Trabalho) -> str:
    return f"/arquivos/{trabalho.arquivo}"
