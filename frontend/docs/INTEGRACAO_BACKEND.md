# Ligando o site ao backend

O site conversa com a API FastAPI do backend. Cada parte do app fala com a API por um **contrato**
(classe abstrata em `lib/services/`) e uma **implementação** que usa o `ApiClient`
(`lib/core/api_client.dart`). A tela só conhece o contrato.

## Endereço da API

Por padrão, a API é `http://localhost:8000`. Para outro endereço, sem mexer no código:

```bash
flutter run -d chrome --dart-define=API_URL=https://api.seudominio.com.br
```

## Onde cada contrato é ligado

| Contrato | Implementação | Endpoint |
|---|---|---|
| `CatalogRepository` | `ApiCatalogRepository` | `GET /servicos` (público) |
| `BookingRepository` | `ApiBookingRepository` | `GET /agendamentos/ocupados` e `POST /agendamentos/publico` (públicos) |
| `WorksRepository` | `ApiWorksRepository` | `GET /trabalhos` (público); `POST`, `PUT` e `DELETE` (painel, com token) |
| `AuthService` | `ApiAuthService` | `POST /auth/login` (painel) |

A ligação acontece em `lib/main.dart` (site) e `lib/main_admin.dart` (painel).

## Formato dos dados

Os modelos (`lib/models/`) traduzem o JSON da API no `fromJson` / `toJson`. Se a API mudar um nome
de campo, ajuste só ali.

- **Service** (`GET /servicos`): `id, nome, duracao_min, preco, categoria, descricao, destaque`.
  O preço chega como texto (`"70.00"`) e é convertido para número. A duração (`60`) vira texto (`"1h"`).
- **Work** (`GET /trabalhos`): `id, titulo, descricao, categoria, data, imagem_url`.
  `imagem_url` é um caminho relativo (`/arquivos/...`); o `ApiWorksRepository` completa com o endereço da API.
- **BookingRequest** (enviado a `POST /agendamentos/publico`): `servico_id, data, nome_cliente`.
  A `data` vai com dia e hora, sem fuso: a API lê no horário de Brasília.
- **Horários ocupados** (`GET /agendamentos/ocupados`): lista de `{inicio, fim}`, sem nenhum dado do cliente.
  O site desabilita os horários que começam dentro de um desses períodos.

## Regras que a API aplica

- **Um atendimento por vez**: o período de cada agendamento é o horário de início mais a duração do
  serviço. Encostar um no outro (fim = início) é permitido. Um conflito volta como `409` com a mensagem
  "Horário indisponível: já existe um agendamento nesse período", que o site mostra ao cliente.
- **Datas passadas** são recusadas (`422`).
- **Serviço inativo** não pode ser agendado (`409`).

## Fotos da galeria

Envio pelo painel como multipart (`POST /trabalhos`, campo `imagem`):
- formatos JPG, PNG ou WEBP, conferidos pelo conteúdo do arquivo (não só pela extensão);
- até 5 MB;
- a foto é gravada em `backend/uploads/trabalhos/` e servida em `/arquivos/...`.

## Erros

A API responde `{"detail": "..."}` com mensagem em português. O `ApiClient` usa essa mensagem
direto na tela (`AppException`). Sem conexão, o usuário vê "Não foi possível conectar ao servidor.".
Um `401` mostra "Sessão expirada. Entre novamente.".

## O que ainda não está ligado

- **Painel "Fotos de Serviços"** (`photos_panel.dart`): ainda simula o envio. Para ligar ao
  `WorksRepository`, falta escolher um seletor de arquivos (dependência nova) e adaptar o painel.
- **Painéis "Preços" e "Agenda"** do admin: ainda usam dados fixos na própria tela.
- **Login com Google**: o botão existe, mas a API não tem esse login ainda.
- **Contato pelo botão flutuante**: `HomePage(onContactPressed: ...)` continua sem ação definida.
