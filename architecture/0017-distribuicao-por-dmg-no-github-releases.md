# 0017. Distribuição por .dmg no GitHub Releases

- **Status:** Proposto
- **Data:** 2026-10-22
- **Substitui:** —
- **Substituído por:** —

## Contexto

Até aqui o cine-kit só roda para quem clona o repositório e roda `scripts/bundle.sh` com as Command Line Tools e o Node instalados. O objetivo é que qualquer pessoa baixe o app pronto, arraste para Aplicativos e use, sem ferramenta de desenvolvimento.

O projeto não tem conta paga do Apple Developer Program: só há um certificado "Apple Development", que não serve para distribuir fora da App Store nem para notarizar.

## Decisão

- **Formato:** um `.dmg` com o `CineKit.app` e um atalho para `/Applications`, gerado com `hdiutil` (vem com o macOS) por `scripts/dmg.sh`, depois do `scripts/bundle.sh`.
- **Onde:** GitHub Releases do próprio repositório.
- **Quando:** um workflow do GitHub Actions (`.github/workflows/release.yml`) roda a cada tag `vX.Y.Z`: testes, bundle, dmg e `gh release create` com notas geradas. Só usa o `GITHUB_TOKEN`, sem segredos novos. Um segundo workflow (`ci.yml`) roda os testes a cada push na `main`.
- **Versão:** vem da tag (`v0.1.0` → `0.1.0`), passada ao `bundle.sh` por `VERSION` e gravada em `CFBundleShortVersionString`/`CFBundleVersion`. Sem tag, `0.0.0-dev`.
- **Assinatura:** ad hoc (`codesign -s -`), sem notarização. Na primeira abertura o macOS bloqueia o app e o usuário libera em Ajustes → Privacidade e Segurança → "Abrir Mesmo Assim" (ou `xattr -dr com.apple.quarantine /Applications/CineKit.app`). O README explica.
- **Arquitetura:** só Apple Silicon (arm64). A imagem Android do [0004](0004-apps-android-via-emulador.md) também é arm64.
- **Licença:** MIT.

## Alternativas consideradas

- **Developer ID + notarização** — abre sem aviso, mas exige a conta paga (US$ 99/ano). Pode substituir a assinatura ad hoc depois só mudando o `codesign` e adicionando `notarytool`/`stapler` ao workflow.
- **Mac App Store** — o sandbox impede rodar o emulador Android e servir o controle na rede como hoje.
- **Homebrew cask** — exige um tap e não muda o problema da assinatura. Pode vir depois apontando para o mesmo `.dmg`.
- **.pkg** — só faria sentido para rodar scripts na instalação, e as dependências agora são instaladas pelo próprio app ([0018](0018-sdk-android-instalado-pelo-app.md)).
- **Release montada no Mac do autor** — depende da máquina local e não roda os testes num ambiente limpo.

## Consequências

- Publicar uma versão é `git tag vX.Y.Z && git push origin vX.Y.Z`.
- Quem instala precisa liberar o app uma vez nos Ajustes do macOS.
- O `bundle.sh` precisa funcionar também com o Xcode do runner (não força o SDK das Command Line Tools quando há Xcode).
- Macs Intel ficam de fora.
