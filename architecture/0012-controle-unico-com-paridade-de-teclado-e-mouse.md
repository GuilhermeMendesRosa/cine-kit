# 0012. Controle único com paridade de teclado e mouse

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** no [0003](0003-controle-remoto-web-via-wifi.md), a tabela de teclas por tela, o botão Home e o "fora: touchpad/mouse"; no [0004](0004-apps-android-via-emulador.md), o "fora: mouse/touch dentro do app"; no [0008](0008-navegacao-por-setas-nos-servicos-web.md), o "Esc volta para a home"; no [0011](0011-app-web-do-controle-em-react.md), o layout de botões
- **Substituído por:** —

## Contexto

O controle do [0003](0003-controle-remoto-web-via-wifi.md) só tem botões, e cada botão vira uma tecla que depende da tela (Voltar é Esc na home e `⌘[` na web). Não há touchpad: sites feitos para mouse e apps Android que esperam toque ficam meio inacessíveis do sofá. Ao mesmo tempo, teclado e mouse ligados ao Mac precisam continuar funcionando, e trocar entre eles e o controle não pode perder o foco.

A ideia é ter **um único controle**, igual em todo contexto: os mesmos botões (setas, OK, Pause, Clique, Voltar, Vol±) e um touchpad (cursor, toque = clique, rolagem ao lado), com vibração quando o celular permitir.

## Decisão

- **Princípio: controle = teclado + mouse do Mac.** Cada botão é exatamente uma tecla do Mac e o touchpad é exatamente o mouse do Mac. Cada contexto (home, Configurações, serviço web, app Android) passa a funcionar completo com teclado **e** com mouse. Assim controle e periféricos físicos têm paridade por construção e funcionam ao mesmo tempo, sem modo. Sai a diferenciação por tela no servidor (`RemoteScreen`).
- **Mapa de botões**, igual em todo contexto:

  | Botão | Tecla / ação no Mac |
  | --- | --- |
  | ↑ ↓ ← → | teclas 126 / 125 / 123 / 124 |
  | OK | Return (36) |
  | Pause | Espaço (49) |
  | Voltar | Esc (53) |
  | Segurar Voltar (600 ms) | Esc segurado (envia `home`) |
  | Vol − / + | CoreAudio, como no 0003 |
  | Clique | clique esquerdo onde está o ponteiro (`/api/pointer`) |

  O controle não tem mais botões Home e Mudo; `home` e `mute` continuam aceitos pelo protocolo. Espaço não faz nada nos menus (não há mídia neles).
