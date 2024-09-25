# Guía de Estilos para la App "T3 AI SAT"

## Paleta de Colores

- **Verde Oscuro:** #388E3C
- **Azul Marino:** #1976D2
- **Cian Claro:** #81D4FA
- **Naranja Tierra:** #F57C00
- **Gris Claro:** #E6E6E6
- **Gris Oscuro:** #424242
- **Blanco:** #FFFFFF

## Tipografía

- **Fuente Principal:** Roboto
- **Títulos (Primarios):** 28px, Negrita, Color: Azul Marino (#1976D2)
- **Subtítulos y Botones:** 18px, Semi-Negrita, Color: Azul Marino (#1976D2) o Naranja Tierra (#F57C00) según contexto
- **Texto Normal:** 16px, Regular, Color: Gris Oscuro (#424242)
- **Información Secundaria/Etiquetas:** 14px, Regular, Color: Gris Medio (#757575)
- **Texto en Botones Principales:** 16px, Negrita, Color: Blanco (#FFFFFF)

## Iconografía

- **Estilo:** Minimalista y moderno, siguiendo la paleta de colores.
- **Color de los Íconos Principales:** Verde Oscuro (#388E3C).
- **Color de los Íconos Secundarios:** Gris Oscuro (#424242).

## Componentes y Pantallas

### 1. Pantalla Principal (Inicio)

- **Background:**
  - Color: Gris Claro (#E6E6E6).
- **Título:**
  - Texto: "T3 AI Sat"
  - Tipografía: Roboto, 28px, Negrita, Color: Azul Marino (#1976D2).
  - **Posicionamiento:** Centrar verticalmente todo el contenido en la pantalla para mejorar el balance visual.
- **Botones:**
  - **"Foto con Ubicación" y "Mapa de Parcelas":**
    - Fondo: Verde Oscuro (#388E3C).
    - Texto: Blanco (#FFFFFF), Tipografía: Roboto, 18px, Semi-Negrita.
    - Borde: Sin borde.
    - Sombra: Sombra sutil pero ligeramente intensificada para dar más profundidad visual. Usa un `elevation` de 2-4dp en Flutter.
    - Padding interno de 12px en cada dirección y un espaciado entre los botones de 20px.
  - **Efecto de Pulsación:** Ripple con Verde Oscuro más intenso (código de color automático de Flutter).
- **Espaciado:**
  - Aumentar el espacio entre el título y el primer botón a 40-50px para mejorar la separación y claridad visual.
  - Alinear horizontalmente los botones y mantener un espaciado uniforme.

### 2. Cámara de Fotos (Interfaz de Cámara)

- **Apertura Directa:** Al pulsar "Foto con Ubicación", se abrirá directamente la interfaz de la cámara del dispositivo.
- **Cambios:** No se requiere cambio estético, pero asegúrate de que el flujo sea fluido y directo, sin pantallas intermedias innecesarias.

### 3. Pantalla de Confirmación de Foto (nueva)

- **Background:**
  - Color: Gris Claro (#E6E6E6).
- **Visualización de la Foto:**
  - Imagen a pantalla completa con la opción de confirmarla.
- **Botones:**
  - **"Usar esta Foto":**
    - Fondo: Verde Oscuro (#388E3C).
    - Texto: Blanco (#FFFFFF), Tipografía: Roboto, 16px, Negrita.
    - Posición: Fijo en la parte inferior con un padding de 12px.
  - **"Rehacer Foto":**
    - Texto: Azul Marino (#1976D2), Sin fondo, Tipografía: Roboto, 16px, Negrita.
    - Posición: Fijo en la parte inferior izquierda, con un padding de 12px.

### 4. Pantalla de GeoPosición (Pantalla de Foto con Ubicación)

- **Background:**
  - Color: Gris Claro (#E6E6E6).
- **Título:**
  - Texto: "GeoPosición"
  - Tipografía: Roboto, 24px, Negrita, Color: Azul Marino (#1976D2).
- **Imagen Geolocalizada:**
  - **Eliminación del Botón "Hacer Foto":** Este botón ya no será necesario, por lo que se debe eliminar de la pantalla.
  - **Ajuste de Diseño:** Alinear la imagen geolocalizada y la información asociada para ocupar más espacio vertical, dado que el botón ya no estará presente.
  - **Carga de la Imagen:** Añadir un **spinner de carga** con color Azul Marino (#1976D2) mientras se procesa la imagen y se generan los datos de geolocalización.
- **Texto de Ubicación y Dirección:**
  - Color: Gris Oscuro (#424242).
  - Tipografía: Roboto, 16px, Regular.
  - **Posicionamiento:** Centrarse en la pantalla, con mayor espacio entre la imagen geolocalizada y la información textual para una lectura más clara.
  - **Incorporación de Íconos:**
    - **Latitud y Longitud:** Añadir un ícono de ubicación (un pin) en Verde Oscuro (#388E3C) antes de los valores de latitud y longitud.
    - **Dirección:** Añadir un ícono de dirección (una casa) en Verde Oscuro (#388E3C) antes de la dirección textual.
    - **Alineación:** Los íconos deben estar alineados a la izquierda del texto, con un pequeño margen de 8px entre el ícono y el texto.

### 5. Pantalla Mapa de Parcelas

- **Background:**
  - Color: Gris Claro (#E6E6E6).
- **Título:**
  - Texto: "Mapa Parcelas"
  - Tipografía: Roboto, 24px, Negrita, Color: Azul Marino (#1976D2).
- **Mapa:**
  - Colores Predominantes: Mantener el diseño actual del mapa.
  - Líneas de Parcelas: Rojo (#D32F2F).
- **Selección de Parcela:**
  - Color de Resaltado: Naranja Tierra (#F57C00) para el borde de la parcela seleccionada.
  - Efecto: Aumentar la opacidad del borde resaltado para mayor visibilidad.

### 6. Pantalla con Bottom Sheet

- **Bottom Sheet:**
  - Color de Fondo: Blanco (#FFFFFF).
  - **Texto Principal (Área de la Parcela):**
    - Color: Verde Oscuro (#388E3C).
    - Tipografía: Roboto, 24px, Negrita.
    - Alineación: Centrada en la primera línea.
  - **Texto Secundario (Registro Catastral):**
    - Color: Gris Oscuro (#424242).
    - Tipografía: Roboto, 16px, Regular.
    - Alineación: Centrada en la segunda línea.
  - Sombra: Sombra sutil alrededor del bottom sheet para destacarlo sobre el mapa.

### 7. Pantalla de la Cámara

- **No Cambios:** La interfaz de la cámara debe permanecer sin cambios, asegurando que se abra directamente al pulsar "Foto con Ubicación".

---

## Consideraciones Finales

- **Transiciones y Animaciones:** Utilizar transiciones suaves entre pantallas, y animaciones de ripple en los botones para mejorar la interactividad y dar feedback visual al usuario.
- **Pruebas:** Asegurar que todos los cambios se prueben en condiciones reales, incluyendo trabajo en exteriores, para validar la visibilidad y usabilidad de la aplicación en entornos agrícolas.
