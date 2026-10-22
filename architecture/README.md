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
| [0002](0002-app-nativo-swift-com-webkit.md) | App nativo em Swift com WebKit para os serviços de streaming | Proposto | 2026-10-21 |
| [0003](0003-controle-remoto-web-via-wifi.md) | Controle remoto web via Wi-Fi | Proposto | 2026-10-21 |
| [0004](0004-apps-android-via-emulador.md) | Apps Android (APK) via emulador, só para apps sem DRM | Proposto | 2026-10-21 |
| [0005](0005-ui-nativa-com-liquid-glass.md) | UI nativa com Liquid Glass | Proposto | 2026-10-21 |
