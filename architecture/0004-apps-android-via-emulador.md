# 0004. Apps Android (APK) via emulador, só para apps sem DRM

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** —
- **Substituído por:** [0009](0009-video-android-pelo-framebuffer-do-emulador.md) (só a parte de vídeo)

## Contexto

Alguns apps alternativos que o usuário quer usar só existem para Android. Eles não usam DRM. Os serviços com DRM são atendidos pelo WebKit (ver [0002](0002-app-nativo-swift-com-webkit.md)).

O usuário adiciona um `.apk` nas configurações e ele vira um card na home, igual aos serviços web. Abrir o card deve mostrar só o app Android em tela cheia, sem launcher, boot ou nada que lembre o Android, e as teclas devem se comportar como o controle de uma TV. A lógica precisa continuar testável no `CineKitCore`, sem AppKit/SwiftUI/WebKit e sem dependências Swift externas ([0006](0006-estrutura-swift-package.md)).

## Decisão

- **Runtime:** o **Android Emulator oficial**, headless (`-no-window -no-boot-anim`), com quickboot, rodando o AVD `cinekit-tv` com a imagem **`system-images;android-36;android-tv;arm64-v8a`** (Android TV sem Google Play: sem login nem wizard, boota mais rápido).
- **Instalação:** `scripts/android-setup.sh` instala as Command Line Tools pelo Homebrew, os pacotes do SDK, cria o AVD e baixa o scrcpy-server. O SDK fica em `/opt/homebrew/share/android-commandlinetools` (o app não lê `ANDROID_HOME`, que apps abertos pelo Finder não herdam).
- **Módulo opcional:** sem SDK, AVD ou scrcpy-server, toda a UI Android some e o app funciona como antes.
- **Ciclo de vida:** a VM sobe em `applicationDidFinishLaunching` e morre em `applicationWillTerminate`. Um emulador já rodando (`emulator-5554` no `adb devices`) é reaproveitado. Ao abrir um app, a VM morta tenta subir de novo uma vez.
- **Vídeo e input:** **scrcpy-server** (versão e sha256 fixos no script): H.264 por socket via `adb forward`, decodificado com VideoToolbox em `AVSampleBufferDisplayLayer`. Teclas e texto vão pelo socket de controle do scrcpy. O áudio sai pelo próprio emulador, direto no Mac.
- **Modelo:** um app Android é um `StreamingApp` com `url = android-app://<package>`, sem migration do `apps.json`.
- **Adicionar:** botão "Adicionar APK…" → `aapt2 dump badging` → `adb install -r` → card com o nome do `application-label`. Editar mostra só Nome e Foto. Remover faz `adb uninstall` best-effort.
- **Abrir:** tela "Abrindo <nome>…" até `sys.boot_completed=1` e o package em primeiro plano, para o launcher nunca aparecer. O app é aberto com `cmd package resolve-activity` (`LEANBACK_LAUNCHER`, com fallback para `LAUNCHER`) e `am start -n`. Erro ou timeout de 90 s mostra a tela de falha.
- **Teclas:** setas → DPAD, Return → DPAD_CENTER, Espaço → MEDIA_PLAY_PAUSE, Delete → DEL, outros caracteres → texto. Teclas com ⌘ não são repassadas. Esc → BACK; segurar Esc → HOME e volta à home do cine-kit. Se o app sai do primeiro plano, o cine-kit volta à home. Voltar à home envia HOME e encerra o stream; o app continua vivo e retoma de onde estava.
- **Resolução:** 1080p (`-skin 1920x1080`, 320 dpi) ou 4K (`-skin 3840x2160`, 640 dpi), escolhida nas configurações (`androidResolution` no `UserDefaults`). A troca reinicia a VM.
- **Camadas:** no Core (Foundation), `AndroidSDK`, `CommandRunner`, `AndroidRuntime`, `AndroidKeyMap`, `ApkBadging`, `ForegroundActivity` e `ScrcpyControlMessage`. Na UI, `AndroidScreen`, `ScrcpyClient` e `ScrcpyVideoView`.
- **Fora do escopo:** apps com DRM, que dependem de Play Integrity ou de Google Play Services; mouse/touch dentro do app; download do SDK pelo próprio app.

## Alternativas consideradas

- **VM própria com Virtualization.framework** — exigiria montar e manter uma imagem Android própria.
- **BlueStacks Air** — roda bem no Apple Silicon, mas é fechado e difícil de automatizar e embutir.
- **Waydroid / Redroid** — dependem de kernel Linux; exigiriam uma VM Linux, com muito mais complexidade.
- **Imagem Google TV / com Play** — exige login e wizard, contra o "não ver o Android".
- **gRPC do emulador para vídeo e input** — exigiria `grpc-swift`, contra o 0006.
- **`adb shell input` para as teclas** — leva 200–500 ms por tecla.
- **LaunchAgent no login do macOS** — deixaria um processo órfão permanente.
- **Não suportar APK** — perde os apps alternativos que motivaram o requisito.

## Consequências

- O emulador consome alguns GB de RAM (o AVD usa `hw.ramSize=2048`) enquanto o cine-kit está aberto, e leva dezenas de segundos para iniciar a frio.
- Depende do SDK do Android instalado na máquina (fora do repositório) pelo `scripts/android-setup.sh`.
- O scrcpy-server é um binário externo (Apache-2.0), baixado pelo script com sha256 conferido e fora do repositório. O protocolo dele é interno e muda entre versões: atualizar a versão exige revisar `ScrcpyControlMessage` e o handshake do vídeo.
- Apps que exigem Google Play Services não funcionam.
