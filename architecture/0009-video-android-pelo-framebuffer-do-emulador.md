# 0009. Vídeo dos apps Android pelo framebuffer do emulador

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** a parte de vídeo do [0004](0004-apps-android-via-emulador.md)
- **Substituído por:** —

## Contexto

O [0004](0004-apps-android-via-emulador.md) definiu o vídeo dos apps Android pelo scrcpy-server (H.264 capturado dentro do Android). No primeiro app real (UniTV, IPTV), a tela ficou preta e só os toasts apareciam: a janela do app usa `FLAG_SECURE`, e o Android pinta de preto qualquer captura feita de dentro dele. A imagem `android-tv` é build `user`, sem root, então o scrcpy não consegue criar um display seguro (desde o Android 12 isso exige permissão de sistema). Apps de IPTV e vídeo costumam usar `FLAG_SECURE`, então o problema não é pontual.

O framebuffer que o emulador desenha no Mac não passa por essa regra. Num spike em 2026-10-22, com o UniTV aberto e `FLAG_SECURE` ativo:

- `screencap` dentro do Android: tela preta.
- Emulador iniciado com `-share-vid`: ele publica o framebuffer na memória compartilhada POSIX `videmulator<porta>` (`videmulator5554`). Lida com `shm_open` + `mmap`, a tela do app aparece completa.
- Layout: cabeçalho de 24 bytes little-endian (`width`, `height`, `fps`, `frameNumber` como `UInt32`, `timestampUs` como `UInt64`), seguido de `width × height` pixels RGBA8888. O `frameNumber` só avança quando a tela muda (26–48 quadros/s navegando no app, 0 com a tela parada).

## Decisão

- O emulador sobe com `-share-vid`, além das flags do 0004.
- O vídeo vem da memória compartilhada `videmulator5554`: a cada vsync, se o `frameNumber` mudou, o cine-kit copia o frame para uma imagem e mostra numa layer em tela cheia (`resizeAspect`, fundo preto). Sem decodificação e sem dependências externas ([0006](0006-estrutura-swift-package.md)).
- O parser do cabeçalho fica no `CineKitCore` (testável); o `mmap` e a exibição ficam na UI.
- O scrcpy-server continua, **só para controle** (`video=false`): teclas e texto pelo socket de controle, como no 0004.
- Sai do código: `ScrcpyVideoView`/`H264Renderer` e a parte de vídeo do `ScrcpyClient`.
- O resto do 0004 continua valendo (runtime, ciclo de vida, "Abrindo…" até o app estar em primeiro plano, teclas, Esc, resolução).

## Alternativas consideradas

- **Continuar com o scrcpy e aceitar a limitação** — apps com `FLAG_SECURE` ficam pretos, justamente os de vídeo.
- **Imagem com root (`google_apis`, build `userdebug`)** — não existe imagem Android TV arm64 com root. Mesmo com root, o scrcpy só pede display seguro até o Android 11.
- **gRPC do emulador (`streamScreenshot`)** — também vê o framebuffer, mas exige HTTP/2 + protobuf (`grpc-swift`), contra o 0006.
- **Capturar uma janela visível do emulador com ScreenCaptureKit** — exige a permissão de Gravação de Tela e uma janela do Android na tela, contra o "não ver o Android".

## Consequências

- Apps com `FLAG_SECURE` aparecem. O 4K passa a chegar em 4K: o fallback do encoder do scrcpy para 1080p deixa de existir, porque não há mais encode.
- Menos CPU no Android: sem encode H.264 por software dentro da VM. Em troca, o Mac copia o frame inteiro a cada mudança (cerca de 8 MB em 1080p e 33 MB em 4K).
- O `-share-vid` e o layout da memória são internos do emulador (`VideoFrameSharer`) e podem mudar entre versões. O cine-kit confere se `width × height × 4` cabe no tamanho da região antes de ler, e mostra a tela de falha se não couber. Atualizar o emulador exige conferir o layout.
- Pode haver tearing raro (leitura durante a escrita do emulador). Mitigação: reler o `frameNumber` depois da cópia e descartar o frame se ele mudou.
