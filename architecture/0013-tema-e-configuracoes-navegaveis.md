# 0013. Tema claro/escuro e Configurações navegáveis por setas

- **Status:** Aceito
- **Data:** 2026-10-22
- **Substitui:** no [0007](0007-camada-de-foco-da-home.md), o limite da camada de foco à home (estende às Configurações); no [0011](0011-app-web-do-controle-em-react.md), o "visual escuro"
- **Substituído por:** [0015](0015-controle-absoluto-analogico-e-som.md) (trechos), [0019](0019-tema-escolhido-e-pareado-com-o-controle.md) (trechos)

## Contexto

A home é sempre clara e o resto do app sempre escuro (`.preferredColorScheme(.dark)`); o controle no celular é sempre escuro. O usuário quer escolher o tema e um visual Liquid Glass no Mac e no controle.

As Configurações usam uma `List` nativa: só a lista anda por setas, e os botões do topo só por Tab ou mouse. Com o controle único do [0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md), tudo precisa ser alcançável por setas e por mouse. O usuário também quer reordenar os apps da home e que a ordem fique salva.

## Decisão

- **Tema: Automático / Claro / Escuro**, padrão **Escuro**, salvo em `@AppStorage("appTheme")`. Aplicado com `NSApp.appearance` (`nil`, `.aqua`, `.darkAqua`), que vale também para sheets, alertas e painéis.
- **Home e Configurações seguem o tema; telas de mídia** (webview, Android, abrindo/erro) **continuam escuras**.
- **Controle no celular segue o tema do celular** (`prefers-color-scheme`), sem endpoint novo. O vidro é CSS próprio (sem biblioteca, como no 0011): fundo em gradiente suave, painéis e botões translúcidos com `backdrop-filter: blur(24px) saturate(180%)` e borda especular; com `prefers-reduced-transparency` ou `prefers-contrast: more` o vidro fica opaco; com `prefers-reduced-motion`, sem escala no toque.
- **Redesign da home.** Fundo em gradiente da cor do app focado sobre o fundo da janela (animado, sem animação com Reduzir movimento); barra superior com relógio à esquerda e Configurações em vidro à direita (`.glassProminent` quando focado); bandeja sem vidro (é conteúdo rolável); card focado com escala, sombra e borda especular, sem vidro; nome do app focado sob a bandeja.
- **Configurações navegáveis por setas.** A camada de foco do 0007 é estendida: `SettingsFocus.move` no `CineKitCore` move numa grade de linhas × colunas (↑↓ trocam de linha, limitando a coluna ao tamanho da nova linha; ←→ trocam de coluna), Return ativa, Esc fecha. Hover = foco quando o ponteiro está em uso ([0012](0012-controle-unico-com-paridade-de-teclado-e-mouse.md)); clique ativa. O controle focado ganha vidro; os outros, fundo neutro (um vidro por vez).
- **Layout das Configurações:** coluna central com as seções Aparência (Tema), Apps (uma linha por app com Editar, ▲, ▼ e Remover; depois Adicionar app, Adicionar APK… e Restaurar padrões), Android (Resolução, só com o runtime) e Controle remoto (QR, URL e Gerar novo código).
- **Reordenar apps** com os botões **▲ Subir / ▼ Descer** de cada linha; o foco acompanha o app movido. A ordem é a do array em `apps.json` (`AppCatalogStore.move(id:by:)`), sem schema novo.
- **"Restaurar padrões"** volta também à ordem original (padrões primeiro, depois os apps do usuário), e o diálogo diz isso.

## Alternativas consideradas

- **Só Claro e Escuro** — o Automático custa uma linha e respeita quem segue o sistema.
- **`.preferredColorScheme`** — não alcança sheets e painéis de forma consistente, e `nil` não volta direito ao tema do sistema no macOS.
- **Controle espelhando o tema do Mac** — exigiria endpoint novo; o app no telefone deve respeitar o ajuste do aparelho.
- **Manter a `List` nativa** — os botões fora da lista continuariam fora do alcance das setas.
- **Arrastar e soltar para reordenar** — não funciona por setas; um modo "pegar" seria uma interação a mais.

## Consequências

- A regra "Home clara, mídia escura" da skill `liquid-glass` passa a ser "Menus seguem o tema; mídia escura".
- Cada controle novo nas Configurações precisa de um lugar na grade de foco.
- `AppFormSheet` e as telas de abrindo/erro só herdam o tema, sem redesign.
