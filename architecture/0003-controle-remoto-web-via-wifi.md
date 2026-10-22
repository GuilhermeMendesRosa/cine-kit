# 0003. Controle remoto web via Wi-Fi

- **Status:** Proposto
- **Data:** 2026-10-21
- **Substitui:** —
- **Substituído por:** —

## Contexto

O cine-kit precisa ser usado do sofá, sem mouse. O controle principal será um app web aberto no celular, na mesma rede Wi-Fi do Mac. Mouse e teclado ligados ao Mac também devem funcionar.

## Decisão

- O app do Mac embute um **servidor HTTP + WebSocket** na rede local. Ele serve o app web do controle e recebe os comandos por WebSocket.
- Os comandos seguem um protocolo próprio e versionado (ex.: navegação direcional, OK, voltar, home, play/pause, texto, movimento de mouse), traduzidos pelo app para a UI própria, para o WKWebView ou para o Safari (ver [0002](0002-app-nativo-swift-com-webkit.md)).
- Mouse e teclado locais continuam funcionando normalmente, como entrada paralela.
- A stack do app web do controle será decidida em ADR próprio; a preferência é algo leve (ex.: TypeScript + Vite).

## Alternativas consideradas

- **Siri Remote / gamepad via `GameController`** — não exige rede, mas não digita texto (login, busca) e não emula mouse. Pode ser somado depois.
- **App nativo de iOS como controle** — mais trabalho de desenvolvimento e distribuição; um app web abre em qualquer celular.
- **Só teclado e mouse** — inviável do sofá.

## Consequências

- O servidor fica exposto na rede local: precisa de pareamento simples (ex.: código mostrado na TV) para que outro dispositivo da rede não controle o Mac.
- Descoberta: o controle pode ser aberto por QR code na TV ou por nome Bonjour (`cine-kit.local`).
- O protocolo de comandos vira um contrato entre os dois apps e deve ser documentado e versionado.
