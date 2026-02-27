# Cookest

Cookest é uma plataforma de gestão de refeições e cozinha com assistência de IA. Este repositório contém atualmente a **API backend em Rust** que suporta autenticação, receitas, gestão de inventário, planeamento de refeições e fluxos de chat com IA.

> À procura do frontend? Consulte a nota sobre o **ramo UI** em [Visão Geral do Ramo UI](#visão-geral-do-ramo-ui).

## O que a aplicação faz

O Cookest combina dados estruturados de alimentação com contexto do utilizador para apoiar decisões do dia a dia na cozinha:

- Criação de conta e autenticação segura.
- Pesquisa de receitas e consulta de detalhe da receita.
- Pesquisa de ingredientes + metadados nutricionais.
- Gestão de inventário pessoal (incluindo itens a expirar em breve).
- Preferências de perfil (agregado familiar, restrições alimentares, alergias).
- Geração de plano de refeições e lista de compras.
- Interações com receitas (avaliações, favoritos, histórico de “cozinhado”).
- Sessões de chat com IA que podem usar contexto do utilizador (inventário/preferências/histórico) para responder a perguntas de cozinha.

## Stack tecnológica

### Backend (neste ramo)

- **Linguagem/Framework:** Rust + Actix Web
- **ORM/Acesso a BD:** SeaORM
- **Base de dados:** PostgreSQL
- **Autenticação:** hash Argon2id + fluxo JWT access/refresh
- **Middleware de segurança:** rate limiting, middleware JWT, CORS, uso de cookies seguros
- **Integração IA:** endpoint local compatível com Ollama

## Superfície da API (alto nível)

O Cookest expõe endpoints estilo REST sob `/api/*`:

- `/api/auth/*` — registo/login/refresh/logout
- `/api/recipes/*` — listar receitas + obter por id/slug
- `/api/ingredients/*` — pesquisar ingredientes + detalhe de ingrediente
- `/api/inventory/*` — CRUD de inventário e itens a expirar
- `/api/me/*` — perfil, histórico, favoritos
- `/api/meal-plans/*` — gerar/plano atual/lista de compras/marcar concluído
- `/api/chat/*` — sessões e mensagens de chat com IA

Para configuração detalhada e orientação por endpoint, consulte [`docs/pt-PT/BUILD_AND_USAGE.md`](docs/pt-PT/BUILD_AND_USAGE.md).

## Visão Geral do Ramo UI

O repositório está organizado em torno de um **track principal de backend**, e um **track de ramo UI** separado para trabalho no cliente Flutter.

- **Foco do ramo main:** API backend + schema + lógica de serviços.
- **Foco do ramo UI:** aplicação Flutter que integra com esta API.

Fluxo recomendado para a equipa:

1. Manter contratos de API estáveis em `main`.
2. Desenvolver/polir ecrãs no ramo UI.
3. Validar integração apontando o ramo UI para uma instância local da API.
4. Fazer merge de atualizações UI após verificação de compatibilidade de endpoints e ambiente.

Se o seu checkout local só tiver ficheiros backend, isso é esperado neste ramo.

## Início rápido

### 1) Iniciar PostgreSQL

```bash
docker-compose up -d
```

### 2) Configurar ambiente

Copiar e editar:

```bash
cp .env.example .env
```

Depois confirme que os valores estão corretos para o seu Postgres e configuração JWT.

### 3) Executar a API

```bash
cargo run
```

Por omissão, faz bind em `127.0.0.1:8080`, salvo override por variáveis de ambiente.

## Índice de documentação

- Guia de build, execução e operação: [`docs/pt-PT/BUILD_AND_USAGE.md`](docs/pt-PT/BUILD_AND_USAGE.md)
- Schema da base de dados + diagrama ER: [`docs/database/SCHEMA.pt-PT.md`](docs/database/SCHEMA.pt-PT.md)
- Notas de schema legado: [`DB_SCHEMA.md`](DB_SCHEMA.md)

## Notas do âmbito atual

- Este ramo é centrado na API.
- As migrações são aplicadas no arranque a partir de SQL em `src/main.rs`.
- Ollama é opcional; só é necessário para endpoints de chat IA.
