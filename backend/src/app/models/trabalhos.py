from datetime import date

from sqlalchemy import Date, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


#Modelo Trabalhos (fotos da galeria "Últimos Trabalhos" do site)
class Trabalho(Base):

    __tablename__ = "trabalhos"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True
    )

    titulo: Mapped[str | None] = mapped_column(
        String(120),
        nullable=True
    )

    descricao: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    categoria: Mapped[str | None] = mapped_column(
        String(60),
        nullable=True
    )

    data: Mapped[date | None] = mapped_column(
        Date,
        nullable=True
    )

    # Caminho relativo à pasta de uploads
    arquivo: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )
