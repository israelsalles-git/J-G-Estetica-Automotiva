"""
Cadastra um usuário do painel admin, não há cadastro público pela API.

pasta backend/src
.env configurado
migration aplicada

Comando: python -m app.scripts.criar_admin
"""
import sys
from getpass import getpass

from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

import app.models
from app.core.database import SessionLocal
from app.schemas.auth import SENHA_MIN, UsuarioCreate
from app.services import auth as auth_service
from app.services.exceptions import ConflitoError


def main() -> int:
    print("Cadastro de usuário do painel admin\n")
    nome = input("Nome: ")
    email = input("E-mail: ")
    senha = getpass(f"Senha (mínimo {SENHA_MIN} caracteres): ")
    if getpass("Confirme a senha: ") != senha:
        print("\nErro: as senhas não conferem.")
        return 1

    try:
        dados = UsuarioCreate(nome=nome, email=email, senha=senha)
    except ValidationError as exc:
        print("\nDados inválidos:")
        for erro in exc.errors():
            print(f"  - {erro['loc'][0]}: {erro['msg']}")
        return 1

    with SessionLocal() as db:
        try:
            usuario = auth_service.cadastrar(db, dados)
        except ConflitoError as exc:
            print(f"\nErro: {exc}.")
            return 1
        except IntegrityError:
            # E-mail cadastrado por outra pessoa entre a conferência e a gravação.
            print("\nErro: já existe um usuário com este e-mail.")
            return 1

    print(f"\nUsuário criado: id={usuario.id}, {usuario.nome} <{usuario.email}>")
    return 0


if __name__ == "__main__":
    sys.exit(main())
