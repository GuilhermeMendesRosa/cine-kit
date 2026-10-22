# 0019. Tema escolhido no app e pareado com o controle

- **Status:** Proposto
- **Data:** 2026-10-22
- **Substitui:** no [0013](0013-tema-e-configuracoes-navegaveis.md), o tema Automático e o "controle segue o tema do celular"
- **Substituído por:** —

## Contexto

O [0013](0013-tema-e-configuracoes-navegaveis.md) deu ao app os temas Automático, Claro e Escuro, e fez o controle no celular seguir o tema do próprio celular. O usuário quer que o tema não puxe o padrão do dispositivo: ele escolhe no menu, e o Mac e o controle ficam com o mesmo tema. O controle também precisa de um botão para trocar entre claro e escuro.

## Decisão

- **Só Claro e Escuro**, padrão **Escuro**, salvo em `@AppStorage("appTheme")`. Um `system` já salvo cai no padrão (o `@AppStorage` ignora valor desconhecido). O `enum AppTheme` passa para o `CineKitCore`.
- **Protocolo:** `GET /api/state` devolve `{"clickSound":bool,"theme":"light"|"dark"}`; `POST /api/theme {"theme":"light"|"dark"}` grava o tema e responde 204 (400 com valor inválido, 401 sem token). O valor é explícito, então um toque duplo ou um polling atrasado não desfaz a troca.
- **Controle:** usa o tema do Mac, não o do celular. Abre com o último tema salvo no `localStorage` (senão Escuro), sem piscar; o polling de 1,5 s do [0015](0015-controle-absoluto-analogico-e-som.md) aplica o tema do Mac; offline mantém o último.
- **Botão de tema** na linha 1 do controle, entre o volume e o `⌂`: ícone fixo de círculo meio preenchido, 64 px, mesmo vidro do `⌂`, `aria-label="Alternar tema"`. A troca é otimista (o celular muda na hora); 401 expira o pareamento e, offline, o próximo `/api/state` corrige.
- **Mídia:** no Mac, as telas de mídia continuam sempre escuras. O controle segue o tema escolhido mesmo com um app aberto.

## Alternativas consideradas

- **Manter o Automático** — contradiz o pedido de não seguir o padrão do dispositivo.
- **Botão `toggleTheme` em `/api/press`** — não é idempotente: toque duplo ou polling atrasado desfaz a troca.
- **Tema do controle independente do Mac** — o pedido é que os dois fiquem pareados.
- **Push do Mac para o celular (SSE/WebSocket)** — o polling de 1,5 s já existente basta.

## Consequências

- Quem usava Automático passa a Escuro.
- O controle passa a depender do Mac para o tema; offline, usa o último salvo.
- A regra da skill `liquid-glass` passa a citar Claro/Escuro (ADR 0019).
