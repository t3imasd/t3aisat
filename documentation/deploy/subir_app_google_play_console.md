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
