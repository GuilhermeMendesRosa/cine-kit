# 0006. Estrutura do projeto como Swift Package

- **Status:** Aceito
- **Data:** 2026-10-21
- **Substitui:** —
- **Substituído por:** —

## Contexto

O [0002](0002-app-nativo-swift-com-webkit.md) deixou pendente a estrutura do projeto (Xcode project vs. Swift Package) e os comandos de build/test. A máquina de desenvolvimento tem só as Command Line Tools (Swift 6.4, Swift Testing), sem Xcode: `xcodebuild` não roda, mas `swift build` e `swift test` funcionam.

Queremos testar a lógica (foco, catálogo de apps, validação) sem depender de UI, e manter a UI fina.

## Decisão

- O projeto é um **Swift Package** (`Package.swift` na raiz), **sem dependências externas**, com `platforms: [.macOS(.v26)]` (ver [0005](0005-ui-nativa-com-liquid-glass.md)).
- Três targets:
  - `CineKitCore` (library): lógica pura. **Não importa SwiftUI, AppKit nem WebKit.**
  - `CineKit` (executable): a UI (SwiftUI + AppKit + WebKit), depende de `CineKitCore`.
  - `CineKitCoreTests`: testes do Core com Swift Testing.
- O `.app` é montado por `scripts/bundle.sh`: `swift build -c release`, cria `.build/CineKit.app` com `Info.plist` mínimo (bundle id `dev.guilhermemendes.CineKit`) e assina ad hoc (`codesign -s -`). Executável solto, sem bundle id, atrapalha o WKWebView e a tela cheia.
- Comandos documentados no `AGENTS.md`.

## Alternativas consideradas

- **Xcode project (à mão, XcodeGen ou Tuist)** — exige Xcode instalado para build; XcodeGen/Tuist acrescentam dependência de ferramenta.
- **Executável único, sem library** — mistura lógica e UI e deixa os testes dependentes de SwiftUI/AppKit.

## Consequências

- Build e testes rodam só com as Command Line Tools, inclusive em CI. Sem Xcode, o build usa o SDK do macOS 26 das CLT (`SDKROOT`) e o `swift test` precisa de `-plugin-path` para os macros do Swift Testing; detalhes em `AGENTS.md`.
- Sem testes de UI/snapshot: a UI é validada rodando o `.app`.
- Sem entitlements, ícone, assinatura Developer ID nem notarização. Quando precisarmos disso (ex.: distribuir, sandbox, permissões que exigem entitlements), migrar para um projeto Xcode em novo ADR.
- Resolve a pendência de estrutura do 0002; a versão mínima ficou no 0005.
