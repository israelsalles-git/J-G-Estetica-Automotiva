from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_auth
from app.models.servicos import Servico
from app.schemas.servicos import ServicoCreate, ServicoRead, ServicoUpdate

router = APIRouter(prefix="/servicos", tags=["servicos"])


def _get_or_404(db: Session, servico_id: int) -> Servico:
    servico = db.get(Servico, servico_id)
    if servico is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Serviço não encontrado")
    return servico


@router.get("", response_model=list[ServicoRead])
def listar_servicos(incluir_inativos: bool = False, db: Session = Depends(get_db)):
    """Lista os serviços. Por padrão, apenas os ativos."""
    query = select(Servico).order_by(Servico.nome)
    if not incluir_inativos:
        query = query.where(Servico.ativo.is_(True))
    return db.scalars(query).all()


@router.get("/{servico_id}", response_model=ServicoRead)
def obter_servico(servico_id: int, db: Session = Depends(get_db)):
    return _get_or_404(db, servico_id)


@router.post(
    "",
    response_model=ServicoRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_auth)],
)
def criar_servico(dados: ServicoCreate, db: Session = Depends(get_db)):
    servico = Servico(**dados.model_dump())
    db.add(servico)
    db.commit()
    db.refresh(servico)
    return servico


@router.put("/{servico_id}", response_model=ServicoRead, dependencies=[Depends(require_auth)])
def atualizar_servico(servico_id: int, dados: ServicoUpdate, db: Session = Depends(get_db)):
    servico = _get_or_404(db, servico_id)
    for campo, valor in dados.model_dump(exclude_unset=True, exclude_none=True).items():
        setattr(servico, campo, valor)
    db.commit()
    db.refresh(servico)
    return servico


@router.delete(
    "/{servico_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_auth)],
)
def desativar_servico(servico_id: int, db: Session = Depends(get_db)):
    """Exclusão lógica: apenas marca o serviço como inativo."""
    servico = _get_or_404(db, servico_id)
    servico.ativo = False
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
