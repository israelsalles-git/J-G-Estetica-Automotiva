from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_auth
from app.schemas.clientes import ClienteCreate, ClienteRead, ClienteUpdate
from app.services import clientes as clientes_service

# Todas as rotas exigem token: os dados de clientes (CPF/CNPJ) são pessoais.
router = APIRouter(prefix="/clientes", tags=["clientes"], dependencies=[Depends(require_auth)])


@router.get("", response_model=list[ClienteRead])
def listar_clientes(incluir_inativos: bool = False, db: Session = Depends(get_db)):
    """Lista os clientes. Por padrão, apenas os ativos."""
    return clientes_service.listar(db, incluir_inativos)


@router.get("/{cliente_id}", response_model=ClienteRead)
def obter_cliente(cliente_id: int, db: Session = Depends(get_db)):
    return clientes_service.obter(db, cliente_id)


@router.post("", response_model=ClienteRead, status_code=status.HTTP_201_CREATED)
def criar_cliente(dados: ClienteCreate, db: Session = Depends(get_db)):
    return clientes_service.criar(db, dados)


@router.put("/{cliente_id}", response_model=ClienteRead)
def atualizar_cliente(cliente_id: int, dados: ClienteUpdate, db: Session = Depends(get_db)):
    return clientes_service.atualizar(db, cliente_id, dados)


@router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def desativar_cliente(cliente_id: int, db: Session = Depends(get_db)):
    """Exclusão lógica: apenas marca o cliente como inativo."""
    clientes_service.desativar(db, cliente_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
