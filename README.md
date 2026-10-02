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

# Instale as dependências
pip install -r requirements.txt

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

> O `.env` não é versionado. Nunca suba senhas para o repositório — use o `.env.example` como modelo.

#### 📦 Adicionando dependências

As dependências são gerenciadas com o `pip`. Ao adicionar uma nova, fixe a versão no `requirements.txt` e inclua o pacote no `pyproject.toml`:

```bash
pip install nome-do-pacote
pip show nome-do-pacote        # confira a versão instalada
# adicione "nome-do-pacote==X.Y.Z" ao requirements.txt
```

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
│ ├── .env.example # Modelo das variáveis de ambiente
│ ├── pyproject.toml # Metadados do projeto
│ └── requirements.txt # Dependências Python (pip)
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
