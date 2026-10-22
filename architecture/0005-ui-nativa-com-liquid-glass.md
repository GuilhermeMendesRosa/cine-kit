# 0005. UI nativa com Liquid Glass

- **Status:** Aceito
- **Data:** 2026-10-21
- **Substitui:** —
- **Substituído por:** —

## Contexto

A aparência do cine-kit precisa ser bem próxima à dos apps da Apple. Desde o macOS 26 (Tahoe), a linguagem visual da Apple é o **Liquid Glass**, com APIs próprias no SwiftUI. A UI já é em SwiftUI (ver [0002](0002-app-nativo-swift-com-webkit.md)).

O cine-kit é uma UI de sala ("10-foot UI"), mais parecida com a do tvOS do que com a de um app de Mac comum, que é pensado para o ponteiro do mouse.

## Decisão

- **Versão mínima: macOS 26.** É a primeira versão com as APIs de Liquid Glass. O hardware-alvo (Mac mini M4) roda essa versão.
- **Só componentes nativos do SwiftUI**, sem biblioteca de UI de terceiros. Componentes padrão (botões, toolbars, sheets, menus) já ganham Liquid Glass ao compilar com o SDK do macOS 26.
- Superfícies próprias usam as APIs oficiais: `.glassEffect()`, `GlassEffectContainer`, `.glassEffectID(_:in:)` para as transições de morph, e os estilos de botão `.glass` e `.glassProminent`.
- **Referência visual: tvOS 26** (home, prateleiras de cards, estado de foco) adaptado ao macOS, seguindo as Human Interface Guidelines.
- Os padrões de uso (quando usar vidro, hierarquia, legibilidade a distância) ficam documentados para os agentes numa skill do projeto.
- Fonte de verdade: documentação da Apple — [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass), [Liquid Glass (visão geral)](https://developer.apple.com/documentation/technologyoverviews/liquid-glass), o sample [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass) e as Human Interface Guidelines. Skills da comunidade servem de apoio, nunca de referência acima da Apple.

## Alternativas consideradas

- **Bibliotecas de terceiros que imitam Liquid Glass** — ficam defasadas em relação ao sistema a cada versão do macOS e não acompanham acessibilidade (Reduzir transparência, Aumentar contraste) como as APIs nativas.
- **Efeito próprio com `NSVisualEffectView`/materiais antigos** — é a aparência pré-macOS 26; fica diferente dos apps atuais da Apple.
- **Suportar versões anteriores ao macOS 26 com fallback** — dobra o trabalho de UI para um app de uso pessoal num hardware que já roda o macOS 26.

## Consequências

- A aparência acompanha o sistema automaticamente nas próximas versões do macOS.
- Configurações de acessibilidade do sistema passam a valer sem esforço extra.
- O app não roda em macOS anterior ao 26.
- O efeito de foco no estilo tvOS (card que "levanta" e ganha brilho) não existe pronto no macOS e será feito com SwiftUI, junto com a camada de foco prevista no 0002.
- Uso de vidro tem regras (não empilhar vidro sobre vidro, usar só na camada de navegação/controles e não no conteúdo); revisões de UI devem conferir isso.
