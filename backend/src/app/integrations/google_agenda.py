"""Integração com o Google Agenda.

O resto do sistema conhece só a interface `Agenda`. Sem configuração, `get_agenda` devolve
uma agenda desligada (não faz nada); com GOOGLE_CALENDAR_ID e GOOGLE_CREDENTIALS_FILE no .env,
devolve a `GoogleAgenda`, que cria/altera/remove os eventos via conta de serviço.
"""

import logging
from dataclasses import dataclass
from datetime import datetime
from functools import lru_cache
from typing import Protocol

from app.core.config import settings
from app.services.exceptions import IntegracaoError

logger = logging.getLogger(__name__)

ESCOPO_AGENDA = "https://www.googleapis.com/auth/calendar.events"


@dataclass(frozen=True)
class EventoAgenda:
    titulo: str
    inicio: datetime
    fim: datetime
    descricao: str = ""


class Agenda(Protocol):
    def criar_evento(self, evento: EventoAgenda) -> str | None:
        """Cria o evento e devolve o ID dele na agenda (None se a integração estiver desligada)."""
        ...

    def atualizar_evento(self, evento_id: str, evento: EventoAgenda) -> None: ...

    def remover_evento(self, evento_id: str) -> None: ...


class AgendaDesativada:
    """Usada enquanto o Google Agenda não estiver configurado: não faz nada."""

    def criar_evento(self, evento: EventoAgenda) -> str | None:
        return None

    def atualizar_evento(self, evento_id: str, evento: EventoAgenda) -> None:
        return None

    def remover_evento(self, evento_id: str) -> None:
        return None


class GoogleAgenda:
    """Agenda real, usando a Google Calendar API com uma conta de serviço."""

    def __init__(self, calendar_id: str, credentials_file: str, timezone: str):
        # Import tardio: as bibliotecas do Google só são exigidas quando a integração está ligada.
        from google.oauth2 import service_account

        self._calendar_id = calendar_id
        self._timezone = timezone
        self._credenciais = service_account.Credentials.from_service_account_file(
            credentials_file, scopes=[ESCOPO_AGENDA]
        )

    def _eventos(self):
        # Um cliente por chamada: o cliente HTTP do googleapiclient não é thread-safe.
        from googleapiclient.discovery import build

        return build("calendar", "v3", credentials=self._credenciais, cache_discovery=False).events()

    def _corpo(self, evento: EventoAgenda) -> dict:
        return {
            "summary": evento.titulo,
            "description": evento.descricao,
            "start": {"dateTime": evento.inicio.isoformat(), "timeZone": self._timezone},
            "end": {"dateTime": evento.fim.isoformat(), "timeZone": self._timezone},
        }

    def criar_evento(self, evento: EventoAgenda) -> str | None:
        try:
            criado = (
                self._eventos()
                .insert(calendarId=self._calendar_id, body=self._corpo(evento))
                .execute()
            )
        except Exception as exc:
            logger.exception("Erro ao criar evento no Google Agenda")
            raise IntegracaoError("Não foi possível criar o evento no Google Agenda") from exc
        return criado["id"]

    def atualizar_evento(self, evento_id: str, evento: EventoAgenda) -> None:
        try:
            self._eventos().patch(
                calendarId=self._calendar_id, eventId=evento_id, body=self._corpo(evento)
            ).execute()
        except Exception as exc:
            logger.exception("Erro ao atualizar evento %s no Google Agenda", evento_id)
            raise IntegracaoError("Não foi possível atualizar o evento no Google Agenda") from exc

    def remover_evento(self, evento_id: str) -> None:
        from googleapiclient.errors import HttpError

        try:
            self._eventos().delete(calendarId=self._calendar_id, eventId=evento_id).execute()
        except HttpError as exc:
            # Evento já apagado direto na agenda: nada a fazer.
            if exc.resp.status in (404, 410):
                return
            logger.exception("Erro ao remover evento %s do Google Agenda", evento_id)
            raise IntegracaoError("Não foi possível remover o evento do Google Agenda") from exc
        except Exception as exc:
            logger.exception("Erro ao remover evento %s do Google Agenda", evento_id)
            raise IntegracaoError("Não foi possível remover o evento do Google Agenda") from exc


@lru_cache
def get_agenda() -> Agenda:
    """Dependência do FastAPI: devolve a agenda configurada (ou a desligada)."""
    if settings.google_calendar_id and settings.google_credentials_file:
        return GoogleAgenda(
            settings.google_calendar_id, settings.google_credentials_file, settings.timezone
        )
    return AgendaDesativada()
