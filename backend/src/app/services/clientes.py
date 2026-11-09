from collections.abc import Sequence

from sqlalchemy.orm import Session

from app.models.clientes import Cliente
from app.repositories import clientes as clientes_repository
from app.schemas.clientes import ClienteCreate, ClienteUpdate
from app.services.exceptions import ConflitoError, NaoEncontradoError

# Campos que aceitam null no banco: enviar null limpa o valor.
CAMPOS_ANULAVEIS = {"cpf_cnpj"}


def _garantir_cpf_cnpj_livre(db: Session, cpf_cnpj: str | None, cliente_id: int | None = None) -> None:
    """Impede dois clientes com o mesmo CPF/CNPJ (ignora o próprio cliente na atualização)."""
    if cpf_cnpj is None:
        return
    existente = clientes_repository.obter_por_cpf_cnpj(db, cpf_cnpj)
    if existente is not None and existente.id != cliente_id:
        raise ConflitoError("Já existe um cliente com este CPF/CNPJ")


def listar(db: Session, incluir_inativos: bool = False) -> Sequence[Cliente]:
    """Lista os clientes. Por padrão, apenas os ativos."""
    return clientes_repository.listar(db, incluir_inativos)


def obter(db: Session, cliente_id: int) -> Cliente:
    cliente = clientes_repository.obter(db, cliente_id)
    if cliente is None:
        raise NaoEncontradoError("Cliente não encontrado")
    return cliente


def criar(db: Session, dados: ClienteCreate) -> Cliente:
    _garantir_cpf_cnpj_livre(db, dados.cpf_cnpj)
    return clientes_repository.salvar(db, Cliente(**dados.model_dump()))


def atualizar(db: Session, cliente_id: int, dados: ClienteUpdate) -> Cliente:
    """Altera só os campos enviados. `null` só limpa os campos que aceitam nulo no banco."""
    cliente = obter(db, cliente_id)
    alteracoes = {
        campo: valor
        for campo, valor in dados.model_dump(exclude_unset=True).items()
        if valor is not None or campo in CAMPOS_ANULAVEIS
    }
    _garantir_cpf_cnpj_livre(db, alteracoes.get("cpf_cnpj"), cliente_id)
    for campo, valor in alteracoes.items():
        setattr(cliente, campo, valor)
    return clientes_repository.salvar(db, cliente)


def desativar(db: Session, cliente_id: int) -> None:
    """Exclusão lógica: apenas marca o cliente como inativo."""
    cliente = obter(db, cliente_id)
    cliente.ativo = False
    clientes_repository.salvar(db, cliente)
