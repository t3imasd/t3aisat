# Características de la aplicación T3 AI SAT

## 1. Introducción

Esta aplicación principalmente tiene 2 funcionalidades:

1. Validación de la geolocalización de una foto o un vídeo.
2. Dibujar las parcelas catastrales de fincas urbanas y rústicas.

## 2. Validación de la geolocalización de una foto o un vídeo

Este funcionalidad tiene una cámara para poder hacer fotos o vídeos. Cuando se hace una foto o un vídeo se le escribe la fecha y hora, las coordenadas de latitud y longitud y la dirección en la que se ha hecho la foto o el vídeo. También, añade estos fotos y vídeos en la galería de fotos del teléfono móvil. Además, se le incrustan estos metadatos en los archivos de fotos y vídeos.

Las coordenadas se obtienen de la geolocalización del teléfono móvil, y la dirección se obtiene en base a las coordenadas de latitud y longitud que suministra el teléfono móvil.

La dirección se obtiene de la API Mapbox en base a las coordenadas de latitud y longitud obtenidas del teléfono móvil. Las coordenadas de latitud y longitud se envían de forma anónima a la API Mapbox únicamente para obtener la dirección en texto.

## 3. Dibujar las parcelas catastrales de fincas urbanas y rústicas

En un mapa con vista satélite de Mapbox se muestra un círculo azul con la geolocalización del usuario. Esta geoposición se obtiene de la geolocalización del teléfono móvil.

En el mapa vista satélite se dibujan las parcelas catastrales de fincas urbanas y rústicas con los datos obtenidos del Catastro, que incluyen el registro catastral y los metros cuadrados de la parcela. Esta información y líneas se obtienen de la API del Catastro de forma anónima. Solamente se envía la coordenadas de latitud y longitud de la geolocalización del usuario para obtener las parcelas catastrales, de forma anónima.

El usuario puede seleccionar parcelas para obtener el número del registro catastral y los metros cuadrados de la parcela. Además, puede copiar estos datos para poder pegarlos en otra aplicación.

## 4. Datos personales

No se usa ningún tipo de cookies ni se almacenan datos personales en la aplicación.

No se envían datos personales a terceros.

## Descargo de responsabilidad

La aplicación T3 AI SAT no se hace responsable de la exactitud de los datos obtenidos de la API del Catastro y de la API Mapbox.

La aplicación T3 AI SAT no se hace responsable de la exactitud de los datos obtenidos de la geolocalización del teléfono móvil.

## 5. Contacto

- [info@t3imasd.eu](mailto:info@t3imasd.eu)
