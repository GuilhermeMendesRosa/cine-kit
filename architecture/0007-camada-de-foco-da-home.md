# 0007. Camada de foco da home

- **Status:** Aceito
- **Data:** 2026-10-21
- **Substitui:** —
- **Substituído por:** —

## Contexto

O [0002](0002-app-nativo-swift-com-webkit.md) prevê que o foco do SwiftUI no macOS não basta para a navegação estilo TV: as setas não movem o foco entre views customizadas de forma confiável, e o anel de foco do Mac não serve para TV ([0005](0005-ui-nativa-com-liquid-glass.md)). A home tem uma prateleira horizontal de cards e um botão de configuração acima dela.

## Decisão

- A home usa uma **camada mínima própria**: o alvo focado é um valor (`ShelfFocusTarget`: `.settings` ou `.card(índice)`) e a transição por seta é uma função pura `ShelfFocus.move(_:direction:itemCount:)` em `CineKitCore`.
- Regras: ←/→ andam pelos cards sem dar a volta; ↑ de um card vai para a configuração lembrando o card; ↓ da configuração volta ao último card.
- A view sincroniza esse estado com `@FocusState`, recebe as setas via `.onMoveCommand`, desliga o anel do sistema com `.focusEffectDisabled()` e desenha o foco (card: escala, sombra e borda).
- Telas montadas com componente nativo que já navega por setas (ex.: `List` com seleção) usam o **foco nativo**, sem esta camada.

## Alternativas consideradas

- **Só o foco nativo do SwiftUI** — setas não navegam de forma confiável entre views customizadas no macOS.
- **Framework de foco genérico (grade, regiões, histórico)** — mais do que a home precisa hoje.

## Consequências

- A lógica de navegação é testável sem UI.
- Novas telas customizadas precisam estender esta camada (ou um novo ADR para generalizá-la); não criar camada paralela.
