# AGENTS.md

Instruções para agentes de IA (Claude Code, Codex, Cursor, Copilot, etc.) que trabalham neste repositório. Humanos também devem seguir.

## O projeto

**cine-kit** é um app para macOS que transforma o Mac numa TV box: UI em tela cheia, navegável à distância por controle remoto/teclado, focada em mídia. Veja o [README](README.md) para a visão geral.

Fase atual: **MVP em desenvolvimento**. Stack: Swift + SwiftUI/AppKit/WebKit num Swift Package, macOS 26+ (ADRs [0002](architecture/0002-app-nativo-swift-com-webkit.md), [0005](architecture/0005-ui-nativa-com-liquid-glass.md), [0006](architecture/0006-estrutura-swift-package.md)).

## Antes de começar qualquer tarefa

1. Leia [`architecture/README.md`](architecture/README.md) e os ADRs com status `Aceito`. Eles são as regras do projeto.
2. Não contradiga um ADR aceito. Se a tarefa exigir isso, pare e proponha um novo ADR que o substitua.
3. Se algo não estiver decidido (stack, dependência, estrutura de pastas), **não decida sozinho em silêncio**: proponha um ADR com status `Proposto` e pergunte.

## Decisões de arquitetura (ADRs)

Toda decisão que seja difícil de reverter ou que afete a estrutura do projeto vira um ADR em `architecture/`. Exemplos:

- Escolha de linguagem, framework de UI, versão mínima do macOS
- Adoção de dependências externas
- Organização de módulos/pastas
- Modelo de distribuição (App Store, notarização, direto)
- Integrações com serviços de terceiros

Processo:

1. Copie [`architecture/template.md`](architecture/template.md) para `architecture/NNNN-titulo-em-kebab-case.md`, usando o próximo número livre (4 dígitos).
2. Preencha contexto, decisão, alternativas e consequências.
3. Adicione uma linha no índice de [`architecture/README.md`](architecture/README.md).
4. ADRs são imutáveis depois de aceitos. Para mudar, crie um novo ADR e marque o antigo como `Substituído por NNNN`.

## Convenções

- **Idioma:** documentação em português (pt-BR). Código, identificadores, nomes de arquivo de código e mensagens de commit em inglês.
- **Commits:** pequenos e focados, no formato [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- **Branch única:** projeto de uma pessoa só. Todo trabalho é commitado direto na `main` e enviado com `git push origin main`. Não crie branches, worktrees nem pull requests.
- **Mudanças mínimas:** faça só o que a tarefa pede. Sem refactors oportunistas, sem arquivos extras.
- **Sem segredos no repositório:** nada de chaves de API, tokens ou credenciais em código ou docs.
- **UI:** antes de criar ou revisar qualquer view, leia [`.claude/skills/liquid-glass/SKILL.md`](.claude/skills/liquid-glass/SKILL.md) (regras de Liquid Glass, 10-foot UI e foco, com checklist de revisão).

## Comandos

Rodam só com as Command Line Tools (sem Xcode). Ainda não há lint.

```sh
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk
TESTING_PLUGINS=/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing

swift build                                                                  # build
swift test -Xswiftc -plugin-path -Xswiftc "$TESTING_PLUGINS"                 # suíte completa
swift test -Xswiftc -plugin-path -Xswiftc "$TESTING_PLUGINS" --filter ShelfFocusTests  # uma suíte
scripts/bundle.sh && open .build/CineKit.app                                 # monta e abre o .app
scripts/dmg.sh                                                               # depois do bundle: .build/CineKit-<versão>.dmg
```

Release ([ADR 0017](architecture/0017-distribuicao-por-dmg-no-github-releases.md)): `git tag vX.Y.Z && git push origin vX.Y.Z` dispara `.github/workflows/release.yml`, que testa, gera o `.dmg` (versão vinda da tag, por `VERSION`) e publica no GitHub Releases. O `ci.yml` roda os testes a cada push na `main`. Os runners têm Xcode, então as armadilhas das Command Line Tools abaixo não se aplicam lá.

Controle remoto web ([ADR 0003](architecture/0003-controle-remoto-web-via-wifi.md), [0011](architecture/0011-app-web-do-controle-em-react.md)), em `remote/` (Node 22 + npm; o `scripts/bundle.sh` também precisa deles):

```sh
(cd remote && npm ci && npm test)   # testes do app web
(cd remote && npm run dev)          # itera no layout no navegador do Mac
```

- Para testar no celular, use o `.app`: ele serve o build em `http://<LocalHostName>.local:8686`, e o QR fica em Configurações → Controle remoto. O `npm run dev` não tem a API.

Apps Android ([ADR 0004](architecture/0004-apps-android-via-emulador.md), [0018](architecture/0018-sdk-android-instalado-pelo-app.md)):

- O próprio app instala o SDK (Configurações → Android → Apps Android → Ligado): baixa os zips fixados em `AndroidSDKPackage` para `~/Library/Application Support/CineKit/android/sdk`, o scrcpy-server para `~/Library/Application Support/CineKit/android/` e escreve o AVD `cinekit-tv` em `~/.android/avd`. Sem Homebrew nem Java.
- O app **não lê `ANDROID_HOME`**: apps abertos pelo Finder não herdam o ambiente, então o caminho é fixo em `AndroidSDK.default`.
- Para testar a instalação do zero, apague `~/Library/Application Support/CineKit/android` e `~/.android/avd/cinekit-tv.*`, e `defaults delete dev.guilhermemendes.CineKit androidEnabled` para o toggle voltar ao padrão.

Armadilhas das Command Line Tools:

- **`SDKROOT` no SDK 26:** no SDK do macOS 27, `@State` e outros wrappers do SwiftUI viram macros cujo plugin (`SwiftUIMacros`) só vem com o Xcode; sem o `SDKROOT` o build falha com `plugin for module 'SwiftUIMacros' not found`. O `scripts/bundle.sh` já fixa esse SDK.
- **`-plugin-path` no `swift test`:** o plugin de macros do Swift Testing fica em `plugins/testing`, fora do caminho padrão; sem a flag, `@Test` falha com `plugin for module 'TestingMacros' not found`.
- Com o Xcode instalado, as duas armadilhas somem e `swift build`/`swift test` puros funcionam.

## Mantendo este arquivo

Se você (agente ou humano) descobrir algo que outro agente precisaria saber para trabalhar bem aqui — um comando, uma armadilha, uma convenção — atualize este arquivo no mesmo commit.
