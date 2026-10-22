# 0002. App nativo em Swift com WebKit para os serviços de streaming

- **Status:** Proposto
- **Data:** 2026-10-21
- **Substitui:** —
- **Substituído por:** —

## Contexto

O cine-kit é um launcher de mídia em tela cheia para um Mac ligado à TV. A forma principal de assistir é abrir os serviços de streaming (Netflix, Prime Video etc.) num navegador controlado pelo app.

Requisito inegociável: **imagem na melhor qualidade possível, sem limitação por DRM.**

Serviços-alvo: Netflix, Prime Video, Disney+, Max, Globoplay e YouTube. Hardware-alvo: Mac mini M4 ligado a um monitor 4K.

No macOS, os serviços entregam a maior resolução (1080p/4K, HDR) ao WebKit com FairPlay. Engines Chromium usam Widevine L3 e são limitadas pelos serviços (a Netflix, por exemplo, costuma limitar a 720p). O app é de uso pessoal: sem App Store e sem sandbox obrigatório.

## Decisão

- O app será **nativo, em Swift**, com UI em **SwiftUI** e **AppKit** onde o SwiftUI não alcançar (janela em tela cheia, cursor, eventos).
- Os serviços de streaming abrem em **WKWebView** (WebKit do sistema, com FairPlay).
- **Plano B por serviço:** se um serviço entregar qualidade pior ou bloquear a webview embutida, o app abre o **Safari** em tela cheia e envia os comandos do controle via `CGEvent` (requer permissão de Acessibilidade).
- Qual caminho cada serviço usa será definido por um spike comparando WKWebView e Safari (login, resolução, HDR).

## Alternativas consideradas

- **Electron (inclusive o fork castlabs, com Widevine)** — Chromium no Mac fica em Widevine L3, com resolução limitada pelos serviços. Viola o requisito de qualidade.
- **Chrome/Chromium externo em modo quiosque** — mesma limitação de DRM do Electron.
- **Tauri (WKWebView + Rust)** — usa o WebKit, mas a abstração do wry esconde parte da configuração do WKWebView e a integração com o sistema (CGEvent, processos, energia) acaba indo para Rust/Objective-C do mesmo jeito. Não traz vantagem sobre o nativo.
- **Flutter** — sem acesso direto ao WebKit/FairPlay; dependeria de plugins.

## Consequências

- Acesso total à configuração do WKWebView e às APIs do sistema (impedir sleep, abrir no login, esconder cursor, gerenciar processos).
- O motor de foco do SwiftUI no macOS é limitado; a navegação estilo TV (grade por setas, rolagem até o item focado) provavelmente precisará de uma camada própria de foco, a ser decidida em ADR próprio.
- 4K exige hardware compatível. O M4 atende (decodifica HEVC e AV1 em hardware); o monitor e o cabo precisam suportar HDCP 2.2, e HDR depende de o monitor ser HDR. Alguns serviços também exigem plano de assinatura com 4K.
- Pendências: escolher a versão mínima do macOS e a estrutura do projeto (Xcode project vs. Swift Package) e documentar os comandos de build/test no `AGENTS.md`.
