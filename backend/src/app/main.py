from fastapi import FastAPI

from app.api import health
from app.core.config import settings

app = FastAPI(title=settings.app_name, version=settings.app_version, debug=settings.debug)

app.include_router(health.router)


@app.get("/")
def home():
    return {"mensagem": "Minha primeira API"}