- **Esc nos serviços web (= Voltar).** No **soltar** do Esc: se a webview está em tela cheia, sai da tela cheia; senão, se o perfil do serviço trata o voltar (YouTube TV, [0010](0010-youtube-com-ui-de-tv-na-webview.md)), envia Backspace à página; senão, se há histórico, `goBack()`; senão, volta à home do cine-kit. **Esc segurado** (primeiro auto-repeat) volta à home de qualquer lugar. É a mesma convenção do Android ([0004](0004-apps-android-via-emulador.md)). A decisão é pura (`WebBack.action` no `CineKitCore`). O `⌘[` continua como atalho extra.
- **Protocolo: `POST /api/pointer`**, aditivo ao v1 (mesmo `Authorization: Bearer`). Corpo `{"type":"move","dx":n,"dy":n}`, `{"type":"scroll","dx":n,"dy":n}` ou `{"type":"click"}`. Respostas: `204` aceito; `400` tipo desconhecido ou número inválido (não finito ou |v| > 4000); `401` token.
- **Mouse sintético no Mac.** O cursor real é movido com `CGWarpMouseCursorPosition`, seguido de `CGAssociateMouseAndMouseCursorPosition(1)` para o mouse físico não ficar suprimido por 250 ms. `mouseMoved`, `leftMouseDown` e `leftMouseUp` são postados com `NSApp.postEvent` na janela do app sob o cursor; o scroll é um `CGEvent` de roda em pixels convertido para `NSEvent` e enviado direto à janela com `sendEvent(_:)` (postado na fila, ele chega sem janela e se perde). A posição é sempre lida de `NSEvent.mouseLocation`, então mouse físico e touchpad partem do mesmo ponto. O cursor fica limitado à tela da janela do cine-kit. Sem permissão de Acessibilidade, como as teclas do 0003. Se os eventos postados não chegarem ao WebKit, tenta-se `window.sendEvent(_:)`; se ainda assim falhar, um novo ADR decide sobre `CGEvent.post` no HID.
- **Mouse e toque nos apps Android.** A view do vídeo recebe `mouseDown`/`mouseDragged`/`mouseUp` e `scrollWheel` (físicos ou sintéticos), converte o ponto da view para o pixel do Android (aspect-fit, nada nas tarjas) e envia pelo socket de controle do scrcpy que já existe: `INJECT_TOUCH_EVENT` (tipo 2, `pointerId = -2`) e `INJECT_SCROLL_EVENT` (tipo 3). Sem vídeo no scrcpy, o servidor usa as coordenadas cruas. Scroll: `delta / 20` com deltas precisos (trackpad/controle) e `delta / 1` com roda, limitado a [-16, 16]. O cursor visível é o do Mac.
- **Ponteiro x foco (troca fluida).** Um `InputMode` global (`.keys`/`.pointer`) é atualizado por um monitor local: tecla → `.keys` e o cursor some até o mouse mexer; mouse, clique ou scroll → `.pointer`. Nos menus, **hover = foco** só em `.pointer`, então as setas continuam de onde o mouse parou. A rolagem automática da prateleira só acontece em `.keys`. Um foco só, no estilo tvOS.
- **Ponteiro x foco nos sites.** O `spatial-navigation.js` ([0008](0008-navegacao-por-setas-nos-servicos-web.md)) marca o candidato sob o ponteiro num `mousemove` real (sem chamar `focus()`) e esconde o anel; a próxima seta parte do elemento marcado e mostra o anel de novo.
- **Touchpad no celular.** Relativo, como um trackpad: ganho `min(4, 1,5 + 2·v)` (v em px/ms) aplicado no celular; o Mac só soma deltas. **Um dedo move**; **toque = clique** (≤ 250 ms e ≤ 10 px); **dois dedos rolam**; uma **faixa de rolagem** de 56 px na borda direita do painel rola na vertical. Rolagem natural, ganho 2×, sem inércia. Sem clique direito, arrastar ou duplo clique.
- **Fila serial no celular.** No máximo uma requisição de ponteiro em voo; moves e scrolls se acumulam enquanto esperam; o clique (do touchpad ou do botão Clique) só sai depois do move pendente, mantendo a ordem.
- **Layout do controle**, de cima para baixo: status; touchpad com a faixa de rolagem; D-pad circular com OK no centro; Voltar · Clique · Pause; Vol − / + numa cápsula. Alvos de pelo menos 64 px.
- **Vibração.** `navigator.vibrate(10)` quando existe (Android/Chrome); senão, um clique programático no `<label>` de um `<input type="checkbox" switch>` escondido, que dá o tique háptico no Safari do iOS 18+; senão, nada. Vibra em cada botão (só no primeiro disparo ao segurar) e no toque do touchpad, nunca no movimento nem na rolagem.

## Alternativas consideradas

- **Dois controles diferentes (botões na TV, touchpad nos sites)** — o usuário quer um só, igual em todo lugar.
- **Roteamento por tela no servidor** — cada tela trataria comandos próprios; mais código e sem paridade automática com teclado e mouse físicos.
- **WebSocket para o touchpad** — menos latência, mas uma segunda forma de transporte; o 0003 já rejeitou, e a fila serial sobre HTTP basta na LAN.
- **`CGEvent.post` no HID** — eventos de sistema reais, mas exige a permissão de Acessibilidade, que com assinatura ad hoc se perde a cada build. Fica como plano B se os eventos postados no app não bastarem.
- **Cursor virtual desenhado pelo app** — não gera hover nem clique reais no WebKit.
- **`adb shell input tap` no Android** — 200 a 500 ms por toque.
- **Touchpad absoluto** — sem precisão numa TV 4K a partir da tela de um celular.

## Consequências

- Cada tela nova precisa funcionar completa com teclado e com mouse; não há mais comandos específicos por tela.
- O cursor do Mac aparece sobre a mídia ao usar o touchpad e some na próxima tecla.
- `NSOpenPanel` (Adicionar APK, Escolher foto) roda fora do processo e não recebe os eventos postados; continua sendo feito com mouse e teclado físicos.
- O sinal da rolagem no Android e o fator `k` são ajustados no teste manual.
- Continuam fora: teclado de texto no controle, clique direito, arrastar, inércia, hover dentro do Android, HUD de volume, status "conectado" ao vivo e Siri Remote/gamepad.
