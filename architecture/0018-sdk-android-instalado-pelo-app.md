# 0018. SDK Android instalado pelo próprio app

- **Status:** Proposto
- **Data:** 2026-10-22
- **Substitui:** no [0004](0004-apps-android-via-emulador.md), a "Instalação", o caminho do SDK em `/opt/homebrew` e o "download do SDK pelo próprio app" entre os itens fora do escopo
- **Substituído por:** —

## Contexto

Com a distribuição por `.dmg` ([0017](0017-distribuicao-por-dmg-no-github-releases.md)), quem instala o app não tem o repositório nem o `scripts/android-setup.sh`. Esse script ainda exigia Homebrew e Java (o `sdkmanager` é Java). As dependências dos apps Android precisam ser instaladas a partir do próprio app.

Em tempo de execução o app só usa binários nativos: `adb`, `emulator`, `aapt2`, a imagem do sistema e o scrcpy-server. O `sdkmanager` e o `avdmanager` só baixam zips e escrevem arquivos de texto.

## Decisão

- **Onde:** o SDK fica em `~/Library/Application Support/CineKit/android/sdk`, ao lado do scrcpy-server. O AVD `cinekit-tv` continua em `~/.android/avd`, onde o emulador procura sem variável de ambiente.
- **O quê:** zips baixados direto de `dl.google.com/android/repository`, com versão, URL e sha1 fixos no código (`AndroidSDKPackage`): `platform-tools` 37.0.1, `emulator` 37.2.12 (darwin aarch64), `build-tools` 35.0.0 e `system-images;android-36;android-tv;arm64-v8a` rev 4. O scrcpy-server v5.0.1 vem do GitHub com sha256 fixo, como antes. Cerca de 1,5 GB de download.
- **Como:** `AndroidInstaller` (no Core) baixa cada pacote para um arquivo temporário, confere o checksum, extrai com `ditto -x -k` e move a pasta de topo do zip para o caminho do SDK. Depois escreve o AVD (`AndroidAVD`, o mesmo `config.ini` que o `avdmanager` gerava, com 2 GB de RAM e 4 GB de dados). É idempotente: pula o que já existe, então uma instalação interrompida continua de onde parou.
- **Sem Homebrew, Java, sdkmanager nem avdmanager.**
- **Quando:** na primeira abertura o app pergunta uma vez se deve instalar o suporte a apps Android. Nas Configurações, a seção Android mostra o botão "Instalar apps Android" enquanto o SDK não existe, e o progresso durante a instalação. Os dois mostram que instalar aceita os termos de licença do Android SDK. Ao terminar, a VM sobe e "Adicionar APK…" aparece, sem reiniciar o app.
- O `scripts/android-setup.sh` sai do repositório.

## Alternativas consideradas

- **Rodar o `android-setup.sh` de dentro do app** — continua exigindo Homebrew e Java na máquina de quem instala.
- **Embutir o SDK no `.dmg`** — o `.dmg` passaria de 1,5 GB para todo mundo, inclusive quem nunca usa Android.
- **Ler o `repository2-3.xml` e baixar sempre a versão mais nova** — versões novas do emulador ou da imagem podem quebrar o vídeo e o protocolo do scrcpy ([0009](0009-video-android-pelo-framebuffer-do-emulador.md)); fixar mantém o que foi testado.
- **Instalar sem perguntar** — baixaria 1,5 GB e aceitaria uma licença sem consentimento.

## Consequências

- Atualizar uma versão do SDK é trocar URL e sha1 em `AndroidSDKPackage` (os valores estão em `repository2-3.xml` e `sys-img/android-tv/sys-img2-3.xml`).
- Um SDK instalado antes pelo script em `/opt/homebrew/share/android-commandlinetools` não é mais usado; pode ser removido com `brew uninstall --cask android-commandlinetools`.
- O instalador ganha testes no Core com download e extração falsos.
