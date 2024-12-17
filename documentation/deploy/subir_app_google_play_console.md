# Subir app a Google Play CONSOLE

Para crear el archivo AAB de la aplicación es recomendable seguir los siguientes pasos:

1. Limpiar el proyecto

   ```bash
   flutter clean
   flutter pub get
   ```

2. Probar la aplicación en modo release en un dispositivo físico

   ```bash
   flutter run --release
   ```

3. Crear el archivo AAB

   ```bash
   flutter build appbundle --release
   ```

4. Si da problemas el AAB al probarlo en la prueba interna:

Puedes general una salida detalla al construir el archivo AAB con el comando anterior. Para ello, se redirige la salida estándar y de error a un archivo de texto.

```bash
flutter build appbundle --release --verbose > build_log_full.txt 2>&1
```

Para verificar el contenido del archivo AAB:

```bash
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=test.apks
unzip -l test.apks
```

Busca específicamente el archivo MD:

```bash
unzip -l test.apks | grep privacy_policy_t3aisat.md
```

> También se puede descomprimir el archivo AAB usando la herramienta de descomprimir de macOS y ver así su contenido.
