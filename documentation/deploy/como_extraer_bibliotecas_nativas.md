# [Cómo extraer bibliotecas nativas](https://developer.android.com/studio/build/shrink-code#native-crash-support)

De forma predeterminada, las bibliotecas de código nativo se extraen en las compilaciones de actualización de tu app. Esta extracción consiste en quitar la tabla de símbolos y la información de depuración de las bibliotecas nativas que usa tu app. La extracción de bibliotecas de código nativo genera un ahorro significativo de tamaño. Sin embargo, es imposible diagnosticar fallas en Google Play Console debido a la falta de información (como los nombres de clases y funciones).

## Asistencia para fallas por error en código nativo

Google Play Console informa las fallas por error en código nativo, en [Android vitals](https://developer.android.com/studio/debug/android-vitals). Con solo unos pasos, puedes generar y subir un archivo nativo de símbolos de depuración para tu app. Este archivo habilita seguimientos de pila de fallas simbólicas por error en código nativo (que incluyen nombres de clases y funciones), en Android vitals para que te ayuden a depurar tu app en producción. Estos pasos varían según la versión del complemento de Android para Gradle que uses en tu proyecto y el resultado de la compilación de este.

> 📝 **Nota:** Para restablecer los nombres de símbolos en los informes de fallas por tu cuenta, usa la [herramienta ndk-stack](https://developer.android.com/ndk/guides/ndk-stack), que viene incluida con el NDK de Android.

### Versión del complemento de Gradle para Android: 4.1 o posterior

Si tu proyecto involucra la compilación de un Android App Bundle, puedes incluir el archivo nativo de símbolos de depuración automáticamente. Para incluir este archivo en compilaciones de actualización, agrega lo siguiente al archivo `build.gradle.kts` de tu app:

```kotlin
android.buildTypes.release.ndk.debugSymbolLevel = { SYMBOL_TABLE | FULL }
```

Selecciona uno de los siguientes niveles de símbolos de depuración:

- Usa el elemento `SYMBOL_TABLE` para obtener los nombres de las funciones en los seguimientos de pila simbólicos de Play Console. Este nivel es compatible con [tombstones](https://developer.android.com/ndk/guides/ndk-stack#tombstones).
- Usa el objeto `FULL` para obtener los nombres de funciones, los archivos y los números de línea en los seguimientos de pila simbólicos de Play Console.

> 📝 **Nota:** Hay un límite de 300 MB para el archivo nativo de símbolos de depuración. Si la huella de los símbolos de depuración es demasiado grande, usa `SYMBOL_TABLE` en lugar de `FULL` para reducir el tamaño del archivo.

Si tu proyecto involucra la creación de un APK, usa la configuración de compilación `build.gradle.kts` anterior para generar el archivo nativo de símbolos de depuración por separado. De forma manual, [sube el archivo nativo de símbolos de depuración](https://developer.android.com/studio/publish/upload-crash-symbols) a Google Play Console. Como parte del proceso de compilación, el complemento de Gradle para Android genera este archivo en la siguiente ubicación del proyecto:

```bash
app/build/outputs/native-debug-symbols/variant-name/native-debug-symbols.zip
```

### Complemento de Android para Gradle versión 4.0 o anterior (y otros sistemas de compilación)

Como parte del proceso de compilación, el complemento de Android para Gradle conserva una copia de las bibliotecas sin extraer en un directorio de proyecto. Esta estructura de directorios es similar a la siguiente:

```plaintext
app/build/intermediates/cmake/universal/release/obj/
├── armeabi-v7a/
│ ├── libgameengine.so
│ ├── libothercode.so
│ └── libvideocodec.so
├── arm64-v8a/
│ ├── libgameengine.so
│ ├── libothercode.so
│ └── libvideocodec.so
├── x86/
│ ├── libgameengine.so
│ ├── libothercode.so
│ └── libvideocodec.so
└── x86_64/
├── libgameengine.so
├── libothercode.so
└── libvideocodec.so
```

> 📝 **Nota:** Si usas un sistema de compilación diferente, puedes modificarlo para almacenar bibliotecas sin extraer en un directorio que cumpla con la estructura que se indicó más arriba.

1. **Comprime el contenido de este directorio:**

   Ejecuta los siguientes comandos en tu terminal:

   ```bash
   cd app/build/intermediates/cmake/universal/release/obj
   zip -r symbols.zip .
   ```

2. **Sube manualmente el archivo `symbols.zip` a Google Play Console.**

> 📝 **Nota:** Hay un límite de 300 MB para el archivo de símbolos de depuración. Si tu archivo es demasiado grande, es posible que se deba a que los archivos `.so` contienen una tabla de símbolos (nombres de funciones) además de información de depuración DWARF (nombres de archivos y líneas de código). Estos elementos no son necesarios para simbolizar el código. Para quitarlos, ejecuta el siguiente comando:
>
> ```bash
> $OBJCOPY --strip-debug lib.so lib.so.sym
> ```
>
> , en el que `$OBJCOPY` apunta a la versión específica de la ABI que estás extrayendo (por ejemplo, `ndk-bundle/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/aarch64-linux-android-objcopy`).
