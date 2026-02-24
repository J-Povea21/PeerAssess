# Aplicación de Gestión de Trabajos Colaborativos – Desarrollo Móvil

## 1. Descripción General

En la asignatura **Desarrollo Móvil**, los proyectos grupales son una parte clave del aprendizaje. Sin embargo, suelen aparecer problemas como:
- Mala organización del equipo.
- Falta de control sobre quién hace qué.
- Dificultad para evaluar la participación individual.

Esta aplicación móvil permite que los docentes publiquen proyectos, que los estudiantes los vean, registren sus grupos y gestionen las tareas internas. La idea es simplificar la gestión de proyectos y hacer más transparente la evaluación.

---

## 2. Herramientas Analizadas

### Google Classroom
- **Fortalezas:**
  - Publicación de trabajos y fechas de entrega.
  - Interfaz sencilla.
  - Centraliza la información.
- **Debilidades:**
  - No permite seguimiento interno de grupos.
  - No organiza tareas dentro de un proyecto.

### Trello
- **Fortalezas:**
  - Organización visual mediante tableros.
  - División de tareas entre miembros.
  - Seguimiento de avances.
- **Debilidades:**
  - No está orientado a contexto académico.
  - No tiene control docente ni relación con calificaciones.

### Microsoft Teams
- **Fortalezas:**
  - Comunicación integrada entre estudiantes y docentes.
  - Integración con archivos y herramientas externas.
- **Debilidades:**
  - No enfocado en gestión de proyectos académicos.
  - No registra avances individuales de los grupos.

---

## 3. Arquitectura

La aplicación se compone de:

- **App móvil:** para estudiantes y docentes (con funciones según rol).
- **Servidor con base de datos:** almacena proyectos, grupos, tareas y avances.

Este diseño mantiene todo centralizado, sencillo de desarrollar y fácil de mantener en un contexto universitario.

---

## 4. Flujo Funcional

1. El docente crea un proyecto en la aplicación.
2. Publica la descripción y fecha de entrega.
3. Los estudiantes ven los proyectos disponibles.
4. Los estudiantes crean o se unen a un grupo.
5. Cada grupo divide el proyecto en tareas.
6. Los integrantes actualizan el estado de sus tareas.
7. Se pueden agregar comentarios o evidencias.
8. El docente revisa el avance de cada grupo.
9. Al finalizar, el docente evalúa el proyecto.

---

## 5. Justificación

Muchos proyectos se organizan usando varias herramientas externas, lo que genera desorden. La evaluación suele centrarse solo en el resultado final.  

Esta app permite:

- Publicar proyectos.
- Registrar grupos.
- Organizar tareas.
- Visualizar avances y participación.

Así, se mejora la **transparencia**, la **responsabilidad individual** y la **evaluación justa**.

---

## 6. Prototipo

El prototipo fue diseñado en **Figma**, mostrando el flujo básico y las funciones principales para docentes y estudiantes.  

**Enlace al prototipo:**  
[Prototipo en Figma](https://www.figma.com/design/JjmbEb3wWiwASTTv9pSytb/EDU-educational-application-ui-kit--FREE---Community-?node-id=0-1&t=Ii7L1A36TLjHe49J-1)

El diseño es simple, centrado en la gestión de proyecto, trabajos entre estudiantes y profesores.

