---
name: liquid-glass
description: Regras e referência para construir a UI do cine-kit com Liquid Glass (SwiftUI, macOS 26+) numa interface de sala ("10-foot UI") com foco no estilo tvOS 26. Use sempre que criar, alterar ou revisar views SwiftUI, componentes, navegação, estados de foco, toolbars, sheets ou qualquer uso de glassEffect, GlassEffectContainer, glassEffectID, glassEffectUnion, buttonStyle(.glass) ou backgroundExtensionEffect.
---

# Liquid Glass no cine-kit

Decisão de origem: [ADR 0005](../../../architecture/0005-ui-nativa-com-liquid-glass.md). Alvo: **macOS 26+**, SwiftUI, Mac mini ligado a um monitor/TV 4K, usado à distância com controle remoto.

**Fonte de verdade é a Apple.** Se algo aqui divergir da documentação oficial, vale a Apple — e corrija este arquivo. Na dúvida sobre uma API, consulte (os `.md` abaixo são legíveis por agentes):

- Adopting Liquid Glass — https://developer.apple.com/tutorials/data/documentation/technologyoverviews/adopting-liquid-glass.md
- Applying Liquid Glass to custom views — https://developer.apple.com/tutorials/data/documentation/swiftui/applying-liquid-glass-to-custom-views.md
- Sample Landmarks — https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass
- Human Interface Guidelines (materiais, tvOS, foco) — https://developer.apple.com/design/human-interface-guidelines/

Referência de APIs verificadas: [references/api.md](references/api.md).

## Princípios

1. **Componente padrão primeiro.** `Button`, `Toggle`, `Slider`, `Picker`, `TextField`, `.toolbar`, `.sheet`, `Menu`, `NavigationStack`, `NavigationSplitView` já ganham Liquid Glass. Só crie vidro customizado quando não houver componente padrão.
2. **Vidro é a camada de navegação e controles, nunca o conteúdo.** Pôsteres, capas, thumbnails, texto, listas de títulos e o vídeo são conteúdo — sem `glassEffect`. Vidro vai em barra superior, botões, controles de player, overlays flutuantes.
3. **Use pouco.** Poucos elementos de vidro na tela ao mesmo tempo; reserve para os elementos funcionais mais importantes.
4. **Nunca vidro sobre vidro.** Vidro não amostra outro vidro. Elementos de vidro próximos ficam no mesmo `GlassEffectContainer`.
5. **Sem fundos customizados em navegação/controles.** Não use `.toolbarBackground`, `.presentationBackground`, `.background(.ultraThinMaterial)` ou `NSVisualEffectView` em barras, sheets, popovers e controles — o sistema cuida.
6. **Cor com parcimônia.** Em controles, use cores do sistema ou cores com variantes claro/escuro e de alto contraste. `tint` no vidro só para indicar proeminência (ação primária).
7. **Cantos concêntricos.** Formas aninhadas usam `ConcentricRectangle` ou `.rect(corners:isUniform:)` para acompanhar o container.

## Regras de sala (10-foot UI)

Convenções do projeto, inspiradas no tvOS 26. Não são API — ajuste aqui se a prática mostrar outra coisa.

- **Tudo navegável por direção.** Toda tela funciona só com setas, OK (Enter/Espaço), Voltar (Esc) e Home. Mouse é secundário.
- **Foco sempre visível e inequívoco.** Exatamente um item focado por vez, evidente a 3 metros.
- **Texto grande.** Use estilos de texto (`.title`, `.largeTitle`, `.headline`) em vez de tamanhos fixos pequenos; nada de `.caption`/`.footnote` para informação que precisa ser lida do sofá.
- **Margens de segurança.** Mantenha conteúdo e controles longe das bordas (referência: margens laterais e verticais generosas, como no tvOS). Fundo e imagens hero podem ir até a borda.
- **Alvos grandes e espaçados.** Cards e botões com área e espaçamento amplos; nada de controles densos de app de Mac.
- **Menus seguem o tema; mídia escura.** Home e Configurações seguem o tema escolhido (Automático/Claro/Escuro, ADR 0013); telas de mídia/player ficam escuras, com imagens de conteúdo dando a cor.

## Foco no estilo tvOS

No tvOS, controles padrão ganham Liquid Glass ao receber foco. No macOS não há isso pronto: o anel de foco azul do Mac não serve para TV. Padrão do projeto:

- Itens navegáveis usam `.focusable()` e `@FocusState`; desligue o anel do sistema com `.focusEffectDisabled()` e desenhe o estado focado.
- **Card de conteúdo focado:** escala leve, sombra e destaque de borda — **sem** vidro no card (é conteúdo).
- **Botão/controle focado:** pode ganhar vidro ou trocar `.glass` → `.glassProminent`; o elemento continua dentro do `GlassEffectContainer` do grupo.
- Agrupe regiões de navegação (prateleiras, barra superior) para as setas se comportarem como no tvOS; a camada de foco do projeto é decisão em aberto (ver ADR 0002) — não invente uma paralela, use/estenda a que existir.
- Respeite `accessibilityReduceMotion`: sem escala/bounce quando ativo.

## Armadilhas conhecidas

- **Ordem dos modificadores:** `glassEffect` vem **depois** dos modificadores que afetam a aparência (`padding`, `font`, `frame`). Ele captura o conteúdo para o container renderizar.
- **Morph não anima:** os elementos precisam estar no mesmo `GlassEffectContainer`, com `glassEffectID` no mesmo `@Namespace`, mudança de estado em `withAnimation`, e a view precisa **entrar/sair da hierarquia** (`if`), não só mudar `opacity`.
- **Spacing do container maior que o do `HStack`/`VStack` interno** faz os vidros se fundirem em repouso. Use isso de propósito ou iguale os valores.
- **Desempenho:** muitos efeitos fora de container ou muitos containers degradam a renderização. Não aplique vidro em cada item de uma lista/grade rolável.
- **Área clicável:** se só o símbolo/texto responder ao clique, defina `.contentShape(...)` com a mesma forma do vidro.
- **Toolbar vazia:** esconda o item inteiro (`ToolbarContent.hidden(_:)`), não a view dentro dele.

## Checklist de revisão de UI

- [ ] Usei componente padrão onde existia um?
- [ ] Nenhum `glassEffect` em conteúdo (cards, pôsteres, texto, vídeo)?
- [ ] Vidros próximos estão no mesmo `GlassEffectContainer`? Nenhum vidro sobre vidro?
- [ ] Nenhum fundo/material customizado em barras, sheets, popovers ou controles?
- [ ] A tela inteira funciona só com setas, OK, Voltar e Home? O foco é óbvio de longe?
- [ ] Texto legível do sofá? Margens de segurança respeitadas?
- [ ] Testado com Reduzir transparência, Aumentar contraste e Reduzir movimento?
- [ ] Cores de controle têm variante escura e de alto contraste?

---

Créditos: parte das armadilhas foi adaptada de [haider-nawaz/liquid-glass-skill](https://github.com/haider-nawaz/liquid-glass-skill) (MIT), conferida contra a documentação da Apple.
