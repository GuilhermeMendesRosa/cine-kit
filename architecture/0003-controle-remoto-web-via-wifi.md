# 0003. Controle remoto web via Wi-Fi

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** —
- **Substituído por:** [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md) (tabela de teclas, botão Home, touchpad)

## Contexto

O cine-kit precisa ser usado do sofá, sem mouse. O controle principal é um app web aberto no navegador do celular, na mesma rede Wi-Fi do Mac, que pode ser salvo na tela inicial do iPhone. Mouse e teclado ligados ao Mac continuam funcionando.

A ideia inicial era hospedar o app web na Vercel. O Safari do iOS bloqueia requisições `http://` e `ws://` para um IP da rede local a partir de uma página HTTPS (mixed content), e o Mac não tem certificado válido na LAN. Por isso o próprio Mac serve o app web.

## Decisão

- **Servidor no app.** O app do Mac embute um servidor HTTP/1.1 mínimo (`NWListener`, Network.framework, sem dependências) na **porta fixa 8686**. Ele serve o build do app web (`Contents/Resources/remote/`) e a API. Sobe em `applicationDidFinishLaunching` e fica sempre ligado; se falhar (porta ocupada etc.), as Configurações mostram "Controle indisponível: <motivo>", sem retry.
- **Pareamento por QR.** As Configurações mostram um QR code com `http://<LocalHostName>.local:8686/?token=<token>`. O nome Bonjour não muda com o DHCP, então o atalho e o `localStorage` (que é por origem) continuam valendo. O token é aleatório (32 bytes), fica no `UserDefaults` (`remoteToken`) e **continua na URL**: no iOS o app da tela inicial tem `localStorage` separado do Safari, e o atalho precisa nascer pareado. O celular também guarda o token no `localStorage`. "Gerar novo código" troca o token e invalida todos os celulares pareados. Sem confirmação na TV; vários celulares podem parear.
- **Protocolo v1.** `POST /api/press` com corpo `{"button":"<botão>"}` e `Authorization: Bearer <token>`. Botões: `up`, `down`, `left`, `right`, `ok`, `back`, `home`, `playPause`, `volumeUp`, `volumeDown`, `mute`. Respostas: `204` aceito; `400` botão desconhecido; `401` sem token ou token errado; `404` path inexistente. O token é comparado em tempo constante.
- **Teclas sintéticas.** Cada botão vira eventos de teclado postados no próprio app (`NSEvent.keyEvent` + `NSApp.postEvent`), que seguem os mesmos caminhos do teclado físico. Não exige permissão de Acessibilidade.

  | Botão | Home / Configurações | Serviço web (YouTube incluso) | App Android |
  | --- | --- | --- | --- |
  | Setas, OK, Play/Pause | ←→↑↓, Return, Espaço | idem | idem |
  | Voltar | Esc | ⌘[ (`goBack()`; sem histórico, volta à home do cine-kit) | Esc (BACK) |
  | Home | Esc segurado | Esc segurado | Esc segurado (home do cine-kit) |

- **Segurar botão.** A repetição é feita no celular: um `press` imediato, outro após 400 ms e depois a cada 120 ms, só para setas e Vol±.
- **Volume.** Vol+, Vol− e Mudo agem no dispositivo de saída padrão do Mac via CoreAudio (`VirtualMainVolume`, `Mute`), em passos de 1/16, sem HUD. O áudio do emulador Android também sai pelo Mac.
- A stack do app web fica no [0011](0011-app-web-do-controle-em-react.md).

## Alternativas consideradas

- **App web na Vercel, falando direto com o Mac pelo Wi-Fi** — bloqueado pelo mixed content do Safari do iOS.
- **Vercel + relay na nuvem** — funciona, mas tira o controle da rede local e cria um serviço para manter.
- **WebSocket** — menos latência, mas mais código e uma segunda porta/protocolo; a latência de HTTP na LAN basta.
- **Roteamento por tela** (cada tela recebe comandos próprios) — mais código; as teclas sintéticas reaproveitam os caminhos de teclado que já existem.
- **Volume por `osascript`** — um processo por toque e possível pedido de permissão.
- **Siri Remote / gamepad via `GameController`** — não exige rede, mas não digita texto e não emula mouse. Pode ser somado depois.
- **App nativo de iOS como controle** — mais trabalho de desenvolvimento e distribuição.

## Consequências

- O macOS pede a permissão de Rede Local (`NSLocalNetworkUsageDescription` no `Info.plist`) e o firewall pode perguntar sobre conexões de entrada.
- As teclas só chegam com o cine-kit em primeiro plano (precisa haver `keyWindow`). Normal numa TV box.
- Se o celular não resolver `.local` numa rede, o atalho não abre; mostrar o IP seria a alternativa futura.
- O protocolo é um contrato entre os dois apps; mudanças incompatíveis viram `v2`.
- Fora por enquanto: teclado de texto, touchpad/mouse, HUD de volume, status "conectado" ao vivo.
