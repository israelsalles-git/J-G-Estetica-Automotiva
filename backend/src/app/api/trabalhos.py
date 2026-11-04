from datetime import date

from fastapi import APIRouter, Depends, File, Form, Response, UploadFile, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_auth
from app.schemas.trabalhos import TrabalhoRead, TrabalhoUpdate
from app.services import trabalhos as trabalhos_service
from app.services.trabalhos import TAMANHO_MAX_BYTES

# Listagem pública: o site mostra a galeria sem login.
router_publico = APIRouter(prefix="/trabalhos", tags=["trabalhos (site)"])

# Cadastro, alteração e exclusão: só o painel admin.
router = APIRouter(
    prefix="/trabalhos", tags=["trabalhos"], dependencies=[Depends(require_auth)]
)


def _para_leitura(trabalho) -> dict:
    return {
        "id": trabalho.id,
        "titulo": trabalho.titulo,
        "descricao": trabalho.descricao,
        "categoria": trabalho.categoria,
        "data": trabalho.data,
        "imagem_url": trabalhos_service.url_da_imagem(trabalho),
    }


@router_publico.get("", response_model=list[TrabalhoRead])
def listar_trabalhos(db: Session = Depends(get_db)):
    """Lista os trabalhos da galeria, do mais recente para o mais antigo"""
    return [_para_leitura(t) for t in trabalhos_service.listar(db)]


@router.post("", response_model=TrabalhoRead, status_code=status.HTTP_201_CREATED)
async def cadastrar_trabalho(
    imagem: UploadFile = File(..., description="Foto em JPG, PNG ou WEBP (até 5 MB)"),
    titulo: str | None = Form(None, max_length=120),
    descricao: str | None = Form(None, max_length=500),
    categoria: str | None = Form(None, max_length=60),
    data: date | None = Form(None),
    db: Session = Depends(get_db),
):
    """Envia uma foto e cadastra o trabalho na galeria"""
    # Lê um byte a mais que o limite para detectar arquivo grande sem carregar tudo na memória.
    conteudo = await imagem.read(TAMANHO_MAX_BYTES + 1)
    trabalho = trabalhos_service.criar(
        db, conteudo, titulo or None, descricao or None, categoria or None, data
    )
    return _para_leitura(trabalho)


@router.put("/{trabalho_id}", response_model=TrabalhoRead)
def atualizar_trabalho(trabalho_id: int, dados: TrabalhoUpdate, db: Session = Depends(get_db)):
    """Altera os dados de texto de um trabalho"""
    return _para_leitura(trabalhos_service.atualizar(db, trabalho_id, dados))


@router.delete("/{trabalho_id}", status_code=status.HTTP_204_NO_CONTENT)
def remover_trabalho(trabalho_id: int, db: Session = Depends(get_db)):
    """Exclui o trabalho e a foto"""
    trabalhos_service.remover(db, trabalho_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
