# PeerMark — Propuesta de Aplicación de Evaluación entre Pares

> **Proyecto:** Mobile Development 2026-10 · Peer Assessment App
> **Autor:** Juan
> **Fecha:** Febrero 2026

---

## Tabla de Contenidos

1. [Referentes](#1-referentes)
2. [Composición y Diseño de la Solución](#2-composición-y-diseño-de-la-solución)
3. [Flujo de Trabajo Detallado](#3-flujo-de-trabajo-detallado)
4. [Justificación de la Propuesta](#4-justificación-de-la-propuesta)
5. [Prompt para Diseño en Figma (AI)](#5-prompt-para-diseño-en-figma-ai)

---

## 1. Referentes

Antes de diseñar la solución, revisé tres plataformas existentes que resuelven problemas similares de evaluación entre pares en contextos educativos.

---

### 1.1 TEAMMATES — National University of Singapore (NUS)

**¿Qué es?** [TEAMMATES](https://github.com/TEAMMATES/teammates) es una herramienta gratuita y de código abierto desarrollada por la NUS para facilitar la evaluación y retroalimentación entre pares en equipos de estudiantes universitarios. Es utilizada por decenas de universidades a nivel mundial. Sin embargo, tiene las siguientes desventajas:

- Es **exclusivamente web**, no existe aplicación móvil nativa.
- No tiene integración con Brightspace por lo que los grupos deben crearse manualmente.

Debido a estas limitaciones, no es una opción viable para lo que se requiere en el contexto del curso

---

### 1.2 iPeer — University of British Columbia (UBC)

**¿Qué es?**
[iPeer](https://ipeer.ctlt.ubc.ca/wiki) es una aplicación web de código abierto desarrollada por la UBC para la evaluación entre pares con soporte de rúbricas. Identifiqué las siguientes limitaciones:

- Al igual que TEAMMATES, IPeer **no cuenta con versión móvil** 
- No existe integración con Brightspace para importar grupos.
- La interfaz es algo antigua
- Tiene páginas de la documentación que todavía están ['under construction'](https://ipeer.ctlt.ubc.ca/wiki/eval) lo cual no genera mucha confianza en que el proyecto tenga una buena documentación

En este caso, los principales puntos que evitan que tomemos esta alternativa son la documentación y, por supuesto, la falta de una versión móvil

---

### 1.3 Peergrade / Eduflow

**¿Qué es?**
Peergrade fue una plataforma SaaS de retroalimentación entre pares que evolucionó hacia Eduflow, una plataforma más completa para flujos de aprendizaje colaborativo. Es utilizada en universidades de Europa y Norteamérica. Es muchísimo más moderna y cuentan con una página de documentación. Sin embargo, los inconvenientes que encontré son los siguientes:

- Parece estar enfocada en la revisión de **artefactos** (documentos, proyectos), no en la evaluación del **comportamiento y actitud** en un trabajo en equipo, que es el objetivo de este proyecto
- No existe integración nativa con Brightspace para importar categorías de grupos
- Es un servicio de suscripción paga, lo que la hace inaccesible para uso institucional masivo sin costo

Si bien se ve como una mejor opción en comparación a las dos opciones anteriores, el enfoque de la aplicación y la suscripción no la hacen totalmente elegible para el caso de uso que se presenta en el curso

---

## 2. Composición y Diseño de la Solución

### 2.1 Decisión Arquitectural: Una sola app con roles diferenciados

Se propone **una única aplicación Flutter con navegación basada en rol**, en lugar de dos aplicaciones separadas o una combinación de app móvil con plataforma web.

#### ¿Por qué una sola app?

| Alternativa considerada | Razón para descartar |
|-------------------------|----------------------|
| **Dos apps separadas** (una para profesores, una para estudiantes) | Duplica el mantenimiento del código. Estudiantes y profesores podrían instalar la aplicación incorrecta. Mantener la consistencia de versiones entre las dos apps añade complejidad  innecesaria. |
| **App móvil + plataforma web** | Está fuera del alcance de un proyecto de 4 personas en un curso de desarrollo móvil. Introduciría tecnologías y capas de infraestructura adicionales que tomaría tiempo construir y probar. |
| **Una sola app con roles**  | Mantiene un único codebase. El rol se detecta al iniciar sesión y determina el stack de navegación. Profesores y estudiantes comparten la misma autenticación, modelos de datos y servicios. Es el modelo que siguen los tres referentes analizados (TEAMMATES, iPeer, Eduflow). |

#### Flujo de selección de rol

```
App Launch
    │
    ▼
Login / Register
    │
    ▼
Roble Auth ──► Role detected (teacher | student)
    │                   │
    ▼                   ▼
Teacher Shell       Student Shell
(Dashboard,         (Active assessments,
 Courses,            My Courses,
 Results)            My Results)
```

El rol se asigna durante el registro y se persiste en Roble. GetX maneja el routing condicional con un `GetMiddleware` que redirige según el rol autenticado.

---

### 2.2 Arquitectura Técnica: Clean Architecture + GetX

La aplicación sigue los principios de **Clean Architecture** organizados por features. Cada feature (auth, courses, groups, assessments, results) se divide en tres capas:

- **Presentation layer**: Pages, `GetxController`s y `Bindings`. GetX centraliza el manejo de estado reactivo, la navegación declarativa y la inyección de dependencias. Esta capa no contiene lógica de negocio.

- **Domain layer**: Entities y Use Cases puros — sin dependencias de Flutter, Roble ni ningún framework externo. Los repositorios se definen como interfaces abstractas (`abstract class`). Esto garantiza que la lógica de negocio sea testeable de forma aislada.

- **Data layer**: Implementaciones concretas de los repositorios, models (serialización/deserialización JSON ↔ Entity) y DataSources que se comunican con Roble.

Esta separación es especialmente valiosa dado que **Roble está en desarrollo activo**: si su API cambia, únicamente se actualiza la capa de datos, sin necesidad de modificar la lógica de negocio ni la interfaz de usuario.

---

### 2.3 Backend: Roble

Roble actúa como el BaaS (Backend-as-a-Service) de la aplicación, proveyendo:

- **Autenticación**: registro, login y gestión de sesión de usuarios.
- **Almacenamiento de datos**: cursos, grupos importados, evaluaciones y resultados.

Toda la comunicación con Roble está abstraída detrás de interfaces de repositorio. Esto crea un escudo ante inestabilidades o cambios de API durante el desarrollo, y además permite que el equipo implemente mocks locales para testing sin depender de conectividad.

---

### 2.4 Importación de Grupos desde Brightspace

Los grupos **no se crean dentro de la aplicación**. El flujo de importación es el siguiente:

1. El docente exporta las categorías de grupos desde Brightspace como archivo **CSV**.
2. Dentro de la app, en la vista de detalle del curso, el docente utiliza la función **"Importar desde Brightspace"**.
3. La app parsea el CSV, mapea los nombres de categorías y los IDs de los estudiantes a los miembros ya registrados en el curso.
4. Los grupos se crean o actualizan en Roble de forma **no destructiva** (**importante**: re-importar un CSV actualiza datos sin eliminar evaluaciones existentes).

### 2.5 Módulos Funcionales Principales

| Módulo         | Responsabilidades principales |
|----------------|-------------------------------|
| **Auth**       | Registro, login, detección de rol, gestión de sesión |
| **Courses**    | Crear cursos, generar código de invitación, unirse a cursos, listar cursos por rol |
| **Groups**     | Importar CSV de Brightspace, listar categorías de grupos, ver miembros |
| **Assessments**| Crear y activar evaluaciones, completar evaluaciones como estudiante, gestión de ventana de tiempo |
| **Results**    | Calcular promedios, visualizar resultados por actividad/grupo/estudiante/criterio |

---

## 3. Flujo de Trabajo Detallado

### 3.1 Flujo del Docente

```
[1] Registro / Login
      │  El docente se registra con rol "profesor" vía Roble Auth
      ▼
[2] Crear Curso
      │  Nombre, descripción. La app genera un código de ingreso único con expiración.
      ▼
[3] Invitar Estudiantes
      │  El docente comparte el código externamente (WhatsApp, correo, pantalla).
      │  El código es privado y expira para evitar accesos no autorizados.
      ▼
[4] Importar Grupos desde Brightspace
      │  Sube el CSV exportado desde Brightspace.
      │  La app crea las categorías de grupo y asocia los estudiantes ya inscritos.
      │  Actualizaciones futuras: re-subir CSV aplica cambios de forma incremental.
      ▼
[5] Activar una Evaluación
      │  Selecciona una categoría de grupo.
      │  Configura: Nombre · Ventana de tiempo (minutos u horas) · Visibilidad (Público / Privado).
      │  Al confirmar, la evaluación pasa al estado ACTIVE.
      ▼
[6] Monitorear Progreso
      │  Durante la ventana activa, el docente puede ver cuántos estudiantes han enviado
      │  su evaluación por grupo (ej. "3/4 completadas").
      ▼
[7] Ver Resultados (ventana cerrada)
      │  ├─ Promedio de la actividad (todos los grupos)
      │  ├─ Promedio por grupo (entre actividades)
      │  ├─ Promedio por estudiante (entre actividades)
      │  └─ Detalle: Grupo → Estudiante → Puntaje por criterio
```

---

### 3.2 Flujo del Estudiante

```
[1] Registro / Login
      │  El estudiante se registra con rol "estudiante" vía Roble Auth
      ▼
[2] Unirse a un Curso
      │  Ingresa el código de invitación compartido por el docente.
      │  El sistema valida el código y agrega al estudiante al curso.
      ▼
[3] Ver Evaluaciones Activas
      │  El dashboard muestra las evaluaciones abiertas para sus grupos,
      │  con un contador regresivo de tiempo restante.
      ▼
[4] Completar Evaluación
      │  Para cada compañero de grupo (excluyendo a sí mismo):
      │    └─ Califica 4 criterios: Puntualidad · Contribuciones · Compromiso · Actitud
      │       Puntaje: 2.0 (Needs Improvement) / 3.0 (Adequate) / 4.0 (Good) / 5.0 (Excellent)
      │       Se muestran los descriptores de cada nivel para orientar la evaluación.
      │  El formulario se envía una única vez dentro de la ventana de tiempo.
      ▼
[5] Ver Resultados (si visibilidad = Público)
      │  Puntaje general recibido (promedio de sus pares, fuentes anónimas).
      │  Desglose por criterio con barra de progreso visual.
      │  Si la evaluación es Privada: se muestra mensaje "Resultados disponibles solo para el docente".
```

---

### 3.3 Ciclo de Vida de una Evaluación (State Machine)

```
          ┌──────────────────────────────────────────────────────────┐
          │                                                          │
   [Docente crea y configura]                              [Ventana de tiempo expira]
          │                                                          │
          ▼                                                          ▼
       ACTIVE  ──────────────────────────────────────────►  CLOSED
   (estudiantes pueden                                    (no se aceptan más
    enviar evaluaciones)                                   envíos)
                                                                │
                                                     [Visibilidad = Público]
                                                                │
                                                                ▼
                                                     RESULTS VISIBLE TO STUDENTS
                                                     (docente siempre puede ver)
```

---

## 4. Justificación de la Propuesta

### 4.1 Mobile-first es el diferenciador central

Los tres referentes analizados (TEAMMATES, iPeer, Peergrade) son **exclusivamente web**. En un contexto de un salón de clases, la fricción que genera el tener que abrir la aplicación en el navegador para entonces poder proceder a evaluar al compañero es grande. En cambio, tener una aplicación móvil a la que simplemente deben darle click y calificar hace que la experiencia sea muchísimo más cómodo para los estudiantes y el profesor.

### 4.2 La integración con Brightspace resuelve el problema más crítico

Ninguno de los referentes se integra con Brightspace, la fuente de verdad de los datos. En el contexto de la universidad, los grupos ya existen en Brightspace por lo que forzar al docente a recrearlos manualmente en otra herramienta va a generar molestias. Para solucionar esto es que se va a soportar el importar los grupos por `CSV`, ya que es una opción a un click en Brightspace.

### 4.3 Las ventanas de tiempo son un caso de uso real sin cobertura

La evaluación "en clase, durante una sesión" no está contemplada por ningún referente. TEAMMATES y iPeer asumen evaluaciones que permanecen abiertas días o semanas. El caso de uso que se presenta requiere esa función como a modo de validación.

### 4.4 Una app con roles es el modelo estándar del mercado

Todos los referentes utilizan una sola interfaz con vistas diferenciadas por rol. Separar la app en dos proyectos independientes añade complejidad sin beneficio para el usuario final.

## 5. Link de Figma
Adjunto el link de mi diseño en [Figma](https://www.figma.com/design/qw2PVTcbw4QfORtGOguKJ9/Groupie-%E2%80%94-UI-Mockups?node-id=0-1&t=6x8zcqcvHaZ0iITt-1)
