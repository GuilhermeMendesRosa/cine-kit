# 0001. Registrar decisões de arquitetura com ADRs

- **Status:** Aceito
- **Data:** 2026-10-21
- **Substitui:** —
- **Substituído por:** —

## Contexto

O cine-kit é desenvolvido de forma AI-first: boa parte do código será escrita ou alterada por agentes de IA. Agentes não carregam memória entre sessões, então o raciocínio por trás das escolhas do projeto precisa estar no próprio repositório, em formato fácil de encontrar e ler.

## Decisão

Toda decisão de arquitetura relevante será registrada como um ADR em `architecture/`, um arquivo por decisão, numerado sequencialmente e seguindo `architecture/template.md`. O `AGENTS.md` instrui agentes a ler os ADRs aceitos antes de trabalhar e a propor novos ADRs em vez de tomar decisões estruturais em silêncio.

## Alternativas consideradas

- **Wiki ou ferramenta externa (Notion, Confluence)** — fica fora do alcance dos agentes e desatualiza em relação ao código.
- **Só comentários no código / mensagens de commit** — espalhado, difícil de achar e sem visão do *porquê* das decisões transversais.
- **Um único documento de arquitetura** — cresce sem controle e perde o histórico de quando e por que cada coisa mudou.

## Consequências

- Decisões ficam versionadas junto com o código e revisadas em PR.
- Agentes têm uma fonte de verdade explícita para seguir.
- Exige disciplina: toda decisão estrutural precisa de um ADR antes (ou junto) da implementação.
