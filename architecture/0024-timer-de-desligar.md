# 0024. Timer de desligar pelo controle

- **Status:** Proposto
- **Data:** 2026-10-28
- **Substitui:** —
- **Substituído por:** —

## Contexto

Numa TV, o "sleep" desliga a tela sozinho depois de um tempo, para quem dorme vendo um filme. O CineKit já sabe desligar pelo botão de power do controle ([0021](0021-abrir-no-login-e-botao-de-ligar.md)): volta pra Home, o que pausa o serviço ([0014](0014-servicos-vivos-em-segundo-plano.md)), sai da tela cheia e esconde o app. Falta programar esse desligar para daqui a alguns minutos, e, para quem quiser, bloquear o Mac depois.

## Decisão

- **O timer mora no Mac.** O `RemoteServer` guarda um `SleepTimer` (CineKitCore, só memória) e uma `Task` que dispara no prazo. Fechar o app cancela o timer; nada é persistido.
- **Opções de TV.** 15, 30, 45, 60, 90 ou 120 minutos, mais "Desativar" (`0`). Escolher outro valor substitui o timer atual.
- **Contrato.** `POST /api/sleep {"minutes": N}` aceita `0` ou uma das opções (senão 400), como o `/api/theme` ([0019](0019-tema-escolhido-e-pareado-com-o-controle.md)). O `GET /api/state` ganha `sleep`: segundos restantes, ou `null` sem timer. Segundos restantes não dependem do relógio do celular.
- **Ao fim do timer.** Faz o mesmo que o power ao desligar. Se o app já estiver desligado (⌘H etc.), não desliga de novo.
- **Power manual cancela.** Desligar pelo power apaga o timer. No controle, o botão do timer fica desabilitado com o app desligado.
- **Bloquear o Mac ao fim do timer.** Configurações → Controle remoto ganha a linha "Bloquear o Mac ao fim do timer" (`Desligado`/`Ligado`, padrão `Desligado`). Ligada, depois que o app some (espera `NSApp.isHidden` por até 3 s), o Mac bloqueia a tela com `SACLockScreenImmediate`, carregada por `dlopen` do `login.framework` privado. Se falhar, só registra o erro no log: o app já desligou e não há UI para mostrar. Vale só para o timer, não para o power manual.
- **UI só no controle.** Um botão de lua na linha de ações do controle web, com um `<select>` nativo invisível por cima. Com o timer ativo, fica aceso (`aria-pressed`) e mostra os minutos restantes, atualizados pelo polling do state.

## Alternativas consideradas

- **Timer no navegador do celular** — o Safari congela o JS quando o celular trava a tela, e o timer não dispararia.
- **Escolha e contagem num overlay na TV** — mexe em foco e em overlay SwiftUI; o controle basta por enquanto.
- **`pmset displaysleepnow`** — só apaga a tela; o bloqueio depende de um ajuste do sistema.
- **Simular ⌃⌘Q** — precisa de permissão de Acessibilidade e de eventos sintéticos.

## Consequências

- O `SACLockScreenImmediate` é API privada e pode sumir numa versão do macOS; aí o bloqueio vira só um log de erro e o resto funciona.
- O timer não sobrevive a fechar o app.
- Como o power, o timer só funciona com o Mac acordado e o CineKit rodando.
