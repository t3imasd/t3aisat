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

- **Estilo:** Minimalista y moderno, siguiendo la paleta de colores
- **Color de los Íconos Principales:** Verde Oscuro (#388E3C)
- **Color de los Íconos Secundarios:** Gris Oscuro (#424242)

## Componentes y Pantallas

### 1. Pantalla Principal (Inicio)

- **Background:**
  - Color: Gris Claro (#E6E6E6)
- **Título:**
  - Texto: "T3 AI Sat"
  - Tipografía: Roboto, 28px, Negrita, Color: Azul Marino (#1976D2)
  - **Posicionamiento:** Centrar verticalmente todo el contenido en la pantalla para mejorar el balance visual.
  - **Sombra del Título:**
    - **Color:** #000000 (negro)
    - **Opacidad:** 20-25%
    - **Desenfoque:** 3-4px
    - **Desplazamiento:** 2px hacia abajo y 0px en el eje horizontal.
- **Botones:**
  - **"Foto con Ubicación" y "Mapa de Parcelas":**
    - Fondo: Verde Oscuro (#388E3C)
    - Texto: Blanco (#FFFFFF), Tipografía: Roboto, 18px, Semi-Negrita
    - **Padding interno:** 16px en todas direcciones
    - **Bordes Redondeados:** Radio de borde de 12px
    - **Sombra:** Elevación de 4dp con desenfoque sutil
    - **Efecto de Pulsación:** Ripple con Verde Oscuro más intenso (código de color automático de Flutter), con una animación más suave y ligeramente prolongada.
  - **Iconografía:** Posibilidad de añadir íconos pequeños a la izquierda del texto (opcional).
- **Espaciado:**
  - **Entre Título y Botones:** 60px
  - **Entre Botones:** 20px
  - **Alineación:** Alinear los botones horizontalmente y centrar en la pantalla para un balance visual óptimo.

### 2. Pantalla de la Cámara

- **No Cambios:** La interfaz de la cámara debe permanecer sin cambios, asegurando que se abra directamente al pulsar "Foto con Ubicación".

### 3. Cámara de Fotos (Interfaz de Cámara)

- **Apertura Directa:** La cámara se abre directamente al pulsar "Foto con Ubicación".
- **Cambios:** No se requiere cambio estético, pero asegúrate de que el flujo sea fluido y directo, sin pantallas intermedias innecesarias.

### 4. Pantalla de Confirmación de Foto

- **Background:** Gris Claro (#E6E6E6)
- **Visualización de la Foto:** Imagen a pantalla completa con opción para confirmarla.
- **Botones:**
  - **"Usar esta Foto":**
    - Fondo: Verde Oscuro (#388E3C)
    - Texto: Blanco (#FFFFFF), Tipografía: Roboto, 16px, Negrita
    - Posición: Fijo en la parte inferior con un padding de 12px.
  - **"Rehacer Foto":**
    - Texto: Azul Marino (#1976D2), Sin fondo, Tipografía: Roboto, 16px, Negrita
    - Posición: Fijo en la parte inferior izquierda, con un padding de 12px.

### 5. Pantalla de Foto con Ubicación

- **Background:** Gris Claro (#E6E6E6)
- **Título:**
  - Texto: "GeoPosición"
  - Tipografía: Roboto, 24px, Negrita, Color: Azul Marino (#1976D2)
- **Imagen Geolocalizada:**
  - **Carga de la Imagen:** Añadir un **spinner de carga** con color Azul Marino (#1976D2) mientras se procesa la imagen y se generan los datos de geolocalización.
- **Texto de Ubicación y Dirección:**
  - Color: Gris Oscuro (#424242)
  - Tipografía: Roboto, 16px, Regular
  - **Íconos de Latitud/Longitud y Dirección:**
    - **Latitud y Longitud:** Ícono de ubicación (un pin) en Verde Oscuro (#388E3C) antes de los valores de latitud y longitud.
    - **Dirección:** Ícono de dirección (una casa) en Verde Oscuro (#388E3C) antes de la dirección textual.
    - **Alineación:** Los íconos están alineados a la izquierda del texto. El texto y los íconos se mantienen alineados en una línea vertical para evitar desajustes visuales.

#### Formato de la Información Geolocalizada en la Imagen

- **Formato del Texto en la Imagen:**

  ```text
  Network: [dd mmm yyyy hh:mm ZZZ]
  Local: [dd mmm yyyy hh:mm ZZZ]
  [Latitud DMS] [Longitud DMS]
  [Calle con número]
  [Código postal y Localidad]
  [Provincia]
  ```

- **Ejemplo en la Imagen:**

  ```text
  Network: 3 oct 2024 9:14:14 CEST
  Local: 3 oct 2024 9:14:13 CEST
  38°1 22,83"N 1°14 59,22"W
  12 Calle Venezuela
  30565 Las Torres de Cotillas
  Región de Murcia
  ```

- **Especificaciones del Formato:**
  - **Tipografía:**
    - Fuente: Roboto, Regular
    - Tamaño: 14px
    - Color: Gris Oscuro (#424242)
  - **Alineación:** Justificado a la izquierda.
  - **Espaciado:** Asegurar que el espaciado entre cada línea sea uniforme y balanceado para una correcta visualización.

##### Detalles

1. **Network y Local (Fecha y Hora):**

   - El formato de fecha y hora para "Network" y "Local" es:

     - **Fecha:** `dd mmm yyyy`
     - **Hora:** `hh:mm:ss ZZZ` (zona horaria abreviada).
     - Ejemplo:

       ```text
       Network: 3 oct 2024 9:14:14 CEST
       Local: 3 oct 2024 9:14:13 CEST
       ```

2. **Coordenadas (Latitud y Longitud en DMS):**

   - Mostrar las coordenadas en formato de grados, minutos y segundos (DMS), con dos decimales de precisión en los segundos.
   - Ejemplo:

     ```text
     38°1 22,83"N 1°14 59,22"W
     ```

3. **Dirección (Calle, Código Postal, Localidad y Provincia):**

   - La dirección se presenta en tres líneas:
     1. La primera línea con la **calle y número**.
     2. La segunda línea con el **código postal** y la **localidad**.
     3. La tercera línea con la **provincia**.
   - Ejemplo:

     ```text
     12 Calle Venezuela
     30565 Las Torres de Cotillas
     Región de Murcia
     ```

##### Comportamiento

- Validar que este texto se coloque correctamente sobre la imagen geolocalizada.
- Mantener la legibilidad del texto bajo diferentes condiciones de luz y tamaños de pantalla.

### 6. Pantalla Mapa de Parcelas

- **Background:** Gris Claro (#E6E6E6)
- **Título:**
  - Texto: "Mapa Parcelas"
  - Tipografía: Roboto, 24px, Negrita, Color: Azul Marino (#1976D2).
- **Mapa:**
  - **Líneas de Parcelas:** Las líneas de las parcelas están delineadas en rojo (#D32F2F) para mayor visibilidad.
  - **Área de Parcelas:**
    - **Color de Texto:** Negro (#000000) para el área en m².
    - **Fuente:** Roboto, **14px**, Regular.
    - **Espaciado:** Asegurar un espacio de 4px entre el texto del área y los bordes de la parcela para evitar solapamientos.
- **Selección de Parcela:**
  - Color de Resaltado: Naranja Tierra (#F57C00) para el borde de la parcela seleccionada.
  - **Detalles de la Parcela Seleccionada:**
    - Mostrar un resumen en un "Bottom Sheet" al seleccionar una parcela.
    - **Texto Principal (Área):** Color: Negro (#000000), Fuente: Roboto, 24px, Negrita.
    - **Texto Secundario (Registro Catastral):** Color: Gris Oscuro (#424242), Fuente: Roboto, 16px, Regular.
    - **Bottom Sheet:** Fondo Blanco (#FFFFFF) con sombra sutil para destacarlo sobre el mapa.

### 6.1. Bottom Sheet (Cambios para Selección Múltiple)

#### 6.1.1. Modo Compacto (Vista Inicial)

- El `BottomSheet` debe mostrar la suma total del área de las parcelas seleccionadas.
- **Texto Principal (Área Total):**

  - Color: Negro (#000000)
  - Tipografía: Roboto, 24px, Negrita
  - Alineación: Centrada en la primera línea.
  - **Ejemplo de texto**:

    ```markdown
    **Área Total: 5000 m²**
    ```

- Si se selecciona **una sola parcela**, debajo del área se debe mostrar el registro catastral:

  ```markdown
  Reg. Catastral: 30038A00600251
  ```

- Si se seleccionan **múltiples parcelas**, mostrar un resumen de la cantidad de registros seleccionados:

  ```markdown
  Registros Catastrales: 3 seleccionados
  ```

- **Tipografía de los Registros:** Roboto, 14px, Regular, Color: Gris Oscuro (#424242)
- **Botón "Ver más detalles":** Cuando haya más de una parcela seleccionada, debe aparecer un botón que permita expandir el `BottomSheet`:
  - Texto: "Ver más detalles"
  - Fondo: Verde Oscuro (#388E3C)
  - Texto: Blanco (#FFFFFF), Roboto, 16px, Negrita
  - **Padding interno:** 16px en todas direcciones.
  - **Bordes redondeados:** 12px para coherencia con los botones de la app.

#### 6.1.2. Modo Expandido (Al Deslizar Hacia Arriba)

- **Lista Completa de Registros Catastrales**: Al expandir el `BottomSheet`, debe mostrarse la lista completa de los registros catastrales seleccionados. Cada número debe estar en una nueva línea, con un espacio vertical de **12px** entre cada registro para mejorar la legibilidad.

  - **Ejemplo de formato**:

    ```markdown
    Registros Catastrales:

    - 30038A00600251
    - 30038A00600252
    - 30038A00600253
    ```

- **Padding**: Asegurar un padding de **16px** en los laterales de los textos para evitar que el contenido esté alineado completamente a la izquierda y cumpla con las guidelines de Apple y Google.

#### 6.1.3. Comportamiento de Desplazamiento

- El `BottomSheet` debe tener comportamiento expandible y colapsable.
- **Altura inicial**: El `BottomSheet` debe ocupar el 20% de la pantalla cuando está en modo compacto.
- **Altura expandida**: Al expandir, debe ocupar un máximo del 50% de la pantalla en pantallas pequeñas y medianas, y hasta un 70% en pantallas grandes.

- **Redimensionamiento del mapa**: Al expandir el `BottomSheet`, el mapa debe ajustarse dinámicamente para seguir visible, recortándose pero manteniendo el centro del mapa visible en todo momento.

---

## Consideraciones Finales

- **Transiciones y Animaciones:** Implementar transiciones suaves de 300ms para expandir y colapsar el `BottomSheet`, y animaciones de ripple effect en los botones para mejorar la interactividad y dar feedback visual al usuario.
- **Feedback Visual:** Añadir microinteracciones al seleccionar parcelas, como un cambio en el color del borde de la parcela seleccionada (Naranja Tierra #F57C00).
- **Pruebas:** Asegurar que los cambios sean probados en dispositivos móviles y en **diferentes condiciones de luz**, como en exteriores, para validar la legibilidad del `BottomSheet` y del mapa bajo diferentes condiciones de iluminación. También asegurar que el `BottomSheet` sea responsivo y funcione bien en diferentes tamaños de pantalla.
