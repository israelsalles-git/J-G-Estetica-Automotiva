# Importa os models para registrá-los no Base.metadata (usado no create_all).
from app.models.agendamentos import Agendamento
from app.models.clientes import Cliente
from app.models.servicos import Servico
from app.models.usuarios import Usuario

__all__ = ["Agendamento", "Cliente", "Servico", "Usuario"]
