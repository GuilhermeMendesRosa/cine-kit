# 0021. Abrir no login e botão de ligar no controle

- **Status:** Proposto
- **Data:** 2026-10-23
- **Substitui:** —
- **Substituído por:** —

## Contexto

O controle web ([0003](0003-controle-remoto-web-via-wifi.md), [0020](0020-controle-sem-token.md)) só responde com o CineKit aberto. Numa TV box, quem está no sofá quer ligar o CineKit pelo celular, sem ir até o Mac, e desligá-lo quando terminar, como num controle de TV. Rodar sempre em segundo plano precisa ser uma escolha do usuário.

## Decisão

- **Abrir ao iniciar o Mac.** Configurações → Controle remoto ganha a linha "Abrir ao iniciar o Mac" (`Desligado`/`Ligado`), desligada por padrão. Ligado registra o app com `SMAppService.mainApp`; desligado cancela o registro. Se o registro falhar, a seção mostra o erro e a linha continua em `Desligado`. O usuário também pode revogar em Ajustes do Sistema → Geral → Itens de Início.
- **Escondido no login.** Aberto pelo login (`keyAELaunchedAsLogInItem` no Apple Event de abertura), o app não se ativa nem entra em tela cheia: chama `NSApp.hide(nil)`. O servidor do controle, o Android ([0018](0018-sdk-android-instalado-pelo-app.md)) e o modo de entrada sobem como numa abertura normal.
- **Botão de ligar.** O protocolo v1 ganha o botão `power` em `POST /api/press`. Ele não vira teclas: o `RemoteServer` trata à parte, como o volume.
  - Com a janela do CineKit visível na tela, ativo ou não, desliga: posta as teclas do botão Home (o que sai do serviço e pausa a mídia, [0014](0014-servicos-vivos-em-segundo-plano.md)) e, no ciclo seguinte do run loop, esconde o app.
  - Senão, liga, com qualquer app na frente: mostra o app e o reabre pelo Launch Services (`NSWorkspace.openApplication`), que o ativa como um clique no Dock. Desde o macOS 14 a ativação é cooperativa e o `NSApp.activate()` vindo de segundo plano é recusado. Depois tenta pôr a janela em tela cheia por até ~3 s, porque o pedido é ignorado enquanto a janela ainda volta para a tela. Para o reopen não criar uma segunda janela, o `AppDelegate` só deixa o SwiftUI criar uma quando não há nenhuma.
- **Ícone fixo no controle.** O botão fica na 1ª posição da linha de cima do controle web, com ícone de power, sem mostrar se o CineKit está ligado.

## Alternativas consideradas

- **Sempre rodar em segundo plano** — sem o consentimento pedido; o toggle é revogável.
- **Rota nova (`/api/power`)** — o `/api/press` já transporta botões; um caso a mais no `RemoteServer` basta.
- **Mostrar o estado ligado/desligado no controle (`/api/state`)** — mais código para pouco ganho; o ícone fixo segue o padrão do botão de tema.
- **Só ligar, sem desligar** — o controle de TV alterna; desligar reaproveita a pausa ao sair do serviço.

## Consequências

- O botão de ligar só funciona com o Mac acordado, desbloqueado e o CineKit rodando (aberto ou escondido). Acordar o Mac pela rede fica fora.
- Com o toggle ligado, o CineKit fica na memória o tempo todo, junto com o emulador Android se ele estiver ligado.
- Se a janela for fechada (⌘W ou botão vermelho), o power não a recria; é preciso reabrir pelo Dock.
- O `SMAppService.mainApp` depende do `.app` assinado em `/Applications`; rodando do `.build`, o registro pode falhar e o erro aparece nas Configurações.
