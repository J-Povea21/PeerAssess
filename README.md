# 📌 Proyecto Seleccionado: Peer Assessment App

## 🎯 Resumen del Proyecto

Como equipo, hemos decidido elegir el desarrollo de este **Peer Assessment App** como nuestro proyecto principal. La propuesta base fue tomada de Verónica Ospina, y decidimos adicionar algunos elementos extra tomados de las otras propuestas para hacer un proyecto más robusto.
Entre las funcionalidades principales está la creación de cursos, la importación de grupos de trabajo por medio de un CSV, la asignación de evaluaciones, y la retroalimentación con analíticas (con vistas por actividad, por estudiante, y por grupo). 

Figma: https://www.figma.com/design/N6kajiJicDVZDNC8lQWPrG/PeerAssess---Prototipo-App-Evaluacion-Colaborativa?node-id=0-1&t=XqA6N9jAGDJbAaz7-1

Prototipo: https://www.figma.com/proto/N6kajiJicDVZDNC8lQWPrG/PeerAssess---Prototipo-App-Evaluacion-Colaborativa?node-id=0-1&t=QYV8tAk726wk74yV-1

Fotos:
![](https://i.imgur.com/og4khDI.png)
![](https://i.imgur.com/mcAe9EG.png)
![](https://i.imgur.com/Upcj7CD.png)


Videos de demostración:
1. Demo de gestión académica: https://youtu.be/zvnyz1B5LCM
2. Demo de evaluación y reportes: https://youtu.be/XBMUnI1a-hU
3. Pruebas widget: https://youtu.be/poTUsrXJ07A
4. Pruebas de integración: https://youtu.be/snNXyWDca_8
5. Implementación de caché: https://youtu.be/ucryIt6Qsyw
6. Revisión del código: https://youtu.be/ZeJmbkAozxg?si=0I-oneiGoLIZLdKV

---

## 1. Introducción

A lo largo de nuestra vida universitaria, nos hemos podido dar cuenta que cuando hay actividades colaborativas, uno de los principales retos es garantizar una evaluación justa y transparente del desempeño individual dentro de los equipos de trabajo. A veces los integrantes de los equipos no se esfuerzan por igual ni dedican la misma cantidad de tiempo para resolver las actividades, y por eso, una plataforma que facilite el peer evaluation resulta muy conveniente, tanto para los estudiantes, como para el monitoreo del profesor. 

Actualmente, los grupos se crean en Brightspace y los profesores activan actividades colaborativas, pero no existe una herramienta especializada que permita evaluar sistemáticamente el desempeño individual dentro de los grupos bajo criterios estructurados.

Este proyecto propone el desarrollo de una aplicación móvil en Flutter que permita el peer assessment, integrándose con grupos importados desde Brightspace, y cumpliendo los lineamientos técnicos establecidos (Clean Architecture, GetX, Roble para autenticación y almacenamiento, permisos de ubicación y background).

---
# 2. Referentes Analizados
Tomamos como ejemplo tres plataformas que existen en el mercado actualmente y están relacionados a la problemática.

## 2.1 Peergrade
- Plataforma especializada en evaluación entre pares.
- Permite rúbricas estructuradas.
- Resultados pueden ser públicos o privados.
- Fuerte enfoque pedagógico.

Limitaciones:
- No se integra directamente con Learning Management Systems (LMS) institucionales como Brightspace.
- No está optimizada para evaluación móvil por curso importado.

## 2.2 Moodle Workshop Module
- Herramienta de evaluación entre pares dentro del LMS Moodle.
- Permite múltiples fases (envío, evaluación, cálculo de notas).
- Rúbricas configurables.

Limitaciones:
- Flujo complejo.
- Poco intuitivo en dispositivos móviles.
- No está diseñado específicamente para evaluación interna de equipos pequeños.

## 2.3 Google Forms + Hojas de cálculo
- Solución improvisada usada por muchos profesores.
- Fácil de implementar.
- Flexible en diseño de rúbricas.

Limitaciones:
- No garantiza anonimato real.
- No automatiza análisis por grupo.
- No permite estadísticas avanzadas por curso, grupo y estudiante.
- No controla ventana de tiempo ni visibilidad.

---


---

# 3. Composición y Diseño de la Solución

## 3.1 Tipo de Aplicación

Mi propuesta consiste en una sola aplicación móvil con manejo de roles (Profesor / Estudiante).

Justificación:
- Simplifica mantenimiento.
- Reduce duplicación de código.
- Facilita la gestión de autenticación.
- Permite navegación condicional según rol.

## 3.2 Arquitectura Propuesta

La aplicación seguirá Clean Architecture con separación en:

### Presentation Layer
- UI en Flutter.
- GetX para state management, navegación e inyección de dependencias.
- Controladores por módulo.

### Domain Layer
- Entidades: User, Course, GroupCategory, Group, Assessment, Evaluation, Criteria.
- Casos de uso: CreateAssessment, SubmitEvaluation, CalculateGroupAverage, CalculateStudentAverage, ImportGroups, JoinCourse.

### Data Layer
- Servicios Roble para autenticación y base de datos.
- Repositorios específicos por módulo.

---

## 👥 Roles del Sistema

### 👨‍🏫 Profesor

* Crear cursos.
* Invitar estudiantes mediante código privado.
* Importar grupos desde Brightspace.
* Crear evaluaciones.
* Visualizar métricas avanzadas.

### 👨‍🎓 Estudiante

* Unirse a cursos mediante código.
* Visualizar grupos.
* Evaluar compañeros (sin autoevaluación).
* Consultar resultados (si son públicos).

---
# 4. Flujo Funcional Detallado

## 4.1 Registro y Autenticación
1. Usuario abre la app.
2. Inicia sesión mediante Roble.
3. El sistema detecta el rol.
4. Se redirige al dashboard correspondiente.

## 4.2 Gestión de Cursos
Profesor:
- Crea curso.
- Invita estudiantes mediante código privado.
- Importa grupos desde Brightspace.

Estudiante:
- Ingresa código de invitación.
- Se une al curso.
- Visualiza sus grupos.

## 4.3 Creación de Evaluación
1. Profesor selecciona curso.
2. Selecciona categoría.
3. Define nombre, ventana de tiempo y visibilidad.
4. Activa evaluación.

## 4.4 Evaluación entre Pares
1. Estudiante recibe notificación.
2. Evalúa a cada compañero (sin autoevaluación).
3. Califica según criterios:
   - Punctuality
   - Contributions
   - Commitment
   - Attitude
4. Envía evaluación.

## 4.5 Cálculo Automático
El sistema calcula:
- Promedio por estudiante.
- Promedio por grupo.
- Promedio por actividad.
- Promedio global por curso.

## 4.6 Visualización de Resultados
Si es pública:
- Estudiantes ven criterios y promedio general.

Si es privada:
- Solo el profesor ve resultados detallados.

---

# 🚀 5. Funcionalidades Diferenciadoras

Decidí incorporar ciertas funcionalidades adicionales que me parece que pueden favorecer el análisis de métricas para el profesor.
## 5.1 Índice de Equidad del Grupo

La aplicación calculará automáticamente un “Índice de Equidad”, que mide la desviación estándar entre los puntajes de los miembros del grupo.  
Esto permite identificar rápidamente grupos con desequilibrios de participación.

## 5.2 Detección de Evaluaciones Anómalas

El sistema identificará patrones como:
- Un estudiante que califica extremadamente bajo a todos.
- Evaluaciones significativamente diferentes al promedio del grupo.

Esto ayuda al docente a detectar posibles sesgos o conflictos internos.

## 5.3 Panel Analítico Avanzado (Dashboard Inteligente)

El docente podrá visualizar:
- Gráficos comparativos entre grupos.
- Evolución del desempeño a lo largo del semestre.
- Ranking de mejora individual.

## 5.4 Retroalimentación Automática Generada

Basado en los puntajes obtenidos, el sistema podrá generar un breve resumen automático de desempeño para cada estudiante (ej: “Demuestra alto compromiso pero puede mejorar su puntualidad”).

## 5.5 Modo Reflexión Post-Evaluación

Después de ver resultados, el estudiante podrá completar una breve auto-reflexión voluntaria, fomentando metacognición y mejora continua.
---

# 📚 6. Justificación Académica

Teniendo en cuenta los referentes iniciales, este proyecto adopta una estructura clara de rúbrica (Peergrade), también adopta el cálculo automatizado por fases (Moodle), y conserva la simplicidad de uso (Google Forms).

Basándonos en las entrevistas a docentes, nos dimos cuenta que existe una necesidad de evaluación individual justa, se requiere de una reducción de carga administrativa, se necesita transparencia y anonimato, es importante la automatización de cálculos, y además, existe un gran interés en herramientas analíticas para detectar problemas en grupos.

Las funcionalidades de valor agregado responden directamente a la necesidad de análisis profundo y apoyo en toma de decisiones pedagógicas.

---
# 7. Cumplimiento Técnico

✔ Clean Architecture  
✔ GetX  
✔ Roble para autenticación y almacenamiento  
✔ Permisos solicitados  
✔ Importación desde Brightspace  
✔ Módulo analítico adicional implementado en capa Domain  

---

# 🏁 8. Conclusión

La aplicación no solo cumple con los requerimientos funcionales establecidos, sino que incorpora herramientas analíticas e inteligentes que fortalecen la evaluación formativa.

Esto posiciona la solución como una plataforma más robusta, moderna y orientada a la toma de decisiones basada en datos, diferenciándola claramente de propuestas tradicionales.
