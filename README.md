# 📌 Proyecto Seleccionado: Plataforma de Peer Assessment Universitario

## 🎯 Decisión del Proyecto

Como equipo, hemos decidido elegir el desarrollo de esta **Plataforma de Peer Assessment** como nuestro proyecto principal.

Sin embargo, no partimos desde cero en términos conceptuales. Analizamos distintas soluciones existentes en el mercado y decidimos **tomar funcionalidades clave de otras plataformas**, adaptándolas y mejorándolas dentro de nuestra propia arquitectura y enfoque técnico.

De esta manera:

* 
* 
* 
* 

Nuestro objetivo no es replicar otras herramientas, sino **integrar sus mejores características y potenciarlas dentro de una aplicación móvil moderna, estructurada bajo Clean Architecture y optimizada para el contexto universitario.**

---

# 📱 Peer Assessment App

Aplicación móvil desarrollada en **Flutter** para la evaluación entre pares en entornos universitarios, con integración de grupos importados desde Brightspace y arquitectura basada en Clean Architecture.

---

## 📌 Descripción del Proyecto

Durante el desarrollo de actividades colaborativas en la universidad, uno de los principales retos es garantizar una evaluación justa y transparente del desempeño individual dentro de los equipos de trabajo.

Esta aplicación permite realizar **peer assessment estructurado**, automatizando cálculos, garantizando anonimato y proporcionando métricas avanzadas para el análisis docente.

La solución está diseñada para estudiantes y profesores mediante un sistema de roles dentro de una única aplicación.

---

## 🎯 Objetivos

* Garantizar evaluación individual justa en trabajos grupales.
* Reducir carga administrativa del docente.
* Automatizar cálculo de promedios.
* Proporcionar análisis estadístico avanzado.
* Integrarse con grupos importados desde Brightspace.

---

## 🏗️ Arquitectura

El proyecto implementa **Clean Architecture**, separando responsabilidades en tres capas:

### 1️⃣ Presentation Layer

* UI desarrollada en Flutter.
* GetX para manejo de estado, navegación e inyección de dependencias.
* Controladores por módulo.

### 2️⃣ Domain Layer

**Entidades principales:**

* User
* Course
* GroupCategory
* Group
* Assessment
* Evaluation
* Criteria

**Casos de uso:**

* CreateAssessment
* SubmitEvaluation
* CalculateGroupAverage
* CalculateStudentAverage
* ImportGroups
* JoinCourse

### 3️⃣ Data Layer

* Servicios Roble para autenticación y base de datos.
* Repositorios específicos por módulo.

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

## 🔄 Flujo Funcional

### 1️⃣ Autenticación

* Inicio de sesión mediante Roble.
* Redirección automática según rol.

### 2️⃣ Gestión de Cursos

* Creación de curso por parte del docente.
* Unión mediante código privado.
* Importación de grupos.

### 3️⃣ Creación de Evaluaciones

* Selección de curso y categoría.
* Definición de ventana de tiempo.
* Configuración de visibilidad.

### 4️⃣ Evaluación entre Pares

Criterios evaluados:

* Punctuality
* Contributions
* Commitment
* Attitude

### 5️⃣ Cálculo Automático

El sistema calcula:

* Promedio por estudiante.
* Promedio por grupo.
* Promedio por actividad.
* Promedio global por curso.

---

## 🚀 Funcionalidades Diferenciadoras

### 📊 Índice de Equidad del Grupo

Calcula la desviación estándar entre puntajes del grupo para identificar desequilibrios.

### ⚠️ Detección de Evaluaciones Anómalas

Identifica:

* Calificaciones extremadamente bajas generalizadas.
* Desviaciones significativas respecto al promedio.

### 📈 Dashboard Analítico Avanzado

Permite visualizar:

* Comparación entre grupos.
* Evolución del desempeño.
* Ranking de mejora individual.

### 🤖 Retroalimentación Automática

Generación automática de resumen de desempeño basado en puntajes obtenidos.

### 🧠 Modo Reflexión Post-Evaluación

Auto-reflexión voluntaria para fomentar mejora continua.

---

## ✅ Cumplimiento Técnico

* ✔ Clean Architecture
* ✔ GetX
* ✔ Roble para autenticación y almacenamiento
* ✔ Manejo de permisos (ubicación y background)
* ✔ Importación desde Brightspace
* ✔ Módulo analítico en Domain Layer

---

## 🛠️ Tecnologías Utilizadas

* Flutter
* Dart
* GetX
* Roble (Auth & Storage)

---

## 📚 Justificación Académica

La solución combina:

* Rúbricas estructuradas.
* Automatización de cálculos.
* Simplicidad de uso.
* Análisis estadístico avanzado.

Responde a necesidades reales identificadas en entrevistas docentes: evaluación justa, anonimato, reducción de carga administrativa y soporte en toma de decisiones pedagógicas.

---

## 🏁 Conclusión

La aplicación no solo cumple con los requerimientos funcionales establecidos, sino que incorpora herramientas analíticas e inteligentes que fortalecen la evaluación formativa.

Se posiciona como una solución moderna, robusta y orientada a la toma de decisiones basada en datos dentro del entorno universitario.
