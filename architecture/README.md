# Architecture Decision Records

Esta pasta registra as decisões de arquitetura do cine-kit no formato ADR (Architecture Decision Record). Cada arquivo é uma decisão, com o contexto em que foi tomada, as alternativas consideradas e as consequências.

O objetivo é que qualquer pessoa — ou agente de IA — entenda **por que** o projeto é como é, sem depender de histórico de conversa.

## Processo

1. Copie [`template.md`](template.md) para `NNNN-titulo-em-kebab-case.md` com o próximo número livre.
2. Preencha e abra com status `Proposto`.
3. Após revisão, mude para `Aceito` e adicione ao índice abaixo.
4. Não edite ADRs aceitos (exceto correções de digitação). Para mudar uma decisão, crie um novo ADR e marque o antigo como `Substituído por NNNN`.

## Status possíveis

| Status | Significado |
| --- | --- |
| Proposto | Em discussão, ainda não vale como regra |
| Aceito | Decisão em vigor |
| Rejeitado | Considerado e descartado (mantido para registro) |
| Obsoleto | Não se aplica mais |
| Substituído por NNNN | Trocado por outro ADR |

## Índice

| # | Título | Status | Data |
| --- | --- | --- | --- |
| [0001](0001-registrar-decisoes-de-arquitetura.md) | Registrar decisões de arquitetura com ADRs | Aceito | 2026-10-21 |
| [0002](0002-app-nativo-swift-com-webkit.md) | App nativo em Swift com WebKit para os serviços de streaming | Aceito | 2026-10-21 |
| [0003](0003-controle-remoto-web-via-wifi.md) | Controle remoto web via Wi-Fi | Aceito | 2026-10-22 |
| [0004](0004-apps-android-via-emulador.md) | Apps Android (APK) via emulador, só para apps sem DRM | Aceito | 2026-10-22 |
| [0005](0005-ui-nativa-com-liquid-glass.md) | UI nativa com Liquid Glass | Aceito | 2026-10-21 |
| [0006](0006-estrutura-swift-package.md) | Estrutura do projeto como Swift Package | Aceito | 2026-10-21 |
| [0007](0007-camada-de-foco-da-home.md) | Camada de foco da home | Aceito | 2026-10-21 |
| [0008](0008-navegacao-por-setas-nos-servicos-web.md) | Navegação por setas nos serviços web | Aceito | 2026-10-22 |
| [0009](0009-video-android-pelo-framebuffer-do-emulador.md) | Vídeo dos apps Android pelo framebuffer do emulador | Aceito | 2026-10-22 |
| [0010](0010-youtube-com-ui-de-tv-na-webview.md) | YouTube com a UI de TV na webview | Aceito | 2026-10-22 |
| [0011](0011-app-web-do-controle-em-react.md) | App web do controle em React | Aceito | 2026-10-22 |
| [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md) | Controle único com paridade de teclado e mouse | Aceito | 2026-10-22 |
| [0013](0013-tema-e-configuracoes-navegaveis.md) | Tema claro/escuro e Configurações navegáveis por setas | Aceito | 2026-10-22 |
| [0014](0014-servicos-vivos-em-segundo-plano.md) | Serviços vivos em segundo plano | Aceito | 2026-10-22 |
| [0015](0015-controle-absoluto-analogico-e-som.md) | Touchpad mais rápido, faixa de rolagem analógica e som de clique por app | Proposto | 2026-10-22 |
| [0016](0016-teclado-de-texto-no-controle.md) | Teclado de texto no controle | Proposto | 2026-10-22 |
| [0017](0017-distribuicao-por-dmg-no-github-releases.md) | Distribuição por .dmg no GitHub Releases | Proposto | 2026-10-22 |
| [0018](0018-sdk-android-instalado-pelo-app.md) | SDK Android instalado pelo próprio app | Proposto | 2026-10-22 |
| [0019](0019-tema-escolhido-e-pareado-com-o-controle.md) | Tema escolhido no app e pareado com o controle | Proposto | 2026-10-22 |
