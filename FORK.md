# Fork de jotagalindo

Fork de [tiltedphoques/TiltedEvolution](https://github.com/tiltedphoques/TiltedEvolution) (Skyrim Together Reborn) para nuestro servidor privado. El stack del servidor (Portainer + Cloudflare) y su documentación están en el proyecto `skyrim together stack`.

**Nunca se sube nada al repo oficial.** Todo va a este fork.

## Ramas

| Rama | Qué es |
|---|---|
| `oficial` | **La que usamos para jugar.** `dev` oficial tal cual, más solo nuestro CI (`fork-build.yml`, `.github/scripts/fork-release.sh` y el `--match` de versión en `windows.yml`). No lleva ningún cambio nuestro en el código del juego. |
| `jota` | Rama por defecto del fork: `dev` oficial de 2026-10-16 más 4 PR del oficial (#848, #898, #861, #879). Su build (54) dio un fallo en el juego y se retiró. Se conserva solo como referencia. |
| `jota-extra` | Pruebas: `jota` más #891, #895 y #913. Su release (67) se retiró. Referencia. |
| `dev` | Copia de la `dev` oficial. No se toca: se actualiza desde `upstream`. |

## Compilar cliente y servidor

El servidor rechaza cualquier cliente compilado de otro commit (comprobación `BUILD_COMMIT`), así que **los dos siempre salen de la misma ejecución** del workflow [`fork-build.yml`](.github/workflows/fork-build.yml):

1. GitHub → *Actions* → **Fork build (client + server)** → *Run workflow*: elegir la rama (normalmente `oficial`) y escribir en **notes** qué cambia. Desde la terminal: `gh workflow run fork-build.yml -R jotagalindo/TiltedEvolution --ref oficial -f notes="…"`.
2. Se compila **solo el cliente para la versión actual del juego (1.7.104)**. El oficial también compila uno para 1.6.1170 en `windows-playable-build.yml`; aquí no hace falta.
3. Al acabar (unos 15–25 minutos) **se publica una release en este fork** con etiqueta `<rama>-<versión>`: zip del cliente para Vortex, símbolos de depuración, la línea `image:` del servidor y las notas. Las ramas que no son `jota` salen como *pre-release*.
4. **Servidor:** `ghcr.io/jotagalindo/st-reborn-server:<versión>` (y `:<rama>`, que cambia con cada build; en Portainer, fijar siempre `<versión>`).
5. `<versión>` sale de `git describe --tags --always --match 'v[0-9]*'`: solo cuentan las etiquetas oficiales `vX.Y.Z`, no las de nuestras releases.
6. El script de la release se niega a publicar si el repositorio es `tiltedphoques/*`.

## Actualizar `oficial` desde el proyecto oficial

```bash
git fetch upstream --tags
git checkout dev && git merge --ff-only upstream/dev && git push origin dev
git checkout oficial && git merge dev && git push origin oficial
```

## Historial

| Fecha | Cambio |
|---|---|
| 2026-10-18 | Añadido `fork-build.yml`, releases por build y este archivo. Sin cambios en el código del juego. |
| 2026-10-28 | Rama `oficial` creada desde `dev` oficial `25a0049a` (2026-10-27) con solo nuestro CI. `fork-build.yml` compila únicamente el cliente 1.7.104 llamando a `windows.yml`. |
