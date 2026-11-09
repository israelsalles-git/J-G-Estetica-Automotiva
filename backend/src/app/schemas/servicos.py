from decimal import Decimal
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field

from app.models.servicos import DURACAO_MAX_MIN

Nome = Annotated[str, Field(min_length=1, max_length=120)]
DuracaoMin = Annotated[
    int, Field(gt=0, le=DURACAO_MAX_MIN, description=f"Duração em minutos (máx. {DURACAO_MAX_MIN})")
]
Preco = Annotated[Decimal, Field(ge=0, max_digits=10, decimal_places=2)]
Categoria = Annotated[str, Field(min_length=1, max_length=30, description="Ex.: Carro, Moto")]
Descricao = Annotated[str | None, Field(max_length=500)]


class ServicoCreate(BaseModel):
    nome: Nome
    duracao_min: DuracaoMin
    preco: Preco
    categoria: Categoria = "Outros"
    descricao: Descricao = None
    destaque: bool = False


#Todos os campos opcionais: só o que for enviado é alterado
class ServicoUpdate(BaseModel):

    nome: Nome | None = None
    duracao_min: DuracaoMin | None = None
    preco: Preco | None = None
    categoria: Categoria | None = None
    descricao: Descricao = None
    destaque: bool | None = None
    ativo: bool | None = None


class ServicoRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    duracao_min: int
    preco: Decimal
    categoria: str
    descricao: str | None
    destaque: bool
    ativo: bool
