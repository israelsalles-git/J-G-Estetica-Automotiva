from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_auth
from app.integrations.google_agenda import Agenda, get_agenda
from app.schemas.agendamentos import (
    AgendamentoCreate,
    AgendamentoRead,
    AgendamentoUpdate,
    DataHora,
)
from app.services import agendamentos as agendamentos_service

# Todas as rotas exigem token: os agendamentos têm o nome do cliente (dado pessoal).
router = APIRouter(
    prefix="/agendamentos", tags=["agendamentos"], dependencies=[Depends(require_auth)]
)


@router.get("", response_model=list[AgendamentoRead])
def listar_agendamentos(
    data_inicio: DataHora | None = None,
    data_fim: DataHora | None = None,
    db: Session = Depends(get_db),
):
    """Lista os agendamentos por data. Filtros opcionais: data_inicio e data_fim"""
    return agendamentos_service.listar(db, data_inicio, data_fim)


@router.get("/{agendamento_id}", response_model=AgendamentoRead)
def obter_agendamento(agendamento_id: int, db: Session = Depends(get_db)):
    """Busca agendamento por ID"""
    return agendamentos_service.obter(db, agendamento_id)


@router.post("", response_model=AgendamentoRead, status_code=status.HTTP_201_CREATED)
def criar_agendamento(
    dados: AgendamentoCreate,
    db: Session = Depends(get_db),
    agenda: Agenda = Depends(get_agenda),
):
    """Cria agendamento e o evento no Google Agenda"""
    return agendamentos_service.criar(db, agenda, dados)


@router.put("/{agendamento_id}", response_model=AgendamentoRead)
def atualizar_agendamento(
    agendamento_id: int,
    dados: AgendamentoUpdate,
    db: Session = Depends(get_db),
    agenda: Agenda = Depends(get_agenda),
):
    """Atualiza agendamento pelo ID (e o evento no Google Agenda)"""
    return agendamentos_service.atualizar(db, agenda, agendamento_id, dados)


@router.delete("/{agendamento_id}", status_code=status.HTTP_204_NO_CONTENT)
def remover_agendamento(
    agendamento_id: int,
    db: Session = Depends(get_db),
    agenda: Agenda = Depends(get_agenda),
):
    """Exclui o agendamento e o evento no Google Agenda"""
    agendamentos_service.remover(db, agenda, agendamento_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
