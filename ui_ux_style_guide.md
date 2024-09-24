# Guía de Estilos para la App "T3 AI SAT"

## Paleta de Colores

- **Verde Oscuro:** #388E3C
- **Azul Marino:** #1976D2
- **Cian Claro:** #81D4FA
- **Naranja Tierra:** #F57C00
- **Gris Claro:** #E0E0E0
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
- **Color de los Íconos Principales:** Verde Oscuro (#388E3C) o Azul Marino (#1976D2) dependiendo del contexto.
- **Color de los Íconos Secundarios:** Gris Oscuro (#424242).

## Componentes y Pantallas

### 1. Pantalla Principal (Inicio)

- **Background:**
  - Color: Gris Claro (#E0E0E0).
- **Título:**
  - Texto: "T3 AI Sat"
  - Tipografía: Roboto, 28px, Negrita, Color: Azul Marino (#1976D2).
  - **Posicionamiento:** Centrar verticalmente todo el contenido en la pantalla para mejorar el balance visual.
- **Botones:**
  - **"Foto con Ubicación" y "Mapa de Parcelas":**
    - Fondo: Verde Oscuro (#388E3C).
    - Texto: Blanco (#FFFFFF), Tipografía: Roboto, 18px, Semi-Negrita.
    - Borde: Sin borde.
    - Sombra: Sombra sutil, pero ligeramente intensificada para dar más profundidad visual. Usa un `elevation` de 2-4dp en Flutter.
    - Padding interno de 12px en cada dirección y un espaciado entre los botones de 20px.
  - **Efecto de Pulsación:** Ripple con Verde Oscuro más intenso (código de color automático de Flutter).
- **Espaciado:**
  - Aumentar el espacio entre el título y el primer botón a 40-50px para mejorar la separación y claridad visual.
  - Alinear horizontalmente los botones y mantener un espaciado uniforme.

### 2. Pantalla "Hacer Foto" (ELIMINADA)

- **Eliminación Completa:**
  - **Cambios:** Al pulsar "Foto con Ubicación" en la pantalla principal, abrir directamente la cámara nativa del dispositivo.
  - **Justificación:** Mejora de la fluidez y eficiencia en la experiencia del usuario.

### 3. Cámara de Fotos (Interfaz de Cámara)

- **Apertura Directa:** Al pulsar "Foto con Ubicación", se abrirá directamente la interfaz de la cámara del dispositivo.
- **Cambios:** Ningún cambio estético, pero asegúrate de que el flujo sea fluido y directo, sin pantallas intermedias innecesarias.

### 4. Pantalla de Confirmación de Foto (nueva)

- **Background:**
  - Color: Gris Claro (#E0E0E0).
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

### 5. Pantalla de GeoPosición (Pantalla de Foto con Ubicación)

- **Background:**
  - Color: Gris Claro (#E0E0E0).
- **Título:**
  - Texto: "GeoPosición"
  - Tipografía: Roboto, 24px, Negrita, Color: Verde Oscuro (#388E3C).
- **Imagen Geolocalizada:**
  - Tamaño: Mantener tamaño actual.
  - Borde de la Imagen: Ninguno, imagen mostrada en formato actual.
- **Texto de Ubicación y Dirección:**
  - Color: Gris Oscuro (#424242).
  - Tipografía: Roboto, 16px, Regular.
- **Botón "Hacer Foto":**
  - Color de Fondo: Azul Marino (#1976D2).
  - Texto: Blanco (#FFFFFF), Tipografía: Roboto, 16px, Negrita.
  - Posición: Centrado debajo de la imagen, con un margen superior de 20px.

### 6. Pantalla Mapa de Parcelas

- **Background:**
  - Color: Gris Claro (#E0E0E0).
- **Título:**
  - Texto: "Mapa Parcelas"
  - Tipografía: Roboto, 24px, Negrita, Color: Azul Marino (#1976D2).
- **Mapa:**
  - Colores Predominantes: Mantener el diseño actual del mapa.
  - Líneas de Parcelas: Rojo (#D32F2F).
- **Selección de Parcela:**
  - Color de Resaltado: Naranja Tierra (#F57C00) para el borde de la parcela seleccionada.
  - Efecto: Aumentar la opacidad del borde resaltado para mayor visibilidad.

### 7. Pantalla con Bottom Sheet

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

### 8. Pantalla de la Cámara

- **No Cambios:** La interfaz de la cámara debe permanecer sin cambios, asegurando que se abra directamente al pulsar "Foto con Ubicación".

---

## Consideraciones Finales

- **Transiciones y Animaciones:** Utilizar transiciones suaves entre pantallas, y animaciones de ripple en los botones para mejorar la interactividad y dar feedback visual al usuario.
- **Pruebas:** Asegurar que todos los cambios se prueben en condiciones reales, incluyendo trabajo en exteriores, para validar la visibilidad y usabilidad de la aplicación en entornos agrícolas.
