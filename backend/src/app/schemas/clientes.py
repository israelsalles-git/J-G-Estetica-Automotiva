import re
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field


def _normalizar_cpf_cnpj(valor: str | None) -> str | None:
    """Aceita com ou sem máscara (ex.: 123.456.789-00) e guarda só os dígitos."""
    if valor is None:
        return None
    digitos = re.sub(r"\D", "", valor)
    if len(digitos) not in (11, 14):
        raise ValueError("CPF/CNPJ deve ter 11 (CPF) ou 14 (CNPJ) dígitos")
    return digitos


def _normalizar_telefone(valor: str | None) -> str | None:
    """Aceita com ou sem máscara (ex.: (11) 91234-5678) e guarda só os dígitos (DDD + número)."""
    if valor is None:
        return None
    digitos = re.sub(r"\D", "", valor)
    if len(digitos) not in (10, 11):
        raise ValueError("Telefone deve ter 10 (fixo) ou 11 (celular) dígitos, incluindo DDD")
    return digitos


Nome =Annotated[str, Field(min_length=1, max_length=120)]
CpfCnpj = Annotated[
    str | None,
    AfterValidator(_normalizar_cpf_cnpj),
    Field(description="CPF (11 dígitos) ou CNPJ (14 dígitos), com ou sem máscara"),
]
Telefone = Annotated[
    str | None,
    AfterValidator(_normalizar_telefone),
    Field(description="Telefone com DDD (10 ou 11 dígitos), com ou sem máscara"),
]


class ClienteCreate(BaseModel):
    nome: Nome
    cpf_cnpj: CpfCnpj = None
    telefone: Telefone = None


#Todos os campos opcionais: só o que for enviado é alterado
class ClienteUpdate(BaseModel):

    nome: Nome | None = None
    cpf_cnpj: CpfCnpj = None
    telefone: Telefone = None
    ativo: bool | None = None


class ClienteRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    cpf_cnpj: str | None
    telefone: str | None
    ativo: bool
