# 0016. Teclado de texto no controle

- **Status:** Proposto
- **Data:** 2026-10-22
- **Substitui:** no [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md), o "teclado de texto no controle" entre os itens que continuam fora; no [0015](0015-controle-absoluto-analogico-e-som.md), o botão Clique da linha 2 do "Layout do controle"
- **Substituído por:** —

## Contexto

O controle do [0015](0015-controle-absoluto-analogico-e-som.md) tem um botão Clique, mas tocar no touchpad já clica, então o botão é redundante. O que falta é digitar. Buscar no YouTube TV, preencher um campo nas Configurações ou digitar num app Android exige o teclado físico do Mac ou um teclado na tela, navegado letra por letra com as setas.

## Decisão

- **Layout:** a linha 2 passa a ser `Voltar · Teclado · Pause`. O botão Clique sai, e clicar continua sendo tocar no touchpad. O `{"type":"click"}` de `/api/pointer` não muda.
- **Digitação ao vivo.** O botão Teclado foca um `<input>` escondido, e o celular abre o teclado dele. Tocar no botão de novo, ou no Enter do teclado, fecha o teclado. Cada evento `beforeinput` sai na hora, sem botão "Enviar", para a busca da TV atualizar enquanto se digita:
  - `insertText` (e `insertReplacementText`) vai para `POST /api/text`;
  - `deleteContentBackward` envia o botão `delete`;
  - Enter envia `ok` (Return).

  O input é esvaziado a cada evento, com autocorreção, autocapitalização e autocomplete desligados, para o celular não reescrever o que já saiu.
- **Fila serial.** Uma requisição de texto em voo por vez, e o que é digitado enquanto ela espera é concatenado, como na fila de ponteiro do [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md).
- **Protocolo**, aditivo ao v1 e com o mesmo `Authorization: Bearer`:
  - `POST /api/text` com corpo `{"text":string}` responde `204`;
  - responde `400` se o texto estiver vazio, tiver mais de 256 caracteres ou trouxer caracteres de controle;
  - responde `401` se o token estiver errado ou faltar;
  - `/api/press` ganha o botão `delete`, que é a tecla Delete (51).
- **No Mac (paridade com o teclado).** Cada caractere (grafema) vira um par `keyDown`/`keyUp` postado com `NSApp.postEvent` na janela principal, com o caractere em `characters` e `keyCode` 0, como as teclas do [0003](0003-controle-remoto-web-via-wifi.md). Isso não precisa de permissão de Acessibilidade.
  - O AppKit insere o texto na webview e nos campos do SwiftUI.
  - No Android, o `AndroidKeyMap` já transforma esses eventos em `injectText`.
- **Retorno.** A vibração e o som de clique tocam ao tocar no botão Teclado, não a cada letra.

## Alternativas consideradas

- **Campo com botão "Enviar"**: um passo a mais, e a busca só reage no fim.
- **Manter o botão Clique e pôr o Teclado em outro lugar**: o Clique repete o toque no touchpad, e uma quarta coluna não cabe a 375 px com alvos de 64 px.
- **`CGEvent.keyboardSetUnicodeString` no HID**: exige a permissão de Acessibilidade, já rejeitada no 0012.
- **Mandar o texto direto para a webview (JS) ou para o scrcpy**: um caminho por tela, contra a paridade com o teclado do 0012.

## Consequências

- O texto passa pelo mesmo caminho de um teclado físico: onde o teclado do Mac digita, o controle também digita.
- O `keyCode` 0 é o da tecla A. Uma página que leia `event.code` em vez de `event.key` vê "KeyA" para qualquer letra.
- Com o teclado aberto, o celular cobre parte do touchpad e do D-pad.
