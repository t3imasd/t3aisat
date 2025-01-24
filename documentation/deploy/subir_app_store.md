# Subir archivo de la app al App Store

## Pasos para subir un archivo de la app al App Store

Para subir un archivo de la app al App Store, sigue estos pasos:

1. Abre Xcode y selecciona como dispositivo `Any iOS Device`.

2. En el menú superior, selecciona `Xcode` > `Window` > `Organizer`.

3. En el menú superior, selecciona `Xcode` > `Product` > `Archive`.

4. En la ventana de `Organizer`, selecciona el archivo de la app que acabas de crear.

5. En la parte derecha de la ventana, haz clic en el botón `Validate App`.

6. Si la validación es exitosa, haz clic en el botón `Distribute App`.

7. Selecciona la opción `TestFlight` y haz clic en el botón `Next` para subir la app a TestFlight.

8. Si la app funciona correctamente en TestFlight, vuelve otra vez a la ventana de `Organizer` y pulsa el botón `Distribute App`.

9. Selecciona la opción `App Store Connect` y haz clic en el botón `Next` para subir la app al App Store.

## Solución a problemas con CocoaPods

Si encuentras errores relacionados con CocoaPods al crear el Archive, como por ejemplo con el mensaje `The sandbox is not in sync with the Podfile.lock. Run 'pod install' or update your CocoaPods installation.`, sigue estos pasos de limpieza completa:

1. Cierra Xcode completamente

2. Abre la terminal y elimina los archivos de caché:

   ```bash
   cd ios
   rm -rf Pods/
   rm -rf .symlinks/
   rm -f Podfile.lock
   ```

3. Limpia el proyecto Flutter:

   ```bash
   cd ..
   flutter clean
   flutter pub get
   ```

4. Reinstala los pods:

   ```bash
   cd ios
   pod install --repo-update
   ```

5. Vuelve a abrir Xcode usando el archivo `.xcworkspace` y crea el Archive nuevamente.
