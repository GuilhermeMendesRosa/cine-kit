---
name: release
description: Publica uma release do CineKit no GitHub Releases criando e enviando a tag vX.Y.Z, que dispara o workflow release.yml (testes, .dmg e publicação), e acompanha o workflow até a release sair. Use quando o dev pedir para "fazer a release", "publicar uma versão", "soltar a 0.2.0", "gerar o dmg no GitHub" ou invocar /release.
---

# Release do CineKit no GitHub

Fluxo do [ADR 0017](../../../architecture/0017-distribuicao-por-dmg-no-github-releases.md): o push de uma tag `vX.Y.Z` dispara `.github/workflows/release.yml`, que roda os testes, monta o `.dmg` com a versão da tag e publica `CineKit X.Y.Z` com as notas geradas a partir dos commits. Nada é montado nem enviado à mão.

## Passos

1. **Confira o estado do repo.**
   - Branch `main`, working tree limpo (`git status --short` vazio). Mudança sem commit não entra na release: pare e pergunte se o dev quer commitar antes.
   - `git fetch origin` e `main` igual a `origin/main`. Commit local sem push: pergunte se é para enviar (`git push origin main`) antes de seguir.

2. **Confira o CI do commit.** `gh run list --branch main --workflow ci.yml --limit 1` precisa estar `success` no `HEAD`. Se ainda estiver rodando, acompanhe com `gh run watch <id> --exit-status`. Se falhou, pare e mostre o log (`gh run view <id> --log-failed`).

3. **Escolha a versão.**
   - Última tag: `git tag --sort=-v:refname | head -1`. Commits desde ela: `git log --oneline <tag>..HEAD`. Sem commits novos, não há o que publicar: avise e pare.
   - Se o dev já disse a versão, use essa. Senão, proponha uma pelos Conventional Commits (pré-1.0): `feat:` ou mudança que quebra algo → minor (`0.1.1` → `0.2.0`); só `fix:`, `docs:`, `chore:` e similares → patch (`0.1.1` → `0.1.2`).
   - **Confirme com o dev** a versão e a lista de commits que entram antes de criar a tag: a release é pública e a tag não deve ser reaproveitada.

4. **Crie e envie a tag.**

   ```sh
   git tag vX.Y.Z && git push origin vX.Y.Z
   ```

   Sem tag anotada, sem editar `VERSION` nem `Info.plist`: a versão sai da tag.

5. **Acompanhe o workflow.** `gh run list --workflow release.yml --limit 1` para achar o run da tag e `gh run watch <id> --exit-status` até terminar.
   - Falhou: mostre o log (`gh run view <id> --log-failed`) e não apague a tag por conta própria. Corrigir costuma ser um commit novo e uma tag nova (patch seguinte). Apagar e recriar a tag só com OK explícito do dev.

6. **Confira a release.** `gh release view vX.Y.Z` lista o `CineKit-X.Y.Z.dmg` como asset.

## No fim

Passe ao dev a URL da release (`gh release view vX.Y.Z --json url -q .url`), a versão e os commits incluídos. Se ele quiser essa versão no próprio Mac, a skill `update-app` instala o build local (que sai como `0.0.0-dev`); para a versão numerada, é baixar o `.dmg` da release.
