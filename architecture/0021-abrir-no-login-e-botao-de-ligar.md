# 0021. Abrir no login e botão de ligar no controle

- **Status:** Proposto
- **Data:** 2026-10-23
- **Substitui:** —
- **Substituído por:** —

## Contexto

O controle web ([0003](0003-controle-remoto-web-via-wifi.md), [0020](0020-controle-sem-token.md)) só responde com o CineKit aberto. Numa TV box, quem está no sofá quer ligar o CineKit pelo celular, sem ir até o Mac, e desligá-lo quando terminar, como num controle de TV. Rodar sempre em segundo plano precisa ser uma escolha do usuário.

## Decisão

- **Ligado é visível em tela cheia.** O CineKit está ligado quando não está escondido e a janela principal está em tela cheia, lido do AppKit na hora (`!NSApp.isHidden && styleMask.contains(.fullScreen)`), sem estado guardado. Qualquer tela cheia conta, inclusive pelo botão verde ou ⌃⌘F, e também em outro Space. ⌘H, sair da tela cheia, ⌘W e encerrar viram "desligado" sozinhos.
- **Abrir ao iniciar o Mac.** Configurações → Controle remoto ganha a linha "Abrir ao iniciar o Mac" (`Desligado`/`Ligado`), desligada por padrão. Ligado registra o app com `SMAppService.mainApp`; desligado cancela o registro. Se o registro falhar, a seção mostra o erro e a linha continua em `Desligado`. O usuário também pode revogar em Ajustes do Sistema → Geral → Itens de Início.
- **Escondido no login.** Aberto pelo login (`keyAELaunchedAsLogInItem` no Apple Event de abertura), o app não se ativa nem entra em tela cheia: chama `NSApp.hide(nil)`. O servidor do controle, o Android ([0018](0018-sdk-android-instalado-pelo-app.md)) e o modo de entrada sobem como numa abertura normal.
- **Aberto pelo Finder/Dock, abre em janela normal.** Ativa o app sem entrar em tela cheia, então começa desligado.
- **Botão de ligar.** O protocolo v1 ganha o botão `power` em `POST /api/press`. Ele não vira teclas: o `RemoteServer` trata à parte, como o volume.
  - Ligado, desliga: posta as teclas do botão Home (o que sai do serviço e pausa a mídia, [0014](0014-servicos-vivos-em-segundo-plano.md)) e, no ciclo seguinte do run loop, sai da tela cheia e só esconde o app depois do `didExitFullScreenNotification`, para não deixar um Space vazio. O ícone continua no Dock.
  - Desligado, liga, com qualquer app na frente: mostra o app e o reabre pelo Launch Services (`NSWorkspace.openApplication`), que o ativa como um clique no Dock. Desde o macOS 14 a ativação é cooperativa e o `NSApp.activate()` vindo de segundo plano é recusado. Depois tenta pôr a janela em tela cheia por até ~3 s, porque o pedido é ignorado enquanto a janela ainda volta para a tela. Se a janela foi fechada, o reopen cria outra e a tela cheia espera por ela. Para o reopen não criar uma segunda janela, o `AppDelegate` só deixa o SwiftUI criar uma quando não há nenhuma.
- **Estado no controle.** O botão fica na 1ª posição da linha de cima do controle web, com ícone de power. O `GET /api/state` ganha `power`, e o ícone fica aceso (`aria-pressed`) quando o CineKit está ligado. O toque troca o ícone na hora, de forma otimista, e o polling de 1,5 s corrige, como no botão de tema ([0019](0019-tema-escolhido-e-pareado-com-o-controle.md)).

## Alternativas consideradas

- **Sempre rodar em segundo plano** — sem o consentimento pedido; o toggle é revogável.
- **Rota nova (`/api/power`)** — o `/api/press` já transporta botões; um caso a mais no `RemoteServer` basta.
- **Deduzir "ligado" da oclusão da janela (`occlusionState`)** — instável: a janela coberta por outro app ou fora da tela cheia desligava quando devia ligar, e o app podia parar em janela não cheia.
- **Sumir do Dock e do ⌘Tab quando desligado (`.accessory`)** — trocar a política de ativação em tempo de execução é frágil; esconder basta.
- **Só ligar, sem desligar** — o controle de TV alterna; desligar reaproveita a pausa ao sair do serviço.

## Consequências

- O botão de ligar só funciona com o Mac acordado, desbloqueado e o CineKit rodando (aberto ou escondido). Acordar o Mac pela rede fica fora.
- Com o toggle ligado, o CineKit fica na memória o tempo todo, junto com o emulador Android se ele estiver ligado.
- Com o CineKit em tela cheia em outro Space, ele conta como ligado: o power desliga em vez de trazê-lo para a frente.
- O `SMAppService.mainApp` depende do `.app` assinado em `/Applications`; rodando do `.build`, o registro pode falhar e o erro aparece nas Configurações.
