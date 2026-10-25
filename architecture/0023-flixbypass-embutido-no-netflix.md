# 0023. FlixBypass embutido no Netflix

- **Status:** Proposto
- **Data:** 2026-10-25
- **Substitui:** —
- **Substituído por:** —

## Contexto

No Netflix, a verificação de residência bloqueia o uso fora da rede da conta. A extensão [FlixBypass](https://github.com/singhkhushwant/FlixBypass-public) resolve isso no navegador, mas extensões instaladas no Safari não rodam no `WKWebView` do app. O núcleo da extensão é um content script `document_start` no `world: MAIN`, que é o que um `WKUserScript` faz por padrão.

## Decisão

- **Scripts copiados como estão.** `src/inject_early.js` e `src/content.js` do commit `2952269af8a0bb1031df4094c58f8066024178a7` ficam em `Sources/CineKit/Resources/` como `flixbypass-inject-early.js` e `flixbypass-content.js`, sem edição, ao lado da licença MIT (`flixbypass-LICENSE.txt`) com a URL e o SHA de origem.
- **Só no Netflix.** `WebProfile.for(_:)` liga `bypassesNetflixHousehold` para o host `netflix.com` ou `*.netflix.com`, no mesmo lugar da regra do YouTube ([0010](0010-youtube-com-ui-de-tv-na-webview.md)).
- **Injeção.** O `ServiceWebView` adiciona os dois scripts como `WKUserScript` em `.atDocumentStart`, só no frame principal, somados ao `spatial-navigation.js`.
- **Sempre ligado.** Não há toggle nem configuração.

## Alternativas consideradas

- **`WKWebExtensionController`** — suporte genérico a extensões exige empacotar e carregar a extensão inteira, com background e popup; é muito mais código para usar só dois scripts.
- **Ler o `manifest.json` e injetar os `content_scripts`** — um leitor de manifest para uma extensão só, e o `content.js` nem está no manifest (é injetado pelo background).
- **Submodule ou download no build** — o build passa a depender de um repositório de terceiros e da rede.

## Consequências

- Atualizar o FlixBypass é copiar os arquivos de novo à mão e trocar o SHA na licença.
- Contornar a verificação de residência vai contra os termos de uso da Netflix e pode levar ao bloqueio da conta.
- `background.js`, popup e a aba de doação da extensão ficam de fora, porque dependem de APIs de extensão (`tabs`, `scripting`, `storage`).
- Uma página do Netflix já em cache ([0014](0014-servicos-vivos-em-segundo-plano.md)) só recebe os scripts quando o `WKWebView` é recriado, por exemplo ao reabrir o app.
