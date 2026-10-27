# 📋 Sistema de Gestão de Clientes — J&G Estética Automotiva

Sistema desenvolvido para automatizar e organizar a gestão de clientes de uma empresa de estética automotiva, centralizando informações e facilitando o atendimento do dia a dia.

---

## 👥 Integrantes

| Nome | Responsabilidade |
|------|-----------------|
| David Antunes Rodrigues | Definição de requisitos, Desenvolvimento |
| Israel Salles | Banco de dados, Testes |
| Nicholas Catelan de Góes | Interface/telas, Documentação |
| Juan Felipe Araújo da Silva | Definição de requisitos, Interface/telas |

---

## 🏢 Parceiro

- **Empresa:** J&G Estética Automotiva
- **Responsável:** Gustavo Ribeiro Casemiro
- **Segmento:** Estética automotiva
- **Localização:** Sarandi/PR

---

## 📌 Sobre o Projeto

A J&G Estética Automotiva enfrentava dificuldades na organização das informações dos clientes — dados registrados manualmente ou espalhados em diferentes locais, tornando a consulta e o acompanhamento lentos e sujeitos a erros.

Este projeto tem como objetivo desenvolver um sistema que centralize essas informações em um único lugar, tornando o processo mais ágil e confiável.

---

## ✅ Funcionalidades

- [x] Cadastro de novos clientes
- [x] Consulta e pesquisa de clientes
- [x] Alteração de dados cadastrados
- [x] Exclusão de registros
- [x] Registro de histórico de atendimentos/serviços
- [x] Visualização detalhada das informações de cada cliente
- [x] Busca rápida por nome ou telefone

---

## 🛠️ Tecnologias Utilizadas

### Backend
- **Python** com **FastAPI**
- **Banco de dados:** *(PostgreSQL)*
- **ORM:** *(SQLAlchemy)*

### Frontend
- **Flutter** / **Dart**

---

## 🚀 Como Executar

### Pré-requisitos

- Python 3.13+ instalado (com pip)
- Flutter SDK instalado
---

### ▶️ Backend (FastAPI)

```bash
# Clone o repositório
git clone https://github.com/israelsalles-git/J-G-Estetica-Automotiva.git

# Acesse a pasta do backend
cd J-G-Estetica-Automotiva/backend

# Crie o arquivo de configuração a partir do modelo (ajuste os valores se precisar)
cp .env.example .env

# Crie e ative um ambiente virtual
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/macOS

# Instale as dependências (inclui as de teste; em produção use requirements.txt)
pip install -r requirements-dev.txt

# Crie/atualize as tabelas do banco (rode sempre que puxar migrations novas)
alembic upgrade head

# Inicie o servidor em modo desenvolvimento
uvicorn app.main:app --reload --app-dir src
```

> Execute os comandos de dentro da pasta `backend/`. O arquivo `.env` deve ficar em `backend/.env` (ao lado do `.env.example`).

A API estará disponível em: `http://localhost:8000`  
Verificação de saúde: `http://localhost:8000/health`  
Documentação automática: `http://localhost:8000/docs`

#### ⚙️ Variáveis de ambiente (`.env`)

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `APP_NAME` | Nome da API | `J&G Estética Automotiva API` |
| `APP_VERSION` | Versão da API | `0.1.0` |
| `ENVIRONMENT` | Ambiente (`development`, `production`...) | `development` |
| `DEBUG` | Ativa o modo debug | `false` |
| `DATABASE_URL` | URL de conexão com o PostgreSQL | `postgresql+psycopg://postgres:postgres@localhost:5432/jg_estetica` |
| `CORS_ORIGIN_REGEX` | Padrão (regex) de origens liberadas para chamar a API pelo navegador. Em desenvolvimento: `http://localhost:\d+` | vazio (nenhuma) |
| `CORS_ORIGINS` | Origens exatas liberadas, em JSON e sem `/` no final. Ex.: `["https://seusite.com.br"]` | `[]` (nenhuma) |

> **CORS:** o site Flutter Web roda em outra origem (porta/domínio) que a API, então o navegador só deixa o site chamar a API se a origem estiver liberada em `CORS_ORIGIN_REGEX` ou `CORS_ORIGINS`. Não deixe `CORS_ORIGINS=` vazio no `.env` (a API não sobe): use `[]` ou apague a linha.

> O `.env` não é versionado. Nunca suba senhas para o repositório — use o `.env.example` como modelo.

#### 🗄️ Migrations (Alembic)

As tabelas são criadas e alteradas **somente por migrations** (pasta `backend/alembic/versions/`); a API não cria tabelas ao subir. O Alembic lê a `DATABASE_URL` do `.env`. Com o ambiente virtual ativo, dentro de `backend/`:

