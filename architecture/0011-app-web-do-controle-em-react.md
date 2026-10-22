# 0011. App web do controle em React

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** —
- **Substituído por:** —

## Contexto

O [0003](0003-controle-remoto-web-via-wifi.md) definiu que o controle remoto é um app web servido pelo Mac e deixou a stack para um ADR próprio, com preferência por algo leve (TypeScript + Vite). O app tem poucos estados (sem pareamento, pareamento expirado, Mac não encontrado) e um layout de botões, mas precisa de testes para o pareamento, a chamada da API e a repetição ao segurar.

## Decisão

- O app web fica em **`remote/`**, com **Vite + React + TypeScript** e testes em **Vitest**, gerenciado por **npm** (`package-lock.json` versionado).
- Sem biblioteca de UI: CSS próprio, visual escuro, alvos grandes, D-pad circular no estilo do Siri Remote.
- Para a tela inicial do iOS: `apple-touch-icon` 180×180 gerado de `assets/AppIcon.png`, `manifest.webmanifest` com `display: standalone` e as metas `apple-mobile-web-app-*`.
- O `scripts/bundle.sh` roda `npm ci && npm run build` em `remote/` e copia `remote/dist/` para `CineKit.app/Contents/Resources/remote/`. Um só artefato.
- É a primeira dependência npm do projeto. A regra "sem dependências externas" do [0006](0006-estrutura-swift-package.md) continua valendo para o Swift Package.

## Alternativas consideradas

- **HTML + JS sem build** — sem dependências, mas sem tipos e com testes mais difíceis de montar.
- **Svelte / Preact** — menores, mas React é mais conhecido e o tamanho não importa numa LAN.
- **Biblioteca de UI** — peso e estilo que não ajudam num layout de poucos botões.

## Consequências

- Montar o `.app` passa a exigir Node 22 e npm.
- `remote/node_modules/` e `remote/dist/` ficam fora do git.
- Para testar no celular, usa-se o `.app`, que serve o build; o `npm run dev` serve para iterar no layout no navegador do Mac.
