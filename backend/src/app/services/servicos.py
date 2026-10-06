from collections.abc import Sequence

from sqlalchemy.orm import Session

from app.models.servicos import Servico
from app.repositories import servicos as servicos_repository
from app.schemas.servicos import ServicoCreate, ServicoUpdate
from app.services.exceptions import NaoEncontradoError


def listar(db: Session, incluir_inativos: bool = False) -> Sequence[Servico]:
    """Lista os serviços. Por padrão, apenas os ativos."""
    return servicos_repository.listar(db, incluir_inativos)


def obter(db: Session, servico_id: int) -> Servico:
    servico = servicos_repository.obter(db, servico_id)
    if servico is None:
        raise NaoEncontradoError("Serviço não encontrado")
    return servico


def criar(db: Session, dados: ServicoCreate) -> Servico:
    return servicos_repository.salvar(db, Servico(**dados.model_dump()))


def atualizar(db: Session, servico_id: int, dados: ServicoUpdate) -> Servico:
    """Altera só os campos enviados."""
    servico = obter(db, servico_id)
    for campo, valor in dados.model_dump(exclude_unset=True, exclude_none=True).items():
        setattr(servico, campo, valor)
    return servicos_repository.salvar(db, servico)


def desativar(db: Session, servico_id: int) -> None:
    """Exclusão lógica: apenas marca o serviço como inativo."""
    servico = obter(db, servico_id)
    servico.ativo = False
    servicos_repository.salvar(db, servico)
