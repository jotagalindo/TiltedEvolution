#!/usr/bin/env bash
# Publishes the GitHub release for one run of fork-build.yml, in this fork only.
# Expects: VERSION, IMAGE, NOTES (may be empty), GH_TOKEN and the standard GITHUB_* variables,
# and the client artifacts already downloaded into release-files/.
set -euo pipefail

: "${VERSION:?VERSION is required}"
: "${IMAGE:?IMAGE is required}"

# Releases belong to the fork. Never publish anything on the official repository.
if [[ "${GITHUB_REPOSITORY,,}" == tiltedphoques/* ]]; then
    echo "Refusing to publish a release on ${GITHUB_REPOSITORY}: fork builds are released in the fork only." >&2
    exit 1
fi

branch_name="${GITHUB_REF_NAME//\//-}"
release_tag="${branch_name}-${VERSION}"
client_zip="release-files/SkyrimTogether-${VERSION}-windows-x64.zip"
symbols_zip="release-files/SkyrimTogether-${VERSION}-windows-x64-debug-symbols.zip"

# download-artifact hands back the zip itself for artifacts uploaded with archive: false.
# If it ever unpacks one into a folder instead, zip that folder back under the expected name.
for expected_zip in "$client_zip" "$symbols_zip"; do
    if [[ -d "$expected_zip" ]]; then
        unpacked_folder="${expected_zip}.unpacked"
        mv "$expected_zip" "$unpacked_folder"
        (cd "$unpacked_folder" && zip -qr "../$(basename "$expected_zip")" .)
        rm -rf "$unpacked_folder"
    fi
    if [[ ! -f "$expected_zip" ]]; then
        echo "Missing release asset: $expected_zip" >&2
        ls -la release-files >&2
        exit 1
    fi
done

previous_release_tag="$(git tag --list "${branch_name}-*" --sort=-creatordate | head -n 1)"
notes_file="$(mktemp)"
{
    echo "## Qué hay en esta build"
    echo
    if [[ -n "${NOTES}" ]]; then
        printf '%s\n' "${NOTES}"
    else
        echo "_Sin notas escritas para esta build: mira la lista de cambios de abajo._"
    fi
    echo
    echo "## Cómo probarla"
    echo
    echo "Cliente y servidor tienen que ser **de esta misma release**: el servidor rechaza clientes de otro commit."
    echo
    echo "1. **Servidor** (Portainer, línea \`image:\` del servicio \`skyrim-together\`):"
    echo '   ```yaml'
    echo "       image: ${IMAGE}:${VERSION}"
    echo '   ```'
    echo "   *Update the stack* con *Re-pull image*."
    echo "2. **Cliente** (cada jugador): instala \`SkyrimTogether-${VERSION}-windows-x64.zip\` en Vortex"
    echo "   (pestaña *Mods* → arrastrar el zip → *Install* → *Enable*) y desactiva cualquier otra versión de Skyrim Together."
    echo "   En *Plugins*, \`SkyrimTogether.esp\` y \`SkyrimTogetherQuestPatches.esp\` tienen que estar en *Enabled*."
    echo "3. \`…-debug-symbols.zip\` no se instala: sirve para analizar los \`crash_UTC_*.dmp\`."
    echo
    echo "## Cambios respecto a la \`dev\` oficial"
    echo
    if git rev-parse --verify --quiet origin/dev > /dev/null; then
        git log --first-parent --format='- %s (`%h`)' origin/dev..HEAD
    else
        echo "_No se encontró \`origin/dev\` para comparar._"
    fi
    if [[ -n "$previous_release_tag" ]]; then
        echo
        echo "## Cambios desde \`${previous_release_tag}\`"
        echo
        git log --first-parent --format='- %s (`%h`)' "${previous_release_tag}..HEAD"
    fi
    echo
    echo "---"
    echo "Commit \`${GITHUB_SHA}\` · rama \`${GITHUB_REF_NAME}\` · [ejecución del workflow](${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID})"
} > "$notes_file"

prerelease_flag=()
if [[ "$GITHUB_REF_NAME" != "jota" ]]; then
    prerelease_flag=(--prerelease)
fi

gh release create "$release_tag" "$client_zip" "$symbols_zip" \
    --repo "$GITHUB_REPOSITORY" \
    --target "$GITHUB_SHA" \
    --title "${GITHUB_REF_NAME} · ${VERSION}" \
    --notes-file "$notes_file" \
    "${prerelease_flag[@]}"

{
    echo "### Release"
    echo
    echo "[${release_tag}](${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/releases/tag/${release_tag})"
} >> "$GITHUB_STEP_SUMMARY"
