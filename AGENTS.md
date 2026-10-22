# AGENTS.md

Instruções para agentes de IA (Claude Code, Codex, Cursor, Copilot, etc.) que trabalham neste repositório. Humanos também devem seguir.

## O projeto

**cine-kit** é um app para macOS que transforma o Mac numa TV box: UI em tela cheia, navegável à distância por controle remoto/teclado, focada em mídia. Veja o [README](README.md) para a visão geral.

Fase atual: **preparação do repositório**. Ainda não existe código nem stack definida.

## Antes de começar qualquer tarefa

1. Leia [`architecture/README.md`](architecture/README.md) e os ADRs com status `Aceito`. Eles são as regras do projeto.
2. Não contradiga um ADR aceito. Se a tarefa exigir isso, pare e proponha um novo ADR que o substitua.
3. Se algo não estiver decidido (stack, dependência, estrutura de pastas), **não decida sozinho em silêncio**: proponha um ADR com status `Proposto` e pergunte.

## Decisões de arquitetura (ADRs)

Toda decisão que seja difícil de reverter ou que afete a estrutura do projeto vira um ADR em `architecture/`. Exemplos:

- Escolha de linguagem, framework de UI, versão mínima do macOS
- Adoção de dependências externas
- Organização de módulos/pastas
- Modelo de distribuição (App Store, notarização, direto)
- Integrações com serviços de terceiros

Processo:

1. Copie [`architecture/template.md`](architecture/template.md) para `architecture/NNNN-titulo-em-kebab-case.md`, usando o próximo número livre (4 dígitos).
2. Preencha contexto, decisão, alternativas e consequências.
3. Adicione uma linha no índice de [`architecture/README.md`](architecture/README.md).
4. ADRs são imutáveis depois de aceitos. Para mudar, crie um novo ADR e marque o antigo como `Substituído por NNNN`.

## Convenções

- **Idioma:** documentação em português (pt-BR). Código, identificadores, nomes de arquivo de código e mensagens de commit em inglês.
- **Commits:** pequenos e focados, no formato [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- **Mudanças mínimas:** faça só o que a tarefa pede. Sem refactors oportunistas, sem arquivos extras.
- **Sem segredos no repositório:** nada de chaves de API, tokens ou credenciais em código ou docs.
- **UI:** antes de criar ou revisar qualquer view, leia [`.claude/skills/liquid-glass/SKILL.md`](.claude/skills/liquid-glass/SKILL.md) (regras de Liquid Glass, 10-foot UI e foco, com checklist de revisão).

## Comandos

Ainda não há build, testes ou lint. Quando o projeto for criado, documente aqui os comandos exatos (build, test, lint, run) — agentes dependem desta seção para validar o próprio trabalho.

## Mantendo este arquivo

Se você (agente ou humano) descobrir algo que outro agente precisaria saber para trabalhar bem aqui — um comando, uma armadilha, uma convenção — atualize este arquivo no mesmo PR.
