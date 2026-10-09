from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_auth
from app.schemas.servicos import ServicoCreate, ServicoRead, ServicoUpdate
from app.services import servicos as servicos_service

#Declaração da rota
router = APIRouter(prefix="/servicos", tags=["servicos"])

@router.get("", response_model=list[ServicoRead])
def listar_servicos(incluir_inativos: bool = False, db: Session = Depends(get_db)):
    """Lista os serviços. Por padrão, apenas os ativos"""
    return servicos_service.listar(db, incluir_inativos)


@router.get("/{servico_id}", response_model=ServicoRead)
def obter_servico(servico_id: int, db: Session = Depends(get_db)):
    """"Busca serviço por ID"""
    return servicos_service.obter(db, servico_id)


@router.post(
    "",
    response_model=ServicoRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_auth)],
)
def criar_servico(dados: ServicoCreate, db: Session = Depends(get_db)):
    """Cria serviço"""
    return servicos_service.criar(db, dados)


@router.put("/{servico_id}", response_model=ServicoRead, dependencies=[Depends(require_auth)])
def atualizar_servico(servico_id: int, dados: ServicoUpdate, db: Session = Depends(get_db)):
    """Atualiza serviço por ID"""
    return servicos_service.atualizar(db, servico_id, dados)


@router.delete(
    "/{servico_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_auth)],
)
def desativar_servico(servico_id: int, db: Session = Depends(get_db)):
    """Exclusão lógica: apenas marca o serviço como inativo."""
    servicos_service.desativar(db, servico_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
