
# Propuesta de Aplicación – Victor

## 1. Descripción General

En la materia Desarrollo Móvil es frecuente la realización de proyectos grupales donde cada integrante debe aportar en el diseño, desarrollo e implementación de una aplicación. Sin embargo, uno de los principales problemas en este tipo de trabajos es la dificultad para medir la participación individual, organizar tareas técnicas y realizar una evaluación justa.

La presente propuesta plantea el desarrollo de una aplicación orientada a la gestión inteligente de trabajos colaborativos en asignaturas técnicas, especialmente en Desarrollo Móvil. La aplicación permitirá organizar equipos, distribuir tareas, hacer seguimiento del progreso individual y facilitar la evaluación docente basada en métricas objetivas.

El objetivo principal es mejorar la transparencia, la organización y la equidad en los proyectos grupales universitarios.

---

## 2. Referentes Analizados

### 2.1 Google Classroom

Google Classroom permite a los docentes asignar actividades, recibir entregas y publicar calificaciones. Es ampliamente utilizado en entornos académicos.

Fortalezas:
- Interfaz sencilla.
- Gestión clara de tareas y fechas límite.
- Integración con Google Drive.

Debilidades:
- No permite medir participación individual dentro de trabajos grupales.
- No está orientado a proyectos técnicos con control de avances detallado.

---

### 2.2 Trello

Trello es una herramienta de gestión de proyectos basada en tableros Kanban.

Fortalezas:
- Organización visual clara.
- Permite asignar tareas a miembros específicos.
- Seguimiento del progreso por etapas.

Debilidades:
- No está adaptado al contexto académico.
- No incluye herramientas de evaluación ni métricas docentes.

---

### 2.3 Microsoft Teams

Microsoft Teams permite comunicación, trabajo colaborativo y gestión de archivos.

Fortalezas:
- Comunicación integrada.
- Espacios de trabajo por equipos.
- Integración con herramientas externas.

Debilidades:
- Enfocado más en comunicación que en evaluación académica.
- No proporciona análisis detallado de desempeño individual en proyectos técnicos.

---

## 3. Arquitectura Propuesta

Se propone una arquitectura sencilla compuesta por:

- Una aplicación móvil principal.
- Un servidor con base de datos centralizada.

Justificación:

La aplicación móvil será utilizada tanto por estudiantes como por docentes, pero con diferentes permisos según el rol. De esta manera, se evita desarrollar múltiples plataformas y se simplifica el mantenimiento del sistema.

El servidor se encargará de almacenar la información relacionada con los proyectos, tareas, avances y calificaciones. Toda la información estará centralizada en una base de datos que permitirá consultar el historial de participación de cada estudiante.

Este enfoque es adecuado para un entorno universitario, ya que mantiene la solución simple, funcional y fácil de implementar dentro del contexto de la materia Desarrollo Móvil, sin añadir complejidad innecesaria.


## 4. Flujo Funcional

1. El docente crea una actividad grupal dentro de la aplicación.
2. Publica la descripción del proyecto, los objetivos y la fecha de entrega.
3. Los estudiantes se registran en la actividad y conforman los equipos.
4. Cada equipo divide el proyecto en tareas internas dentro de la app.
5. Los integrantes marcan el estado de sus tareas (pendiente, en proceso, finalizada).
6. Los estudiantes pueden subir evidencias como capturas, enlaces al repositorio o comentarios técnicos.
7. La aplicación registra automáticamente quién realizó cada actualización.
8. Al finalizar el proyecto, el docente revisa el historial de actividad del grupo.
9. Se asigna la calificación teniendo en cuenta tanto el resultado final como la participación registrada.
10. Los estudiantes reciben la nota junto con una breve retroalimentación visible en la aplicación.


## 5. Justificación de la Propuesta

En la materia Desarrollo Móvil, los proyectos grupales son una parte fundamental del aprendizaje. Sin embargo, en muchas ocasiones la evaluación se centra únicamente en el producto final, sin tener en cuenta cómo fue el proceso de trabajo ni el nivel de participación de cada integrante.

Esta propuesta surge como respuesta a esa necesidad. Más que una herramienta de organización, la aplicación busca apoyar al docente en el seguimiento del proceso y brindar mayor claridad sobre el aporte individual dentro del equipo.

A diferencia de herramientas generales como Google Classroom o Trello, esta solución está pensada específicamente para proyectos técnicos universitarios, donde es importante registrar avances, evidencias y participación continua.

El objetivo no es reemplazar plataformas existentes, sino complementar el proceso académico con una herramienta enfocada en la transparencia, la responsabilidad individual y una evaluación más justa.

## 6. Prototipo

El prototipo fue diseñado en Figma con el objetivo de representar el flujo principal de la aplicación y las funcionalidades básicas para docentes y estudiantes.

Prototipo en Figma:
(Aquí debes pegar el enlace)

Capturas principales del prototipo:

https://www.figma.com/design/JjmbEb3wWiwASTTv9pSytb/EDU-educational-application-ui-kit--FREE---Community-?node-id=0-1&t=Ii7L1A36TLjHe49J-1
el prototipo es muy simple para la idea se puede desarrollar de la mejor manera posible

