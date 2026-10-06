from functools import lru_cache
from pathlib import Path
from urllib.parse import quote, unquote

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Pasta backend/ (config.py fica em backend/src/app/core/)
BASE_DIR = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    """Configurações da aplicação, lidas de variáveis de ambiente ou do arquivo .env."""

    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env", env_file_encoding="utf-8", extra="ignore"
    )

    app_name: str = "J&G Estética Automotiva API"
    app_version: str = "0.1.0"
    environment: str = "development"
    debug: bool = False

    # Pode colar a string do Supabase (Connect > Session pooler) como vem; ela é ajustada abaixo.
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/jg_estetica"

    # Token exigido nas rotas protegidas (Authorization: Bearer <token>). Vazio = bloqueia tudo.
    api_token: str = ""

    @field_validator("database_url")
    @classmethod
    def normalizar_database_url(cls, url: str) -> str:
        """Adapta a string do Supabase para o SQLAlchemy + psycopg.

        - `postgres://` / `postgresql://` -> `postgresql+psycopg://`
        - codifica caracteres especiais da senha (ex.: `@`, `#`, `/`)
        - adiciona `sslmode=require` quando o host for do Supabase
        """
        url = url.strip()
        esquema, sep, resto = url.partition("://")
        if not sep:
            return url
        if esquema in ("postgres", "postgresql"):
            esquema = "postgresql+psycopg"

        # O último "@" separa credenciais do host, então a senha pode conter "@".
        credenciais, arroba, host_e_resto = resto.rpartition("@")
        if arroba:
            usuario, dois_pontos, senha = credenciais.partition(":")
            if dois_pontos:
                credenciais = f"{usuario}:{quote(unquote(senha), safe='')}"
            resto = f"{credenciais}@{host_e_resto}"

        url = f"{esquema}://{resto}"
        if "supabase.com" in host_e_resto and "sslmode=" not in url:
            url += ("&" if "?" in url else "?") + "sslmode=require"
        return url


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
