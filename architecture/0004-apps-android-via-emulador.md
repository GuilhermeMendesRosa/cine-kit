# 0004. Apps Android (APK) via emulador, só para apps sem DRM

- **Status:** Proposto
- **Data:** 2026-10-21
- **Substitui:** —
- **Substituído por:** —

## Contexto

Alguns apps alternativos que o usuário quer usar só existem para Android. Eles não usam DRM. Os serviços com DRM são atendidos pelo WebKit (ver [0002](0002-app-nativo-swift-com-webkit.md)).

## Decisão

- APKs rodam no **Android Emulator oficial** (SDK do Android) com imagem **arm64**, sem janela própria (`-no-window`).
- O cine-kit inicia/para o emulador como processo filho, instala e abre apps via `adb` e repassa os comandos do controle (`adb shell input` ou API gRPC do emulador).
- A tela do emulador é exibida dentro do cine-kit; a técnica de captura (gRPC do emulador ou stream estilo scrcpy) será definida num spike.
- É um **módulo opcional**: o app funciona sem o SDK do Android instalado.
- **Fora do escopo:** apps com DRM ou que dependem de Play Integrity.

## Alternativas consideradas

- **BlueStacks Air** — roda bem no Apple Silicon, mas é fechado e difícil de automatizar e embutir.
- **Waydroid / Redroid** — dependem de kernel Linux; exigiriam uma VM Linux, com muito mais complexidade.
- **Não suportar APK** — perde os apps alternativos que motivaram o requisito.

## Consequências

- O emulador consome alguns GB de RAM e leva dezenas de segundos para iniciar a frio; vale mantê-lo pausado ou com snapshot.
- Depende do SDK do Android instalado na máquina (fora do repositório).
- Apps que exigem Google Play Services precisam de imagem com Google APIs/Play.
