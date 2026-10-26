from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.servicos import Servico


#Modelo Agendamentos
class Agendamento(Base):

    __tablename__ = "cadage"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True
    )

    data: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        index=True
    )

    nome_cliente: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
        index=True
    )

    servico_id: Mapped[int] = mapped_column(
        ForeignKey("cadser.id"),
        nullable=False,
        index=True
    )

    # ID do evento no Google Agenda (vazio enquanto a integração estiver desligada)
    google_event_id: Mapped[str | None] = mapped_column(
        String(1024),
        nullable=True
    )

    servico: Mapped[Servico] = relationship(lazy="joined")
