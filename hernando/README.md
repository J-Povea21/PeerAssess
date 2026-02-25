# Propuesta - Hernando Barreto

## Aplicacion movil para la evaluacion entre pares en actividades colaborativas universitarias

**Figma:** https://www.figma.com/design/jbcwyWxsnycqD4m2PhWL2i/Prototipo?node-id=0-1&t=yQtcVZPXAPnRLFtD-1

**Fotos:**
![](https://i.imgur.com/ewCRBEl.png)
![](https://i.imgur.com/e6WCDas.png)
![](https://i.imgur.com/7vuEfXX.png)
![](https://i.imgur.com/5Iu736u.png)
![](https://i.imgur.com/grk14Nv.png)
![](https://i.imgur.com/50GogvA.png)
---
## 1. Referentes

### 1.1 Teammates (Teammates.org)

Plataforma open-source desarrollada por la National University of Singapore que permite realizar evaluaciones entre pares en entornos academicos. Los estudiantes evaluan a sus companeros de equipo mediante rubricas configurables y los profesores acceden a reportes agregados por equipo o por estudiante.

**Aspectos rescatables:**
- Sistema de rubricas con escalas numericas y descriptores cualitativos.
- Reportes detallados por equipo, por estudiante y promedios globales.
- Separacion clara entre la vista del profesor (resultados completos) y la vista del estudiante (resultados limitados segun configuracion).

**Limitaciones identificadas:**
- Es una plataforma web sin aplicacion movil nativa, lo que reduce la accesibilidad en contextos donde los estudiantes trabajan desde el celular.
- No se integra directamente con LMS como Brightspace.

### 1.2 Google Forms + Google Sheets (Flujo manual comun)

Muchos profesores universitarios utilizan formularios de Google para recopilar evaluaciones entre pares y luego procesan los datos manualmente en hojas de calculo. Este flujo fue confirmado en entrevistas con docentes que implementan trabajos colaborativos.

**Aspectos rescatables:**
- Flexibilidad total para definir criterios y escalas.
- Familiaridad de los usuarios con la herramienta.

**Limitaciones identificadas:**
- Proceso completamente manual para consolidar resultados.
- No hay control de ventanas de tiempo ni visibilidad automatizada.
- Propenso a errores al cruzar datos de grupos, estudiantes y actividades.
- No existe autoexclusion automatica (un estudiante puede evaluarse a si mismo por error).

### 1.3 SparkPlus (University of Technology Sydney)

Herramienta web disenada especificamente para la evaluacion entre pares y la autoevaluacion en equipos universitarios. Permite definir criterios de evaluacion (contribucion, actitud, compromiso) y genera automaticamente factores de ajuste para la calificacion individual a partir de la nota grupal.

**Aspectos rescatables:**
- Enfoque academico puro: disenada para resolver exactamente el problema de la evaluacion justa en trabajos grupales.
- Generacion automatica de metricas: promedio por actividad, por grupo y por estudiante.
- Configuracion de visibilidad (publica o privada) por evaluacion.

**Limitaciones identificadas:**
- Interfaz anticuada, no adaptada a dispositivos moviles.
- No soporta importacion de grupos desde LMS externos.
- No tiene soporte para multiples categorias de grupos dentro de un mismo curso.

---

## 2. Composicion y Diseno de la Solucion

### Arquitectura propuesta: Una sola aplicacion Flutter con roles diferenciados (Profesor / Estudiante)

Se propone desarrollar **una unica aplicacion movil en Flutter** que gestione ambos roles (profesor y estudiante) dentro de la misma instalacion, diferenciando la experiencia de usuario mediante el rol autenticado.

### Justificacion de la arquitectura de una sola app

| Criterio | Una sola app (elegida) | Dos apps separadas |
|---|---|---|
| **Mantenimiento** | Un solo codigo fuente, menor costo de mantenimiento | Duplicacion de logica comun (auth, modelos, red) |
| **Experiencia de usuario** | Un profesor que tambien es estudiante en otro curso usa la misma app | Necesitaria instalar dos aplicaciones |
| **Distribucion** | Una sola publicacion en tiendas | Dos publicaciones independientes |
| **Complejidad** | Rutas y vistas condicionales por rol, manejadas con GetX | Proyectos separados con repositorios independientes |
| **Tamano de la app** | Ligeramente mayor al incluir ambas vistas | Cada app es mas liviana |

La decision se alinea con lo observado en los referentes: tanto Teammates como SparkPlus manejan roles dentro de una misma plataforma. Ademas, dado que la logica de negocio compartida (modelos de evaluacion, criterios, cursos, grupos) es significativa, mantener un solo proyecto reduce la deuda tecnica.

---

## 3. Flujo Funcional Detallado

### 3.1 Registro y Autenticacion

1. El usuario abre la aplicacion y se autentica mediante **Roble** (servicio institucional de autenticacion).
2. Roble retorna el perfil del usuario incluyendo su rol (profesor o estudiante).
3. La app redirige automaticamente a la vista correspondiente segun el rol.

### 3.2 Configuracion del Curso (Profesor)

1. El profesor crea un nuevo curso ingresando nombre e informacion basica.
2. El profesor genera **invitaciones privadas** (enlaces unicos o codigos de verificacion) para que los estudiantes se unan al curso.
3. Los estudiantes reciben la invitacion, la aceptan dentro de la app y quedan inscritos.

### 3.3 Importacion de Grupos desde Brightspace

1. El profesor selecciona un curso y accede a la opcion "Importar grupos".
2. La app se conecta a la API de Brightspace y obtiene las **categorias de grupos** (group categories) del curso.
3. El profesor selecciona que categorias importar.
4. Los grupos y sus miembros se sincronizan en la base de datos de la app.
5. El profesor puede **actualizar** los grupos en cualquier momento para reflejar cambios hechos en Brightspace.

### 3.4 Creacion de Evaluaciones (Profesor)

1. El profesor selecciona un curso y una **categoria de grupos**.
2. Crea una nueva evaluacion con los siguientes parametros:
   - **Nombre** de la evaluacion (ej: "Sprint 2 - Evaluacion de pares").
   - **Ventana de tiempo**: duracion de disponibilidad en minutos u horas.
   - **Visibilidad**:
     - *Publica*: los resultados (puntajes por criterio + puntaje general) son visibles para los miembros del grupo una vez cerrada la ventana.
     - *Privada*: los resultados solo son visibles para el profesor.
3. La evaluacion queda activa y disponible para los estudiantes durante la ventana configurada.

### 3.5 Proceso de Evaluacion (Estudiante)

1. El estudiante accede a la app y ve la lista de **evaluaciones pendientes** en sus cursos.
2. Selecciona una evaluacion activa.
3. Para **cada companero de su grupo** (no se incluye a si mismo), evalua los siguientes criterios en una escala de 2.0 a 5.0:

| Criterio | Descripcion |
|---|---|
| **Puntualidad** | Asistencia y puntualidad a sesiones de equipo |
| **Contribuciones** | Aportes al trabajo del equipo |
| **Compromiso** | Responsabilidad con tareas y roles asignados |
| **Actitud** | Disposicion positiva hacia el trabajo colaborativo |

4. Cada nivel de la escala presenta un **descriptor cualitativo** para guiar al evaluador.
5. El estudiante envia la evaluacion. No puede modificarla una vez enviada.
6. Si la ventana de tiempo expira, las evaluaciones pendientes se cierran automaticamente.

### 3.6 Visualizacion de Resultados

#### Para el Profesor:

```
Curso > Evaluacion > Vista General
    |
    +-- Promedio por actividad (todos los grupos)
    |
    +-- Promedio por grupo (a traves de actividades)
    |
    +-- Promedio por estudiante (a traves de actividades)
    |
    +-- Vista detallada:
         Grupo > Estudiante > Puntaje por criterio
```

El profesor puede navegar en la jerarquia completa:
- **Nivel actividad**: promedio general de todos los grupos en esa evaluacion.
- **Nivel grupo**: promedio del grupo en cada criterio y puntaje general.
- **Nivel estudiante**: puntajes individuales recibidos por cada criterio, identificando quien evaluo (visible solo para el profesor).

#### Para el Estudiante (solo en evaluaciones publicas):

- Ve su **puntaje general** y **puntaje por criterio** (promedio de lo que sus pares le asignaron).
- **No ve** quien le asigno cada puntaje (anonimato del evaluador).
- En evaluaciones privadas, el estudiante solo ve que la evaluacion fue completada, sin acceso a resultados.

## 4. Justificacion de la Propuesta

### 4.1 Basada en los referentes analizados

La propuesta toma las mejores practicas de cada referente e intenta resolver sus limitaciones:

| Aspecto | Referente | Aplicacion en la propuesta |
|---|---|---|
| Rubricas con descriptores cualitativos | Teammates, SparkPlus | Los 4 criterios (Puntualidad, Contribuciones, Compromiso, Actitud) incluyen descriptores por nivel, tal como lo define el proyecto |
| Reportes multinivel | Teammates | El profesor puede ver promedios por actividad, por grupo y por estudiante, con drill-down hasta el criterio individual |
| Visibilidad configurable | SparkPlus | Cada evaluacion puede ser publica o privada, controlada por el profesor al momento de crearla |
| Integracion con LMS | Ninguno de los referentes | La importacion directa desde Brightspace elimina la creacion manual de grupos, superando una limitacion comun |
| Aplicacion movil nativa | Ninguno de los referentes | Flutter permite una experiencia movil nativa en iOS y Android, a diferencia de las soluciones web existentes |
| Eliminacion del flujo manual | Google Forms | Se automatiza todo el proceso: desde la evaluacion hasta la consolidacion de resultados |

### 4.2 Basada en entrevistas con profesores

A partir de conversaciones con docentes que implementan trabajos colaborativos, se identificaron los siguientes puntos de dolor que la propuesta aborda directamente:

1. **"Paso horas cruzando datos en Excel"**: Los profesores que usan formularios pierden tiempo significativo consolidando evaluaciones. La app automatiza completamente la agregacion de resultados a multiples niveles (actividad, grupo, estudiante, criterio).

2. **"Los estudiantes se evaluan a si mismos o evaluan al grupo equivocado"**: El sistema solo presenta para evaluacion a los companeros del mismo grupo, excluyendo automaticamente la autoevaluacion. Los grupos se importan de Brightspace, eliminando errores de asignacion.

3. **"Necesito que la evaluacion sea rapida, en clase, desde el celular"**: La ventana de tiempo configurable (en minutos u horas) y la interfaz movil nativa permiten realizar evaluaciones rapidas durante o al final de una sesion de clase.

4. **"A veces quiero que los estudiantes vean sus resultados y a veces no"**: La visibilidad configurable (publica/privada) por evaluacion da al profesor control total. En evaluaciones formativas puede usar visibilidad publica para retroalimentacion; en evaluaciones sumativas puede mantenerla privada.

5. **"Tengo varios tipos de grupos en un mismo curso"**: El soporte para multiples categorias de grupos por curso (importadas desde Brightspace) permite al profesor manejar diferentes configuraciones grupales sin conflicto.

### 4.3 Viabilidad tecnica

La propuesta se alinea con los requerimientos tecnicos del proyecto:

- **Clean Architecture**: separacion en capas (dominio, datos, presentacion) facilita el mantenimiento y testing.
- **GetX**: manejo de estado, navegacion y dependencias con un solo framework.
- **Roble**: autenticacion y almacenamiento de datos mediante el servicio institucional.
- **Flutter**: una sola base de codigo para Android e iOS.

---

## 5. Resumen

Se propone una **aplicacion movil unica en Flutter** con roles diferenciados que permite a los profesores crear evaluaciones entre pares con ventanas de tiempo y visibilidad configurable, importar grupos directamente desde Brightspace, y consultar resultados a multiples niveles de detalle. Los estudiantes evaluan a sus companeros mediante una rubrica de 4 criterios con descriptores cualitativos, y pueden consultar sus resultados cuando la evaluacion es publica. La solucion automatiza un proceso que actualmente es manual y propenso a errores, ofreciendo una experiencia movil nativa que se ajusta al contexto real de uso en el aula.
