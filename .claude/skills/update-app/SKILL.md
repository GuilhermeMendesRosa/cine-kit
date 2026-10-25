---
name: update-app
description: Atualiza o CineKit instalado em /Applications no Mac do dev com um build do código atual (scripts/bundle.sh), fechando o app aberto e o emulador Android com segurança antes de trocar e abrindo de novo no fim. Use quando o dev pedir para "atualizar o app no meu Mac", "instalar essa versão", "trocar o app de Aplicativos" ou invocar /update-app.
---

# Atualizar o CineKit no Mac

Troca `/Applications/CineKit.app` pelo build do working tree atual, inclusive mudanças sem commit. Não mexe em dados do usuário (`~/Library/Application Support/CineKit`, `UserDefaults`, AVD).

## Passos

1. **Monte o `.app`.** Na raiz do repo, rode `scripts/bundle.sh`. Ele já fixa o `SDKROOT` das Command Line Tools e precisa de Node 22 + npm para o controle remoto. Se falhar, pare e mostre o erro: não troque o app instalado por um build quebrado.

2. **Feche o app aberto.** Se `pgrep -f /Applications/CineKit.app/Contents/MacOS/CineKit` achar o processo, peça para ele sair normalmente:

   ```sh
   osascript -e 'tell application id "dev.guilhermemendes.CineKit" to quit'
   ```

   Espere o processo sumir (até ~15 s). Não use `kill`: o app desliga o emulador ao sair.

3. **Espere o emulador Android desligar.** Ao sair, o app roda `adb emu kill`, e o `qemu-system-aarch64-headless` pode levar alguns segundos para fechar. Espere até `pgrep -f qemu-system` voltar vazio (até ~60 s). O `sleep` em primeiro plano é bloqueado; use um laço curto, por exemplo:

   ```sh
   for i in $(seq 1 120); do pgrep -f qemu-system >/dev/null || break; perl -e 'select(undef,undef,undef,0.5)'; done
   ```

   Se o emulador continuar rodando depois disso, pare e avise o dev em vez de matar o processo, porque isso pode corromper o snapshot do AVD.

4. **Troque o app.**

   ```sh
   rm -rf /Applications/CineKit.app && ditto .build/CineKit.app /Applications/CineKit.app
   ```

5. **Abra de novo** com `open /Applications/CineKit.app` e confirme com `pgrep` que o processo subiu.

## No fim

Diga ao dev:

- que o app foi trocado e já está aberto (PID);
- a versão instalada (`defaults read /Applications/CineKit.app/Contents/Info CFBundleShortVersionString`). Um build local sai como `0.0.0-dev`, porque a versão só vem da tag na release ([ADR 0017](../../../architecture/0017-distribuicao-por-dmg-no-github-releases.md));
- se havia mudanças sem commit no build (`git status --short`).
