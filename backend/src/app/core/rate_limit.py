from slowapi import Limiter
from slowapi.util import get_remote_address

# Limite de requisições por IP nas rotas públicas que gravam ou autenticam.
# Os contadores ficam na memória do processo: zeram quando a API reinicia.
# Atrás de proxy (Render, Railway, Nginx), suba o uvicorn com --proxy-headers, senão todos
# os clientes chegam com o IP do proxy e o limite passa a valer para o site inteiro.
limiter = Limiter(key_func=get_remote_address)

LIMITE_AGENDAMENTO_PUBLICO = "5/minute;20/hour"
LIMITE_LOGIN = "5/minute"
LIMITE_LOGIN_GOOGLE = "10/minute"
