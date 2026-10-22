# 0008. Navegação por setas nos serviços web

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** —
- **Substituído por:** [0010](0010-youtube-com-ui-de-tv-na-webview.md) (só o YouTube), [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md) (Esc)

## Contexto

Ao abrir um serviço (Netflix, Prime Video, Disney+, HBO Max, Globoplay, YouTube), a webview do [0002](0002-app-nativo-swift-com-webkit.md) não recebe o foco de teclado: setas e Enter só funcionam depois de um clique. Mesmo com foco, os sites são feitos para mouse e as setas apenas rolam a página. A camada de foco do [0007](0007-camada-de-foco-da-home.md) é SwiftUI e não alcança o conteúdo de uma página web.

## Decisão

- A webview vira **first responder** ao entrar na janela (subclasse mínima de `WKWebView` com `viewDidMoveToWindow`).
- Um **script próprio de navegação espacial** (`Sources/CineKit/Resources/spatial-navigation.js`) é injetado como `WKUserScript` em `atDocumentStart`, só no frame principal. Ele escuta `keydown` em captura no `window` e só chama `preventDefault` + `stopPropagation` quando trata a tecla.
- Regras:
  - Candidatos: `a[href]`, `button`, `input`, `select`, `textarea`, `[role=button]`, `[role=link]`, `[tabindex]` com `tabIndex >= 0`, habilitados, com tamanho e visíveis.
  - A seta escolhe, entre os candidatos à frente na direção, o de menor `distância no eixo + 2 × deslocamento perpendicular`. Sem nada focado, foca o candidato visível mais próximo do canto superior esquerdo. Sem candidato na direção, rola 40% da tela.
  - O elemento focado recebe `focus`, o atributo `data-cinekit-focus` e é rolado para o centro. Enter faz `click()` nele.
  - Em campo de texto, ←/→/Enter vão para o campo. Teclas com modificador não são tratadas.
- **Exceção do vídeo:** com `document.fullscreenElement` ou um `<video>` tocando que cubra pelo menos 50% do viewport, nenhuma tecla é tratada; elas vão para o player.
- **Anel de foco:** `outline` branco de 4px com `box-shadow` escuro, sem `transform`, para ser visível de longe sem quebrar o layout dos sites.
- O Esc continua tratado no Swift e volta para a home.

## Alternativas consideradas

- **Só first responder** — as setas rolam a página, mas não movem foco entre cards.
- **Navegação espacial privada do WebKit** — API privada, sem garantia entre versões do macOS.
- **UIs de TV dos serviços (ex.: `youtube.com/tv`)** — só alguns serviços têm, e dependem de user agent de TV.
- **Monitor de teclas no Swift + `evaluateJavaScript` por tecla** — ida e volta por tecla e lógica dividida entre Swift e JS.

## Consequências

- Um único script genérico atende todos os serviços, sem seletores por site.
- Pode falhar em sites com elementos clicáveis fora dos candidatos (ex.: `div` com `onclick`); ajustes por serviço ficam para outro ADR ou tarefa.
- A lógica vive dentro da página e não tem teste automatizado; a verificação é manual.
- O controle remoto web ([0003](0003-controle-remoto-web-via-wifi.md)) vai precisar expor esta navegação para o Swift.
