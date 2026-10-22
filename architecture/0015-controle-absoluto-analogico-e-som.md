# 0015. Touchpad mais rápido, faixa de rolagem analógica e som de clique por app

- **Status:** Proposto
- **Data:** 2026-10-22
- **Substitui:** no [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md), no "Touchpad no celular", o ganho do touchpad e a faixa com ganho 2×, o "Segurar Voltar (600 ms)" e o "Layout do controle"; no [0013](0013-tema-e-configuracoes-navegaveis.md), o fundo em gradiente do controle
- **Substituído por:** —

## Contexto

Com o controle do [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md) em uso, apareceram quatro incômodos. O fundo em gradiente colorido do [0013](0013-tema-e-configuracoes-navegaveis.md) chama mais atenção que os botões. Ir para a home exige segurar Voltar, o que ninguém descobre sozinho. O touchpad relativo é lento demais e obriga a "remar" o cursor pela TV inteira, e a faixa de rolagem exige arrastar várias vezes para descer uma página longa. Por fim, no iPhone o tique háptico do 0012 é fraco: falta um retorno sonoro, mas alguns apps (Netflix, por exemplo) já fazem som próprio, e o tique por cima incomoda.

## Decisão

- **Fundo do controle monocromático.** Radiais brancos (claro: `rgb(255 255 255 / 0.7)`; escuro: `/ 0.06` e `/ 0.04`) sobre um linear cinza neutro (claro `#f5f5f7 → #e5e5e7`; escuro `#121212 → #050505`). Os radiais continuam porque o `backdrop-filter` precisa de variação atrás para o vidro aparecer. O resto do vidro do 0013 não muda.
- **Layout do controle**, de cima para baixo: status; linha 1 com a cápsula `− | +` (volume) à esquerda e `⌂ Início` à direita; linha 2 com `Voltar · Clique · Pause`; D-pad; touchpad. Alvos de pelo menos 64 px.
- **Início e Voltar.** Início é um botão próprio que envia `home`, que já existe no protocolo. Voltar é toque simples: sai o "segurar Voltar (600 ms)" e a dica. Nenhum dos dois repete ao segurar.
- **Touchpad relativo com o dobro do ganho.** O touchpad continua o do 0012 (um dedo move, dois dedos rolam, toque ≤ 250 ms e ≤ 10 px clica), mas o ganho passa a `3 + 4 · v` (v em px/ms), com teto 8× (antes `1,5 + 2 · v`, teto 4×). A área ocupa o espaço que sobra embaixo do D-pad, sem proporção fixa, com a faixa de rolagem de 56 px à direita, no mesmo vidro. A fila serial do 0012 não muda: soma movimento e rolagem e manda o clique depois.
- **Faixa de rolagem como analógico.** O centro da faixa é o ponto morto; a pill segue o dedo, limitada à faixa, e volta ao centro com transição ao soltar (sem transição com `prefers-reduced-motion`). A velocidade é `v = 2000 · t^1,6` px/s, com zona morta de ±10% da meia-altura e `t` de 0 a 1 depois dela. Dedo abaixo do centro = a página desce. Só vertical; os deltas saem a cada `requestAnimationFrame` e se somam na fila.
- **Som de clique.** Sintetizado com Web Audio no celular: oscilador `triangle` de ~1,8 kHz com envelope de ~30 ms; o `AudioContext` é criado (ou retomado) no primeiro toque. Toca nos mesmos pontos da vibração do 0012 (cada botão, só no primeiro disparo ao segurar, e no toque-clique do touchpad), nunca em movimento ou rolagem. Respeita a chave de silencioso do celular.
- **Som por app.** O `StreamingApp` ganha `remoteClickSound: Bool` (ausente no JSON = `true`), com o `Toggle` "Som de clique no controle" no formulário do app (web e Android), ligado por padrão. O `RemoteServer` guarda `clickSound` (padrão `true`), atualizado a partir do app aberto; na home e nas Configurações, sempre com som.
- **Estado para o celular.** `GET /api/state` (com o mesmo `Authorization` das outras rotas) → `200 {"clickSound":bool}`; sem token ou com token errado → 401. O celular consulta a cada 1,5 s, só com a aba visível, e no `visibilitychange`. Offline mantém o último valor (inicial `true`) e não mexe no aviso "Mac não encontrado"; 401 expira o pareamento, como nas outras rotas.
- As constantes (ganho do touchpad, 2000 px/s, expoente 1,6, zona morta de 10%, envelope de 30 ms, frequência do tique, intervalo de 1,5 s) são pontos de partida, ajustados no teste manual.

## Alternativas consideradas

- **Só um linear neutro no fundo** — sem variação atrás, o vidro some.
- **Botões numa linha só** — não cabe a 375 px com alvos de 64 px; e Início colado no Voltar convida ao toque errado.
- **Touchpad absoluto 1:1 numa área 16:9** (o ponto tocado é o ponto da tela, via `moveTo`) — implementado e rejeitado no teste: impreciso, desconfortável, e a área em 16:9 ficou pequena.
- **Origem do analógico no ponto do toque** — o pedido foi o centro da faixa como ponto morto.
- **Estado do som num header das respostas** — chegaria um toque atrasado: o primeiro toque depois de abrir o app ainda sairia com o valor antigo.
- **Som em arquivo `.wav`** — um asset a mais para servir, sem ganho sobre o oscilador.
- **Editar o 0012/0013** — ADR aceito é imutável.

## Consequências

- O cursor cruza a TV com menos gestos, ao custo de um pouco de precisão fina em movimentos lentos.
- O celular faz uma requisição a cada 1,5 s enquanto a aba está visível; na LAN, o custo é desprezível.
- Se o som de um app não for desligado no formulário, os dois sons tocam juntos.
- `startLongPress` fica sem uso no celular e sai.
- As constantes do analógico e do som precisam de teste manual e podem mudar sem novo ADR.
