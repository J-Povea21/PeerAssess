# PeerAssess Database Schema Documentation

## users
Stores all users in the system.

Fields:
- id (Primary Key)
- name (User name)
- email (Unique email)
- role (teacher or student)
- created_at (timestamp)

---

## courses
Stores courses created by teachers.

Fields:
- id (Primary Key)
- name (Course name)
- teacher_id (Foreign Key → users.id)
- created_at

Relationship:
Each course belongs to a teacher.

---

## group_categories
Defines categories of groups inside a course.

Fields:
- id (Primary Key)
- course_id (Foreign Key → courses.id)
- name

---

## groups
Stores groups of students.

Fields:
- id (Primary Key)
- category_id (Foreign Key → group_categories.id)
- name

---

## assessments
Stores evaluation activities.

Fields:
- id (Primary Key)
- course_id (Foreign Key → courses.id)
- title
- due_date

---

## evaluations
Stores peer evaluations between students.

Fields:
- id (Primary Key)
- assessment_id (Foreign Key → assessments.id)
- evaluator_id (Foreign Key → users.id)
- evaluated_id (Foreign Key → users.id)

---

## criteria_scores
Stores rubric scores for each evaluation.

Rubric criteria:
- Punctuality
- Contributions
- Commitment
- Attitude

Scale: 2.0 – 5.0

Fields:
- id (Primary Key)
- evaluation_id (Foreign Key → evaluations.id)
- punctuality
- contributions
- commitment
- attitude

---

## invitations
Stores invitations sent to students to join a course.

Fields:
- id (Primary Key)
- email
- course_id (Foreign Key → courses.id)
- token
- status
- created_at