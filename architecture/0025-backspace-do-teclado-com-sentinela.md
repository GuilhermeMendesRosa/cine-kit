# 0025. Backspace do teclado do controle com sentinela

- **Status:** Proposto
- **Data:** 2026-10-31
- **Substitui:** no [0016](0016-teclado-de-texto-no-controle.md), o envio de `delete` por `deleteContentBackward` e o input esvaziado a cada evento
- **Substituído por:** —

## Contexto

O input escondido do [0016](0016-teclado-de-texto-no-controle.md) fica sempre vazio, e o backspace do teclado do celular não apaga nada no Mac. Teclados de celular costumam não emitir evento de entrada quando não há o que apagar, então o `delete` não sai.

## Decisão

- O input guarda sempre um sentinela, o espaço de largura zero (`U+200B`).
- A cada `input` fora de composição, e no `compositionend`, o controle lê o valor do campo e o restaura para o sentinela:
  - se há texto além do sentinela, o texto vai para `POST /api/text`;
  - se o sentinela sumiu e não há texto, envia o botão `delete`.
- A decisão vem do valor do campo, não do `inputType`. O listener de `beforeinput` sai.

As demais decisões do 0016 continuam valendo.

## Alternativas consideradas

- **Detectar o backspace no `keydown`**: teclados virtuais podem mandar a tecla como `Unidentified`, sobretudo no Android.
- **Um botão de apagar no controle**: resolve, mas ocupa espaço no layout e ignora a tecla que a pessoa já procura no teclado.

## Consequências

- O backspace sempre tem o que apagar, então o navegador emite o evento.
- Cada evento de apagar vira um `delete`, mesmo quando o iOS apaga por palavra ao segurar a tecla.
- O texto que sai nunca leva o sentinela: ele é removido antes do envio.
- O `delete` continua fora da fila de texto e pode ultrapassar uma letra em voo.
