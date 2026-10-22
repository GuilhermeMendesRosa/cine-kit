# Referência de APIs — Liquid Glass (SwiftUI, macOS 26+)

Conferido em 2026-10-21 contra a documentação da Apple ("Adopting Liquid Glass" e "Applying Liquid Glass to custom views"). Se a Apple mudar algo, atualize aqui.

## `glassEffect(_:in:)`

Aplica Liquid Glass atrás do conteúdo da view. Padrão: variante `.regular` em forma de `Capsule`.

```swift
Text("Início")
    .font(.title)
    .padding()
    .glassEffect()                                  // regular, capsule

Text("Início")
    .padding()
    .glassEffect(in: .rect(cornerRadius: 16.0))     // outra forma

Text("Assistir")
    .padding()
    .glassEffect(.regular.tint(.orange).interactive())  // tint + reage a toque e ponteiro
```

- `Glass.regular` — variante padrão.
- `.tint(_:)` — sugere proeminência. Use com parcimônia.
- `.interactive(_:)` — o componente customizado reage a toque **e ponteiro**, como os botões `.glass`.
- Aplique **depois** dos modificadores de aparência.

## `GlassEffectContainer(spacing:)`

Agrupa vários elementos de vidro: melhor desempenho, formas que se fundem e morph entre elementos.

```swift
GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "play.fill")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()

        Image(systemName: "info.circle")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()
    }
}
```

Quanto maior o `spacing`, mais cedo os vidros se fundem numa transição. `spacing` do container maior que o do stack interno = vidros fundidos em repouso.

## `glassEffectUnion(id:namespace:)`

Faz várias views contribuírem para **um único** formato de vidro, mesmo em repouso. Útil para views criadas dinamicamente ou fora de um mesmo stack.

```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 20.0) {
    HStack(spacing: 20.0) {
        ForEach(symbols.indices, id: \.self) { index in
            Image(systemName: symbols[index])
                .frame(width: 80.0, height: 80.0)
                .glassEffect()
                .glassEffectUnion(id: index < 2 ? "playback" : "settings", namespace: namespace)
        }
    }
}
```

## `glassEffectID(_:in:)` e `glassEffectTransition(_:)`

Morph entre elementos quando entram/saem da hierarquia.

```swift
@State private var isExpanded = false
@Namespace private var namespace

var body: some View {
    GlassEffectContainer(spacing: 40.0) {
        HStack(spacing: 40.0) {
            Image(systemName: "play.fill")
                .frame(width: 80.0, height: 80.0)
                .glassEffect()
                .glassEffectID("play", in: namespace)

            if isExpanded {
                Image(systemName: "captions.bubble")
                    .frame(width: 80.0, height: 80.0)
                    .glassEffect()
                    .glassEffectID("captions", in: namespace)
            }
        }
    }

    Button("Mais opções") {
        withAnimation { isExpanded.toggle() }
    }
    .buttonStyle(.glass)
}
```

`GlassEffectTransition`:
- `.matchedGeometry` — padrão para elementos dentro do `spacing` do container.
- `.materialize` — para elementos mais distantes que o `spacing`, ou transição mais simples.

## Botões

```swift
Button("Configurações") { }
    .buttonStyle(.glass)            // ação comum

Button("Assistir") { }
    .buttonStyle(.glassProminent)   // ação primária

Button("Assistir") { }
    .buttonStyle(.glass(.regular.tint(.accentColor)))  // variante configurada
```

Prefira estes estilos a montar botões com `glassEffect` à mão.

## Layout, bordas e rolagem

- `backgroundExtensionEffect()` — espelha e desfoca o conteúdo adjacente sob sidebars/inspectors, dando sensação de imagem de ponta a ponta (hero).
- `scrollEdgeEffectStyle(_:for:)` — efeito de borda de rolagem que mantém legíveis os controles sobre conteúdo que rola.
- `safeAreaBar(edge:alignment:spacing:content:)` — registra uma barra customizada para receber o efeito de borda de rolagem.
- `ConcentricRectangle` e `.rect(corners:isUniform:)` — cantos concêntricos ao container.
- `ToolbarSpacer` / `SpacerSizing.fixed` — separar grupos de itens de toolbar que compartilham fundo.
- `ToolbarContent.hidden(_:)` — esconder o item inteiro de toolbar.

## Foco (macOS)

- `.focusable(_:)`, `@FocusState`, `@Environment(\.isFocused)` — a Apple recomenda essas APIs no tvOS para aplicar o visual de foco a controles customizados; usamos as mesmas no macOS.
- `.focusEffectDisabled()` — desliga o anel de foco do sistema para desenharmos o estado focado.

## AppKit (quando o SwiftUI não alcançar)

- `NSGlassEffectView` — vidro numa view AppKit.
- `NSButton.BezelStyle.glass` — botão AppKit com vidro.
- `NSBackgroundExtensionView` — equivalente ao `backgroundExtensionEffect()`.

## Acessibilidade

Componentes padrão se adaptam sozinhos a Reduzir transparência, Aumentar contraste e Reduzir movimento. Para vidro customizado, teste os três. Para desligar vidro condicionalmente, use `glassEffect(_:in:)` com a variante adequada ao estado de `accessibilityReduceTransparency`.
