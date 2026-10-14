# IA-DEV-MOBILE

Entorno de desarrollo de apps Android que se ejecuta **en el propio teléfono**,
desde la terminal ([Termux](https://termux.dev)), sin nube, sin Android Studio
y sin Gradle.

```
aapt2 (recursos) → javac (Java) → d8 (dex) → zipalign → apksigner → APK
```

## 1. Instalación (una vez)

1. Instala **Termux desde F-Droid** o desde las releases de GitHub
   (la versión de Google Play está obsoleta).
2. En Termux:

   ```bash
   pkg install -y git
   git clone https://github.com/damianes1802-ai/IA-DEV-MOBILE.git
   cd IA-DEV-MOBILE
   bash setup.sh
   ```

   Al final, `adev doctor` muestra qué herramientas están instaladas.

## 2. Uso

```bash
mkdir -p ~/proyectos && cd ~/proyectos
adev new MiApp com.yo.miapp     # crea el proyecto
cd MiApp
micro src/com/yo/miapp/MainActivity.java   # edita (o nano / vim)
adev build                      # → build/MiApp.apk
adev install                    # instala el APK
```

Estructura de un proyecto:

```
MiApp/
├── adev.conf            # nombre, paquete, minSdk, targetSdk, versión
├── AndroidManifest.xml
├── res/                 # layouts, strings, iconos…
├── src/                 # código Java
├── libs/                # (opcional) .jar extra
└── assets/              # (opcional)
```

## 3. Sin pantallas: instalar, abrir y ver logs con adb

Sin adb, `adev install` abre el instalador de Android y tienes que pulsar
«Instalar». Con la **depuración inalámbrica** (Android 11+) todo se hace
desde la terminal:

1. Ajustes → Acerca del teléfono → pulsa 7 veces «Número de compilación».
2. Ajustes → Opciones de desarrollador → **Depuración inalámbrica** (actívala)
   → «Vincular dispositivo con código». Pon Termux y Ajustes en pantalla
   dividida para ver el código.
3. En Termux (solo la primera vez):

   ```bash
   adev pair <puerto-de-vinculación> <código>
   ```

4. Cada vez que reactives la depuración inalámbrica:

   ```bash
   adev connect <puerto>    # el puerto que aparece en la pantalla principal
   ```

Después ya puedes hacer:

```bash
adev run     # compila, instala y abre la app
adev log     # logcat solo de tu app (Log.d, errores, crashes)
adev stop    # cierra la app
```

## Comandos

| Comando | Qué hace |
|---|---|
| `adev new <Nombre> [paquete]` | Crea un proyecto a partir de `template/` |
| `adev build` | Compila y firma `build/<Nombre>.apk` |
| `adev install` | Instala con adb, o abre el instalador de Android |
| `adev run` | `build` + `install` + abre la app |
| `adev log` / `adev stop` | Muestra los logs de la app / la cierra |
| `adev pair` / `adev connect` | Configura adb inalámbrico contra el propio teléfono |
| `adev clean` | Borra `build/` |
| `adev doctor` | Comprueba las herramientas |

## Notas

- El APK se firma con una clave de depuración (`~/.adev/debug.keystore`),
  válida para instalarlo en tu teléfono. Para publicar en Google Play
  necesitarás una clave propia y un AAB.
- El código es Java (compatible con Java 8). El template usa clases anónimas
  en lugar de lambdas para que funcione con cualquier `android.jar`.
- Si `adev doctor` no encuentra `android.jar`, cópialo a
  `~/.adev/android.jar` o define `ANDROID_JAR=/ruta/android.jar`.
- Todas las herramientas se pueden cambiar por variables de entorno:
  `AAPT2`, `D8`, `APKSIGNER`, `ZIPALIGN`, `JAVAC`.
