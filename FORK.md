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
| 2026-10-18 | Fusionados 4 PR del repo oficial que siguen **abiertos** allí y entran sin conflictos sobre `dev` `69fe8e67`: **#848** (`bdf55ecf`), misiones en grupo sin etapas duplicadas ni escenas atascadas; **#898** (`c72b1df5`), NPC que no desenvainan tras cambiar de dueño; **#861** (`6bbc6a78`), armas de NPC remotos que desaparecen; **#879** (`bb65834b`), sincronización de animaciones de mods y comando `/wave`. No incluidos: #846, que también entra sin conflicto, pero según los mantenedores descarta las misiones completadas por los miembros del grupo; y los PR con conflictos (#891, #913, #897, #895, #918, #839, #912). |

## Quitar un PR fusionado

Cada PR entra como un commit de fusión `Merge upstream PR #<número> …`. Para quitarlo: `git revert -m 1 <commit de la fusión>`, subir `jota` y recompilar.

## Cuando el proyecto oficial fusione uno de estos PR

Al traer `upstream/dev` con `git merge dev` (ver *Actualizar desde el proyecto oficial*), git reconoce los commits que ya tenemos. Si el PR cambió después de fusionarlo aquí, puede haber conflictos: en ese caso, nos quedamos con la versión de `dev` oficial.