```bash
alembic upgrade head                                    # aplica as migrations pendentes
alembic current                                         # mostra a versão atual do banco
alembic revision --autogenerate -m "descricao da mudanca"  # gera migration após alterar um model
alembic downgrade -1                                    # desfaz a última migration
```

Ao alterar um model em `src/app/models/`:

1. Gere a migration com `--autogenerate` e **revise o arquivo gerado** antes de aplicar (o Alembic não detecta tudo, ex.: renomear coluna vira "apagar + criar").
2. Se a coluna nova for obrigatória e a tabela já tiver dados, crie-a como `nullable=True`, preencha os registros antigos e só então aplique o `NOT NULL`.
3. Rode `alembic upgrade head` e suba o arquivo da migration junto com a alteração do model.

#### 🧪 Testes

Os testes usam um banco SQLite em memória (não tocam no PostgreSQL). Com o ambiente virtual ativo, dentro de `backend/`:

```bash
pytest
```

#### 📦 Adicionando dependências

As dependências são gerenciadas com o `pip`. Ao adicionar uma nova, fixe a versão no `requirements.txt` e inclua o pacote no `pyproject.toml`:

```bash
pip install nome-do-pacote
pip show nome-do-pacote        # confira a versão instalada
# adicione "nome-do-pacote==X.Y.Z" ao requirements.txt
```

Dependências usadas só em desenvolvimento/testes (ex.: `pytest`) vão no `requirements-dev.txt` e na seção `[project.optional-dependencies] dev` do `pyproject.toml`.

---

### 📱 Frontend (Flutter)

```bash
# Acesse a pasta do frontend
cd J-G-Estetica-Automotiva/frontend

# Instale as dependências
flutter pub get

# Execute o aplicativo
flutter run
```

---

## 📁 Estrutura do Projeto
```bash
/
├── backend/
│ ├── src/app/
│ │ ├── main.py # Entrypoint da API
│ │ ├── api/ # Rotas da API (ex.: health.py)
│ │ ├── core/ # Configurações (config.py lê o .env)
│ │ ├── models/ # Modelos do banco de dados
│ │ ├── schemas/ # Schemas Pydantic
│ │ ├── repositories/ # Integração com o banco
│ │ └── services/ # Regras de negócio
│ ├── alembic/ # Migrations do banco (versions/)
│ ├── alembic.ini # Configuração do Alembic
│ ├── .env.example # Modelo das variáveis de ambiente
│ ├── pyproject.toml # Metadados do projeto
│ ├── tests/ # Testes automatizados (pytest)
│ ├── requirements.txt # Dependências Python (pip)
│ └── requirements-dev.txt # Dependências de desenvolvimento/testes
│
├── frontend/
│ ├── lib/
│ │ ├── main.dart # Entrypoint Flutter
│ │ ├── screens/ # Telas do app
│ │ ├── widgets/ # Componentes reutilizáveis
│ │ └── services/ # Integração com a API
│ └── pubspec.yaml
│
└── README.md

```

## 🔄 Etapas de Desenvolvimento

1. **Entendimento do problema** — Levantamento das necessidades com o parceiro
2. **Definição dos requisitos** — Funcionalidades e dados a serem armazenados
3. **Modelagem** — Estrutura do banco de dados e endpoints da API
4. **Desenvolvimento** — Backend em FastAPI + Frontend em Flutter
5. **Testes** — Verificação das funções e simulação de cenários reais
6. **Apresentação e ajustes** — Entrega ao parceiro e correções finais

---
## 📝 Padrão de Commits

Este projeto utiliza o padrão de **Conventional Commits** para manter o histórico do Git organizado e legível (junto ao commit é colocado o ticket ao qual pertence).

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `feat` | Nova funcionalidade para o usuário | `feat(auth): adiciona tela de login` |
| `fix` | Correção de um erro (bug) | `fix(carrinho): corrige cálculo do frete` |
| `docs` | Mudanças apenas na documentação | `docs: atualiza instruções de instalação` |
| `style` | Formatação que não altera o funcionamento (espaços, ponto e vírgula) | `style: ajusta indentação do arquivo main` |
| `refactor` | Melhoria de estrutura sem corrigir erros nem adicionar funções | `refactor: reorganiza camada de serviços` |
| `test` | Adição ou correção de testes automatizados | `test: adiciona testes para cadastro de cliente` |

---
## 📈 Resultados Esperados

- Cadastro de clientes mais ágil
- Busca rápida por informações
- Dados organizados em um único local
- Redução de controles manuais
- Histórico de atendimentos acessível
- Economia de tempo durante o atendimento

---

## 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos com o consentimento do parceiro, conforme Termo de Consentimento assinado.
