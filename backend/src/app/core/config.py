from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configurações da aplicação, lidas de variáveis de ambiente ou do arquivo .env."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "J&G Estética Automotiva API"
    app_version: str = "0.1.0"
    environment: str = "development"
    debug: bool = False

    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/jg_estetica"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
