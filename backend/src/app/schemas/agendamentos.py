from datetime import datetime
from typing import Annotated
from zoneinfo import ZoneInfo

from pydantic import AfterValidator, BaseModel, ConfigDict, Field

from app.core.config import settings
from app.schemas.servicos import ServicoRead


def para_fuso_local(valor: datetime) -> datetime:
    """Datas sem fuso são interpretadas no fuso da empresa; as demais são convertidas para ele."""
    fuso = ZoneInfo(settings.timezone)
    if valor.tzinfo is None:
        return valor.replace(tzinfo=fuso)
    return valor.astimezone(fuso)


def _exigir_data_futura(valor: datetime) -> datetime:
    if valor <= datetime.now(valor.tzinfo):
        raise ValueError("A data do agendamento deve ser futura")
    return valor


# Usado também nos filtros da listagem (query string)
DataHora = Annotated[datetime, AfterValidator(para_fuso_local)]
DataAgendamento = Annotated[
    datetime,
    AfterValidator(para_fuso_local),
    AfterValidator(_exigir_data_futura),
    Field(description="Data e hora do agendamento (ISO 8601). Sem fuso = horário de Brasília"),
]
NomeCliente = Annotated[str, Field(min_length=1, max_length=120)]
ServicoId = Annotated[int, Field(gt=0)]


class AgendamentoCreate(BaseModel):
    data: DataAgendamento
    nome_cliente: NomeCliente
    servico_id: ServicoId


#Todos os campos opcionais: só o que for enviado é alterado
class AgendamentoUpdate(BaseModel):

    data: DataAgendamento | None = None
    nome_cliente: NomeCliente | None = None
    servico_id: ServicoId | None = None


class AgendamentoRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    data: DataHora
    nome_cliente: str
    servico_id: int
    servico: ServicoRead
    google_event_id: str | None
