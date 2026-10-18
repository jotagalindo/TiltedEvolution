# Fork de jotagalindo

Fork de [tiltedphoques/TiltedEvolution](https://github.com/tiltedphoques/TiltedEvolution) (Skyrim Together Reborn) para nuestro servidor privado. El stack del servidor (Portainer + Cloudflare) y su documentación están en el proyecto `skyrim together stack`.

## Ramas

| Rama | Qué es |
|---|---|
| `jota` | **Rama por defecto del fork.** Es `dev` oficial más nuestros cambios. De aquí salen los builds que usamos. |
| `dev` | Copia de la `dev` oficial. No se toca: se actualiza desde `upstream`. |

## Compilar cliente y servidor

El servidor rechaza cualquier cliente compilado de otro commit (comprobación `BUILD_COMMIT`), así que **los dos siempre salen de la misma ejecución** del workflow [`fork-build.yml`](.github/workflows/fork-build.yml):

1. GitHub → *Actions* → **Fork build (client + server)** → *Run workflow* (rama `jota`).
2. Cuando acaba (unos 15 minutos):
   - **Cliente:** artefacto `SkyrimTogether-<versión>-windows-x64` en la página de la ejecución. Dura 7 días y hace falta sesión en GitHub para descargarlo.
   - **Símbolos de depuración:** artefacto `…-debug-symbols`. Sirven para leer los `crash_UTC_*.dmp`.
   - **Servidor:** imagen `ghcr.io/jotagalindo/st-reborn-server:<versión>`.
3. `<versión>` es la misma en los dos (salida de `git describe --tags --always`, sin la `v`). Viene en el resumen de la ejecución.

## Actualizar desde el proyecto oficial

```bash
git fetch upstream --tags
git checkout dev && git merge --ff-only upstream/dev && git push origin dev --tags
git checkout jota && git merge dev && git push origin jota
```

## Nuestros cambios

| Fecha | Cambio |
|---|---|
| 2026-10-18 | Añadido `fork-build.yml` y este archivo. Sin cambios en el código del juego. |
