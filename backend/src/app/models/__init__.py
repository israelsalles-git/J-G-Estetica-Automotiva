# Importa os models para registrá-los no Base.metadata (usado no create_all).
from app.models.clientes import Cliente
from app.models.servicos import Servico

__all__ = ["Cliente", "Servico"]
