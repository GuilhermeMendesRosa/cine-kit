# 0022. Núcleos e memória do emulador configuráveis

- **Status:** Proposto
- **Data:** 2026-10-25
- **Substitui:** no [0004](0004-apps-android-via-emulador.md), o `hw.ramSize=2048` fixo das consequências
- **Substituído por:** —

## Contexto

O AVD `cinekit-tv` ([0018](0018-sdk-android-instalado-pelo-app.md)) é escrito com 4 núcleos e 2 GB de RAM fixos. Num Mac com folga, isso deixa apps Android pesados mais lentos do que precisam; num Mac menor, o usuário pode querer gastar menos. Quem liga o Android nas Configurações deve poder escolher quantos núcleos e quanta memória o emulador usa, sem apagar o AVD nem reinstalar o SDK.

## Decisão

- **Flags no lançamento.** O `AndroidRuntime` passa `-cores N -memory MB` em todo lançamento do emulador, como já faz com o `-skin` da resolução. As flags passam por cima de `hw.cpu.ncore` e `hw.ramSize` do `config.ini`, que continua sendo escrito com 4 núcleos e 2048 MB como base.
- **Onde aparece.** Com o Android ligado e o SDK instalado, a seção Android das Configurações ganha as linhas "Núcleos" e "Memória", logo abaixo de "Resolução". Durante a instalação e com o Android desligado, elas não aparecem.
- **Opções.** Núcleos `2 · 4 · 6 · 8`, só os que não passam de `activeProcessorCount`. Memória `2 · 4 · 8 GB`, só as que não passam da metade de `physicalMemory`, para o emulador não travar o Mac.
- **Padrão e valor inválido.** 4 núcleos e 2048 MB, os mesmos do AVD. Um valor salvo que não está entre as opções do Mac atual (outro Mac, edição à mão) volta para o padrão.
- **Efeito da troca.** Trocar reinicia a VM na hora (`restart`), com falha silenciosa, como a resolução.
- **Persistência.** `UserDefaults`, nas chaves `androidCores` e `androidMemory` (em MB), ao lado de `androidResolution`.

## Alternativas consideradas

- **Reescrever o `config.ini` do AVD** — exige migrar instalações que já existem e mexer num arquivo que o instalador é dono; as flags valem para todas sem migração.
- **Sheet de configuração ao ligar o Android** — mais um passo no caminho de quem só quer ligar; as linhas na seção seguem o layout e o foco de hoje.
- **Aplicar só no próximo início** — o usuário não vê o efeito da escolha; a resolução já reinicia na hora.

## Consequências

- Trocar núcleos ou memória invalida o snapshot do quickboot, então o boot seguinte é a frio e mais lento.
- Macs menores veem menos opções; num Mac com 8 GB, só 2 e 4 GB.
- O emulador pode usar até metade da RAM do Mac enquanto o cine-kit está aberto.
