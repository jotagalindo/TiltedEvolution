#!/usr/bin/env bash
# Publishes the GitHub release for one run of fork-build.yml, in this fork only.
# Expects: VERSION, IMAGE, NOTES (may be empty), GH_TOKEN and the standard GITHUB_* variables,
# and the two artifacts downloaded into release-files/client and release-files/symbols.
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

# Turns one downloaded artifact folder into the release zip. download-artifact unpacks the zip
# that windows.yml uploaded, so the folder holds its contents; if it ever holds the zip itself
# instead, that file is used as is.
package_artifact() {
    local artifact_folder="$1"
    local target_zip="$2"
    local target_zip_path
    target_zip_path="$(pwd)/${target_zip}"

    if [[ ! -d "$artifact_folder" ]] || [[ -z "$(ls -A "$artifact_folder")" ]]; then
        echo "Missing or empty artifact folder: $artifact_folder" >&2
        ls -laR release-files >&2 || true
        exit 1
    fi

    local folder_entries=("$artifact_folder"/*)
    if [[ ${#folder_entries[@]} -eq 1 && -f "${folder_entries[0]}" && "${folder_entries[0]}" == *.zip ]]; then
        mv "${folder_entries[0]}" "$target_zip_path"
    else
        (cd "$artifact_folder" && zip -qr "$target_zip_path" .)
    fi

    rm -rf "$artifact_folder"
}

package_artifact release-files/client "$client_zip"
package_artifact release-files/symbols "$symbols_zip"

# The client zip has to install straight into Data/ from Vortex.
# The listing goes through a variable: piping unzip into `grep -q` breaks under pipefail.
client_zip_listing="$(unzip -Z1 "$client_zip")"
if ! grep -qx 'SkyrimTogetherReborn/SkyrimTogether.exe' <<< "$client_zip_listing"; then
    echo "The client zip has no SkyrimTogetherReborn/SkyrimTogether.exe at its root:" >&2
    head -n 20 <<< "$client_zip_listing" >&2
    exit 1
fi

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
