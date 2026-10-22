# 0010. YouTube com a UI de TV na webview

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** a parte do YouTube no [0008](0008-navegacao-por-setas-nos-servicos-web.md)
- **Substituído por:** —

## Contexto

O usuário tentou usar o YouTube pelo APK do YouTube para Android TV no emulador ([0004](0004-apps-android-via-emulador.md)). O app abre, mas mostra "YouTube is not supported on this device". O APK carrega `youtube.com/tv`, e o servidor do Google recusa o aparelho porque ele se identifica como emulador sem certificação (`ro.product.model=sdk_google_atv64_arm64`, `ro.build.characteristics=emulator`, Widevine L3). Essas propriedades são só leitura numa imagem `user`, sem root.

Na webview, o site desktop do YouTube é feito para mouse, e o script genérico do 0008 só consegue aproximar uma navegação de TV. O 0008 rejeitou as UIs de TV dos serviços como solução **genérica**, porque só alguns serviços têm uma. O YouTube tem.

## Decisão

- Só o YouTube (hosts `youtube.com` e `www.youtube.com`) abre **`https://www.youtube.com/tv`** com o user agent de uma Smart TV Tizen: `Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/538.1 (KHTML, like Gecko) Version/6.0 TV Safari/538.1`.
- Nessa página, o `spatial-navigation.js` **não** é injetado: a própria UI de TV trata as setas, o Enter e o Backspace (voltar).
- O Esc continua tratado no Swift e volta para a home do cine-kit.
- A regra fica no Core, em `WebProfile.for(_:)`, e é decidida pela URL. Os padrões já salvos no `apps.json` têm `https://www.youtube.com` e o projeto não faz migration.
- Os outros serviços continuam como no 0008.

## Alternativas consideradas

- **Root (Magisk) no AVD + spoof das props de uma TV certificada** — setup frágil, o Widevine continua L3, uma atualização do YouTube pode quebrar tudo e é falsificar a identidade de um aparelho de terceiro.
- **SmartTube como APK** — funciona no emulador, mas depende de um cliente não oficial e mantém o custo do emulador para um serviço que a webview atende.
- **Aceitar a limitação** — o YouTube continuaria só com o site desktop, ruim de navegar pelo controle.
- **User agent do PS4 Leanback** — também recebe a UI de TV; fica como reserva caso o da Tizen pare de funcionar.

## Consequências

- O YouTube ganha a UI de 10 pés oficial, navegável pelo teclado/controle, sem o emulador.
- Depende de o Google continuar servindo o `/tv` para esse user agent. Se parar, basta trocar a string em `WebProfile`.
- O APK do YouTube no emulador continua bloqueado; não há motivo para usá-lo.
