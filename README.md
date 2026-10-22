# cine-kit

App para macOS que transforma o Mac numa TV box: uma interface de sala de estar, pensada para ser usada à distância (sofá + TV), com navegação por controle remoto/teclado e foco em mídia.

> **Status:** fase inicial. O repositório ainda não tem código, só a estrutura de documentação e de decisões de arquitetura.

## Objetivo

- Interface em tela cheia ("10-foot UI"), legível de longe e navegável sem mouse.
- Ponto único de entrada para conteúdo de mídia no Mac ligado à TV.
- Experiência próxima de uma Apple TV / Android TV, rodando em hardware macOS.

O escopo detalhado e as escolhas técnicas são registrados em [`architecture/`](architecture/).

## Estrutura do repositório

```
.
├── README.md          # Visão geral do projeto (este arquivo)
├── AGENTS.md          # Instruções para agentes de IA (Claude Code, Codex, Cursor, etc.)
├── CLAUDE.md          # Aponta para AGENTS.md
└── architecture/      # Architecture Decision Records (ADRs)
    ├── README.md      # Índice e processo dos ADRs
    ├── template.md    # Modelo para novos ADRs
    └── NNNN-*.md      # Uma decisão por arquivo
```

## Desenvolvimento com IA

Este repositório é **AI-first**: agentes de código são colaboradores de primeira classe.

- [`AGENTS.md`](AGENTS.md) é a fonte de verdade sobre como trabalhar aqui — convenções, comandos, regras.
- Toda decisão de arquitetura relevante vira um ADR em [`architecture/`](architecture/), para que humanos e agentes entendam o *porquê* das coisas sem depender de histórico de conversa.

## Como rodar

Ainda não há código. Esta seção será preenchida quando o projeto Xcode/Swift Package for criado.
