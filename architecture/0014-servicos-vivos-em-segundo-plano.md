# 0014. Serviços vivos em segundo plano

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** —
- **Substituído por:** —

## Contexto

Sair de um serviço web (Esc segurado, Voltar sem histórico, ⌘[) destrói o `WKWebView`: a mídia para, mas a volta recomeça do zero, na página inicial do serviço. O usuário quer que sair pause a mídia sem fechar, para que reabrir o serviço volte ao mesmo ponto.

Os apps Android já ficam vivos no emulador: `am start -n` traz a task existente para a frente e sair só aperta Home. Mas nem todo app pausa sozinho ao perder o foco.

## Decisão

- **Até 3 serviços web vivos**, numa lista LRU (`RecentWebApps` no `CineKitCore`, `WebViewCache` no target `CineKit`, injetado por `.environment`). Abrir um quarto serviço descarta o usado há mais tempo. Os apps Android não contam no limite.
- **Ao sair, a mídia é pausada** com `WKWebView.pauseAllMediaPlayback`, no `dismantleNSView`, caminho comum a toda saída.
- **Tela cheia HTML:** sai da tela cheia (`document.exitFullscreen()`) antes de sair do serviço. A volta não restaura a tela cheia.
- **Ao voltar, a página continua pausada**; o usuário retoma com Pause/Espaço.
- **Descarte:** a webview é descartada quando o app é removido, quando a URL muda (inclui "Restaurar padrões") ou quando a carga falha.
- **Android:** sair manda `KEYCODE_MEDIA_PAUSE` (127) antes do Home.
- O cache é só em memória: fechar o cine-kit descarta tudo.

## Alternativas consideradas

- **Só o último serviço vivo** — trocar entre dois serviços perderia o ponto de um deles.
- **Todos os serviços vivos** — cada página ocupa centenas de MB; sem limite, a memória cresce com o catálogo.
- **`setAllMediaPlaybackSuspended`** — suspende em vez de pausar; a página continua "tocando" do ponto de vista do player.
- **JS `pause()` nos elementos de mídia** — depende do DOM e não alcança iframes de outra origem.

## Consequências

- Memória de até ~3 páginas web abertas em segundo plano.
- As sessões dos serviços ficam abertas em segundo plano enquanto o cine-kit roda.
- A tela cheia HTML não é restaurada na volta.
- Os callbacks da webview (`onExit`, `navigationDelegate`) são reatribuídos a cada abertura, porque o representable e o coordinator são novos.
