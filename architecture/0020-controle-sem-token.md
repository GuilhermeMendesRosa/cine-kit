# 0020. Controle remoto numa URL fixa, sem token

- **Status:** Proposto
- **Data:** 2026-10-23
- **Substitui:** no [0003](0003-controle-remoto-web-via-wifi.md), o pareamento por token e o `401` do protocolo v1
- **Substituído por:** —

## Contexto

No [0003](0003-controle-remoto-web-via-wifi.md), o controle só funciona com o token aleatório que vai na URL do QR. Isso obriga a escanear o QR em cada celular, faz o atalho da tela de início guardar um endereço que muda com "Gerar novo código" e mostra a tela "Escaneie o QR" quando o token expira. O CineKit roda numa rede de casa, e o dono quer abrir o controle digitando o endereço e salvá-lo na tela de início do iPhone com o ícone do app.

O `apple-touch-icon.png` atual já vem com cantos arredondados e transparentes; o iOS arredonda de novo e pinta a transparência de preto.

## Decisão

- **URL fixa.** O controle vive em `http://<LocalHostName>.local:8686/`, sem query. O QR das Configurações e da Home continua, com essa URL.
- **Sem autenticação.** A API (`/api/press`, `/api/pointer`, `/api/text`, `/api/theme`, `/api/state`) aceita qualquer requisição da rede, sem `Authorization`. Sai o `401` do protocolo; o resto do v1 fica igual. Sai "Gerar novo código" e o token do `UserDefaults` deixa de ser lido.
- **Ícone gerado.** O `scripts/bundle.sh` gera o `apple-touch-icon.png` (180×180) a partir de `assets/AppIcon.png`, recortado no quadrado azul, sem transparência. O `remote/public/apple-touch-icon.png` é regenerado do mesmo jeito para o `npm run dev`.

## Alternativas consideradas

- **Token fixo na URL** — continua exigindo o QR em cada celular e não protege de verdade quem está na mesma rede.
- **Manter o PNG do controle** — fica com os cantos pretos no iPhone e desatualiza quando o ícone do app mudar.

## Consequências

- Qualquer aparelho na mesma rede Wi-Fi controla o CineKit, inclusive digitar texto. Aceitável numa rede de casa; em rede pública, o controle fica exposto.
- O atalho salvo na tela de início não expira mais.
- O app web perde a tela de pareamento e o `localStorage` do token.
- A chave `remoteToken` antiga fica no `UserDefaults`, sem uso.
