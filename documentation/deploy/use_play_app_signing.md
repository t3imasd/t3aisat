# [Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/7384423?hl=en)

Con **Play App Signing**, Google gestiona y protege la clave de firma de tu aplicación para usarla en la firma de APKs de distribución optimizados generados a partir de tus app bundles. Play App Signing almacena tu clave de firma en la infraestructura segura de Google y ofrece opciones de actualización para aumentar la seguridad.

Para utilizar Play App Signing, debes ser propietario de la cuenta o un usuario con los permisos de [Release to production, exclude devices, and use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9844686#release_production), y debes aceptar los [Play App Signing Terms of Service](https://play.google.com/about/play-app-signing-updated-terms/).

## How it works

Cuando utilizas Play App Signing, tus claves se almacenan en la misma infraestructura segura que Google utiliza para sus propias claves. Estas están protegidas por el **Google’s Key Management Service**. Si deseas obtener más información sobre la infraestructura de Google, puedes leer el [Google Cloud Security Whitepaper](https://services.google.com/fh/files/misc/security_whitepapers_march2018.pdf).

Las aplicaciones de Android se firman con una clave privada. Para garantizar que las actualizaciones de la aplicación sean seguras, cada clave privada tiene un certificado público asociado que los dispositivos y servicios utilizan para verificar que la aplicación proviene de la misma fuente. Los dispositivos solo aceptan actualizaciones cuando la firma coincide con la de la aplicación instalada. Al permitir que Google gestione tu clave de firma de la aplicación, se simplifica el proceso.

> **Nota:** Para las aplicaciones creadas después de agosto de 2021, aún puedes subir un APK y gestionar tus propias claves sin usar Play App Signing publicando con un [Android App Bundle](https://developer.android.com/guide/app-bundle/). Sin embargo, si pierdes tu keystore o se ve comprometido, no podrás actualizar tu aplicación sin publicar una nueva con un nombre de paquete diferente. Para estas aplicaciones, Google recomienda usar Play App Signing y cambiar a app bundles.

### Descriptions of keys, artifacts, and tools

| **Term**                                 | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **App signing key**                      | La clave que utiliza Google Play para firmar los APKs que se entregan al dispositivo del usuario. Al utilizar Play App Signing, puedes subir una clave de firma de aplicación existente o dejar que Google genere una para ti. Mantén tu clave de firma secreta, pero puedes compartir el certificado público de tu aplicación con otros.                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **Upload key**                           | La clave que utilizas para firmar tu app bundle antes de subirlo a Google Play. Mantén tu upload key en secreto, pero puedes compartir el certificado público de tu aplicación con otros. Por razones de seguridad, es una buena práctica que la clave de firma de la aplicación y la upload key sean diferentes entre sí. Hay dos formas de generar una upload key: <ul><li>**Usar tu app signing key:** Si Google genera tu clave de firma de aplicación, la clave que usas para tu primer lanzamiento es también tu upload key.</li><li>**Usar una upload key separada:** Si proporcionas tu propia clave de firma, se te da la opción de generar una nueva upload key para mayor seguridad. Si no generas una, utiliza tu app signing key como upload key para firmar los lanzamientos.</li></ul> |
| **Certificate (.der o .pem)**            | Un certificado contiene una clave pública e información adicional sobre quién posee la clave. El certificado público permite a cualquiera verificar quién firmó el app bundle o APK, y puedes compartirlo con cualquiera ya que no incluye tu clave privada. Para registrar tus claves con proveedores de API, puedes descargar el certificado público para tu app signing key y upload key desde la página de [Play App Signing](https://play.google.com/console/developers/app/keymanagement) (Test and release > Setup > App signing) en Play Console.                                                                                                                                                                                                                                             |
| **Certificate fingerprint**              | Una representación corta y única de un certificado, que a menudo es solicitada por proveedores de API para registrar una aplicación y usar su servicio. Las huellas digitales MD5, SHA-1 y SHA-256 de los certificados de upload y de app signing se pueden encontrar en la página de [Play App Signing](https://play.google.com/console/developers/app/keymanagement) (Test and release > Setup > App signing) en Play Console. Otras huellas digitales también se pueden calcular descargando el certificado original (.der).                                                                                                                                                                                                                                                                       |
| **Java keystore (`.jks` o `.keystore`)** | Un repositorio de certificados de seguridad y claves privadas.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| **Play Encrypt Private Key (PEPK) tool** | Una herramienta para exportar claves privadas desde un Java keystore y cifrarlas para transferirlas a Google Play. Cuando proporcionas la app signing key que usará Google, selecciona la opción para exportar y subir tu clave (y su certificado público si es necesario) y sigue las instrucciones para descargar y usar la herramienta. Si prefieres, puedes descargar, revisar y utilizar el código fuente abierto de la herramienta PEPK.                                                                                                                                                                                                                                                                                                                                                        |

### App signing process

El proceso de firma de aplicaciones es el siguiente:

1. Firma tu app bundle y súbelo a la [Play Console](https://play.google.com/console).
2. Google genera APKs optimizados a partir de tu app bundle y los firma con la app signing key.
3. Google utiliza [apksigner](https://developer.android.com/studio/command-line/apksigner) para añadir dos sellos al manifiesto de tu aplicación (`com.android.stamp.source` y `com.android.stamp.type`) y luego firma los APKs con la app signing key. Los sellos añadidos por apksigner permiten rastrear los APKs para saber quién los firmó.
4. Google entrega los APKs firmados a los usuarios.

## Set up and manage Play App Signing

Si tu aplicación aún no utiliza Play App Signing, sigue las instrucciones a continuación:

### Step 1: Create an upload key

1. Siguiendo estas [instrucciones](https://developer.android.com/studio/publish/app-signing), crea una upload key.
2. Firma tu app bundle con la upload key.

### Step 2: Prepare your release

1. Sigue las instrucciones para [preparar y desplegar tu lanzamiento](https://developer.android.com/studio/publish/preparing).
2. Después de seleccionar una pista de lanzamiento, la sección **App integrity** muestra el estado de Play App Signing para tu aplicación.
3. Para continuar con una clave de firma de aplicación generada por Google, sube tu app bundle. Alternativamente, puedes seleccionar **Change app signing key** para acceder a las siguientes opciones:

   - **Usar una app signing key generada por Google:** Más del 90% de las nuevas aplicaciones utilizan claves de firma generadas por Google. Usar una clave generada por Google protege contra la pérdida o compromiso de la clave (la clave no es descargable). Si eliges esta opción, puedes descargar APKs de distribución desde el [App bundle explorer](https://play.google.com/console/developers/app/bundle-explorer) firmados con la clave generada por Google para otros canales de distribución, o utilizar una clave diferente para ellos.
   - **Usar una app signing key diferente:** Elegir una clave de firma diferente te permite usar la misma clave que otra aplicación en tu cuenta de desarrollador o mantener una copia local de tu clave de firma para mayor flexibilidad. Por ejemplo, podrías tener ya una clave decidida porque tu aplicación viene preinstalada en algunos dispositivos. Tener una copia de tu clave fuera de los servidores de Google aumenta el riesgo si la copia local se ve comprometida. Tienes las siguientes opciones para utilizar una clave diferente:
     - Usar la misma app signing key que otra aplicación en esta cuenta de desarrollador.
     - Exportar y subir una clave desde un Java keystore.
     - Exportar y subir una clave (sin usar Java keystore).
     - **Optar por no usar Play App Signing** (solo deberías elegir esta opción si planeas [actualizar tu clave de firma para inscribirte en Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en&visit_id=638673512252632764-2865339235&rd=1#upgrade_enroll)).

4. Completa las instrucciones restantes para [preparar y desplegar tu lanzamiento](https://support.google.com/googleplay/android-developer/answer/9859348).

> **Nota:** Debes aceptar los Términos de Servicio y optar por la firma de aplicaciones para continuar.

### Step 3: Register your app signing key with API providers

Si tu aplicación utiliza APIs, generalmente necesitas registrar tu clave de firma con ellos para fines de autenticación usando la huella digital del certificado. Aquí se explica cómo encontrar el certificado:

1. Abre Play Console y ve a la página de [Play App Signing](https://play.google.com/console/developers/app/keymanagement) (Test and release > Setup > App signing).
   - **Tip:** También puedes acceder a esta página a través de la sección **App integrity** (Test and release > App integrity), que contiene servicios de integridad y firma para ayudarte a asegurar que los usuarios experimenten tus aplicaciones y juegos como lo deseas.
2. Desplázate a la sección **App signing key certificate** y copia las huellas digitales (MD5, SHA-1 y SHA-256) de tu certificado de firma de aplicación.
   - Si el proveedor de API requiere otro tipo de huella digital, también puedes descargar el certificado original en formato `.der` y convertirlo usando herramientas de transformación que el proveedor de API requiera.

#### App signing key requirements

Cuando usas una clave generada por Google, esta es una clave RSA fuerte de 4096 bits. Si eliges subir tu propia clave de firma, entonces debe ser una clave RSA de al menos 2048 bits.

#### Upgrade your app signing key to enroll into Play App Signing

Es posible que desees hacer esto si no puedes compartir tu clave existente. Antes de elegir actualizar tu clave de firma para inscribirte, toma en cuenta lo siguiente:

- Esta opción requerirá un lanzamiento dual.
- Necesitarás subir un app bundle y un APK firmado con tu clave heredada en cada lanzamiento. Google utilizará tu app bundle para generar APKs firmados con la nueva clave para dispositivos que ejecutan Android R\* (API nivel 30) o posterior. Los APKs heredados se usarán para dispositivos Android más antiguos (hasta el nivel de API 29).

\*If your app makes use of `sharedUserId`, it is recommended to apply key upgrade for installs and updates on devices running Android T (API level 33) or later. To configure this, please set an accurate minimum SDK version in the bundle configuration.

##### Step 1: Upload your new key and generate and upload proof-of-rotation

Para que la nueva clave sea confiable en los dispositivos Android, debes subir una nueva clave de firma desde un repositorio y generar y subir una prueba de rotación (proof-of-rotation):

1. Abre Play Console y dirígete a la página de [Play App Signing](https://play.google.com/console/developers/app/keymanagement) (Test and release > Setup > App signing).
   - **Tip:** También puedes acceder a esta página a través de [App integrity](https://play.google.com/console/developers/app/app-integrity/overview) (Test and release > App integrity), que incluye [servicios de integridad y firma](https://support.google.com/googleplay/android-developer/answer/13857328) para garantizar que los usuarios experimenten tus aplicaciones y juegos como lo deseas.
2. Selecciona la pestaña **App signing**.
3. Haz clic en **Show advanced options** y selecciona **Use a new app signing key** (esto requiere lanzamientos duales continuos).
4. Elige usar la misma app signing key que otra aplicación en tu cuenta de desarrollador, o sube una nueva app signing key desde Android Studio, Java KeyStore u otro repositorio.
5. Sigue las instrucciones en pantalla, descarga y ejecuta la herramienta **PEPK**.
6. Cuando tu archivo ZIP esté listo, haz clic en **Upload generated ZIP** y súbelo a Play Console.
7. Junto a "5. Allow the new key to be trusted on Android devices by uploading proof-of-rotation", haz clic en **Show instructions**.
8. Descarga [APKSinger](https://developer.android.com/studio/command-line/apksigner) y genera la prueba de rotación ejecutando este comando:

   ```bash
   apksigner rotate --out /path/to/new/file --old-signer --ks old-signer-jks --set-rollback true --new-signer --ks new-signer-jks --set-rollback true
   ```

9. Haz clic en **Upload generated proof-of-rotation file** y sube el archivo de prueba de rotación generado en el paso 8.
10. Haz clic en **Save**.

## Create an upload key and update keystores

Para mayor seguridad, se recomienda firmar tu aplicación con una nueva upload key en lugar de tu app signing key.

Puedes crear una upload key cuando te inscribes en Play App Signing, o puedes crear una upload key más tarde visitando la página de [Play App Signing](https://play.google.com/console/developers/app/keymanagement) (**Test and release > Setup > App signing**).

### Cómo crear una upload key

1. Sigue las instrucciones en el [sitio de Android Developers](https://developer.android.com/studio/publish/app-signing#generate-key). Guarda tu clave en un lugar seguro.
2. Exporta el certificado para la upload key al formato PEM. Reemplaza los argumentos subrayados en el siguiente comando:

   ```bash
   keytool -export -rfc -keystore upload-keystore.jks -alias upload -file upload_certificate.pem
   ```

3. Cuando se te solicite durante el proceso de lanzamiento, sube el certificado para registrarlo con Google.

### When you use an upload key

- Tu upload key solo se registra con Google para autenticar la identidad del creador de la aplicación.
- La firma se elimina de los APKs subidos antes de ser enviados a los usuarios.

#### Upload key requirements

- Debe ser una clave RSA de al menos 2048 bits.

#### Update keystores

Después de crear una upload key, estas son algunas ubicaciones que podrías querer revisar y actualizar:

- Máquinas locales
- Servidores locales con acceso restringido (varios ACLs)
- Máquinas en la nube (varios ACLs)
- Servicios dedicados de gestión de secretos
- Repositorios (Git)

## Upgrade your app signing key

> **Nota:** Esta sección contiene instrucciones relacionadas con la actualización de tu app signing key. Si perdiste tu upload key, no necesitas solicitar una actualización de clave; consulta en su lugar la sección de [Lost or compromised upload key?](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en&visit_id=638673512252632764-2865339235&rd=1#lost) al final de esta página.

En algunas circunstancias, puedes solicitar una actualización de tu app signing key. A continuación, se presentan algunas razones para solicitar una actualización de clave de firma:

- Necesitas una clave criptográficamente más fuerte.
- Tu app signing key ha sido comprometida.

**Importante:** Las actualizaciones de clave solo están disponibles para aplicaciones que usan app bundles.

Antes de solicitar una actualización de clave en Play Console, lee la sección **[Important considerations before requesting a key upgrade](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en&visit_id=638673512252632764-2865339235&rd=1#upgrade_info)** a continuación. Luego, puedes expandir las demás secciones para aprender más sobre cómo solicitar una actualización de clave.

### Important considerations before requesting a key upgrade

Antes de solicitar una actualización de clave, es importante entender los cambios que podrías necesitar realizar una vez completada la actualización:

- Si usas la misma app signing key para múltiples aplicaciones que comparten datos/código entre ellas, necesitas actualizar tus aplicaciones para que reconozcan tanto el nuevo certificado de clave de firma como el certificado heredado. En dispositivos que ejecutan Android S (API nivel 32) o inferior, solo se reconoce el certificado de clave de firma heredado por la plataforma Android para el propósito de compartir datos/código.
- Si tu aplicación utiliza APIs, asegúrate de registrar los certificados de tu nueva clave y de la clave heredada con los proveedores de API antes de publicar una actualización para garantizar que las APIs sigan funcionando. Los certificados están disponibles en la página de [Play App Signing](https://play.google.com/console/developers/app/keymanagement) (Test and release > Setup > App signing) en Play Console.
- Si alguno de tus usuarios instala actualizaciones mediante compartición peer-to-peer, solo podrán instalar actualizaciones firmadas con la misma clave que la versión de tu aplicación que ya tienen instalada. Si no pueden actualizar su aplicación porque tienen una versión firmada con una clave diferente, tienen la opción de desinstalar y reinstalar la aplicación para obtener la actualización.

### Request a key upgrade for all installs on Android N (API level 24) and above

Cada aplicación puede tener su clave de firma de aplicación actualizada para todas las instalaciones en Android N (API nivel 24) y superior una vez al año.

Si solicita con éxito esta actualización de clave, su nueva clave se utiliza para firmar todas las instalaciones y actualizaciones de aplicaciones. En dispositivos que ejecutan Android T (nivel de API 33) y superior, la plataforma Android hace cumplir el uso de la clave actualizada. En dispositivos que ejecutan Android S (nivel de API 32) o inferior, la plataforma Android no aplica el uso de esta clave actualizada y aún reconoce la clave de firma heredada como la clave de firma de la aplicación. Esto también incluye cualquier característica de la plataforma Android (por ejemplo, el intercambio de permisos personalizados) que dependen de la clave de firma de la aplicación. En dispositivos que ejecutan Android N (nivel 24 de API) a Android S (nivel de API 32), Google Play Protect comprobará que las actualizaciones de la aplicación estén firmadas con su clave actualizada, a menos que el usuario las desacte. Esto proporciona una validación adicional, ya que la plataforma Android no impone el uso de la clave actualizada en dispositivos que ejecutan Android S (nivel de API 32) o inferior.

1. Abre Play Console y ve a la página de [Play App Signing](https://play.google.com/console/developers/app/keymanagement) (Test and release > Setup > App signing).
   - **Tip:** También puedes acceder a esta página a través de [App integrity](https://play.google.com/console/developers/app/app-integrity/overview) (**Test and release > App integrity**), que incluye [servicios de integridad y firma](https://support.google.com/googleplay/android-developer/answer/13857328) para asegurar que los usuarios experimenten tus aplicaciones y juegos como lo deseas.
2. En la tarjeta **Upgrade your app signing key**, selecciona **Request key upgrade**.
3. Selecciona una opción para actualizar tu app signing key para todas las instalaciones en Android N y superior.
4. Permite que Google genere una nueva app signing key (recomendado) o sube una propia.
   - Después de actualizar tu app signing key, si estabas utilizando la misma clave para firmar tu aplicación y como upload key, puedes seguir usando tu clave de firma heredada como tu upload key o generar una nueva upload key.
5. Selecciona una razón para solicitar la actualización de la clave de firma.
6. Si es necesario, registra tu nueva clave de firma con los proveedores de API.

> **Tip:** Si distribuyes tu aplicación en varios canales de distribución y deseas maximizar la compatibilidad de actualizaciones para tus usuarios, deberías actualizar tu clave en cada canal de distribución. Para ser compatible con la actualización de clave de Google Play, utiliza la herramienta **ApkSigner**, incluida en los [Android SDK Build Tools](https://developer.android.com/studio/command-line#tools-build) (versión 33.0.1+):

```bash
apksigner sign --in ${INPUT_APK}
--out ${OUTPUT_APK}
--ks ${ORIGINAL_KEYSTORE}
--ks-key-alias ${ORIGINAL_KEY_ALIAS}
--next-signer --ks ${UPGRADED_KEYSTORE}
--ks-key-alias ${UPGRADED_KEY_ALIAS}
--lineage ${LINEAGE}
```

Aprende más sobre cómo funcionan las [actualizaciones de la aplicación](https://developer.android.com/google/play/app-updates).

## Best practices

- Si también distribuyes tu aplicación fuera de Google Play o planeas hacerlo y deseas usar la misma clave de firma, tienes dos opciones:
  - Permitir que Google genere la clave (recomendado) y luego descargar un APK universal firmado desde el [App bundle explorer](https://play.google.com/console/developers/app/bundle-explorer) para distribuir fuera de Google Play.
  - Generar la clave de firma que deseas usar para todas las tiendas de aplicaciones y luego transferir una copia a Google cuando configures Play App Signing.
- Para proteger tu cuenta, activa la [verificación en dos pasos](https://www.google.com/landing/2step/) para las cuentas con acceso a Play Console.
- Después de publicar un app bundle en una pista de lanzamiento, puedes visitar el [App bundle explorer](https://play.google.com/console/developers/app/bundle-explorer) para acceder a los APKs instalables que Google genera a partir de tu app bundle. Puedes:

  - Copiar y compartir un [enlace interno para compartir](https://support.google.com/googleplay/android-developer/answer/9844679) la aplicación, lo que te permite probar en una sola aplicación, el tipo de aplicación que Google Play instalaría desde tu app bundle en diferentes dispositivos.
  - Descargar un APK universal firmado. Este APK único está firmado con la app signing key que Google maneja y se puede instalar en cualquier dispositivo que tu aplicación soporte.
  - Descargar un archivo ZIP con todos los APKs para un dispositivo específico. Estos APKs están firmados con la app signing key que Google maneja. Puedes instalar los APKs del archivo ZIP en un dispositivo usando el comando:

  ```bash
  adb install-multiple *.apk
  ```

- Para mayor seguridad, genera una nueva upload key que sea diferente de tu app signing key.
- Si estás utilizando cualquier API de Google, puede que necesites registrar la upload key y la app signing key en la [Google Cloud Console](https://console.developers.google.com/) para tu aplicación.
- Si estás utilizando [Android App Links](https://developer.android.com/training/app-links#android-app-links), asegúrate de actualizar las claves en el archivo correspondiente de [Digital Asset Links JSON](https://developer.android.com/training/app-links/verify-android-applinks) en tu sitio web.

## Lost or compromised upload key?

Si has perdido tu upload key privada o ha sido comprometida, puedes [crear una nueva](https://support.google.com/googleplay/android-developer/answer/9842756#create). El propietario de la cuenta de desarrollador puede iniciar un reinicio de clave en Play Console.

Después de que el equipo de soporte registre la nueva upload key, el propietario de la cuenta y los administradores globales recibirán un mensaje en la bandeja de entrada y un correo electrónico con más información. Luego, podrás actualizar tus keystores y registrar tu clave con los proveedores de API.

El propietario de la cuenta también puede cancelar la solicitud de reinicio en Play Console.

**Importante:** Restablecer tu upload key no afecta la app signing key que utiliza Google Play para volver a firmar los APKs antes de entregarlos a los usuarios.

## APK Signature Scheme v4

Los dispositivos con Android 11 y superior soportan el nuevo [APK signature scheme v4](https://source.android.com/security/apksigning/v4). Play App Signing utiliza la firma v4 para aplicaciones elegibles con el fin de permitirles acceder a funciones de distribución optimizadas disponibles en dispositivos más recientes. No se requiere ninguna acción por parte del desarrollador y no se espera que haya un impacto en los usuarios debido a la firma v4.

## Related content

- Aprende sobre los [integrity and signing services en Play Console](https://play.google.com/console/about/app-integrity/).
- Aprende sobre los [integrity and signing services en el sitio de desarrolladores de Android](https://developer.android.com/google/play/integrity).
