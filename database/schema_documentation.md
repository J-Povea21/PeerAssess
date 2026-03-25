# PeerAssess Database Schema Documentation

## users

Stores all users in the system.

Fields:

* **id** (Primary Key)
* **name** – User name
* **email** – Unique email address
* **role** – User role (`teacher` or `student`)
* **created_at** – Timestamp when the user was created

---

## courses

Stores courses created by teachers.

Fields:

* **id** (Primary Key)
* **name** – Course name
* **teacher_id** – Foreign Key → `users.id`
* **created_at** – Timestamp when the course was created

Relationship:
Each course is created and managed by a teacher.

---

## group_categories

Defines categories of groups inside a course.

Fields:

* **id** (Primary Key)
* **name** – Category name
* **course_id** – Foreign Key → `courses.id`

Relationship:
A course can have multiple group categories.

---

## groups

Stores groups of students within a category.

Fields:

* **id** (Primary Key)
* **name** – Group name
* **category_id** – Foreign Key → `group_categories.id`

Relationship:
Each group belongs to a group category.

---

## user_groups

Associates users with groups.

Fields:

* **id** (Primary Key)
* **user_id** – Foreign Key → `users.id`
* **group_id** – Foreign Key → `groups.id`

Relationship:
This table creates a many-to-many relationship between users and groups.
Students are assigned to groups through this table.

---

## assessments

Stores evaluation activities for groups.

Fields:

* **id** (Primary Key)
* **group_id** – Foreign Key → `groups.id`
* **created_at** – Timestamp when the assessment was created

Relationship:
Each assessment is associated with a specific group.

---

## evaluations

Stores peer evaluations between students.

Fields:

* **id** (Primary Key)
* **assessment_id** – Foreign Key → `assessments.id`
* **evaluator_id** – Foreign Key → `users.id`
* **evaluated_id** – Foreign Key → `users.id`

Relationship:
A student evaluates another student during an assessment.

---

## criteria_scores

Stores rubric scores for each evaluation.

Rubric criteria:

* **Punctuality**
* **Contributions**
* **Commitment**
* **Attitude**

Scale: **2.0 – 5.0**

Fields:

* **id** (Primary Key)
* **evaluation_id** – Foreign Key → `evaluations.id`
* **punctuality**
* **contributions**
* **commitment**
* **attitude**

Relationship:
Each evaluation can have one set of rubric scores.

---

## invitations

Stores invitations sent to users to join a course.

Fields:

* **id** (Primary Key)
* **email** – Email address of the invited user
* **course_id** – Foreign Key → `courses.id`
* **role** – Role assigned when joining (`student` or `teacher`)
* **status** – Invitation status (e.g., `pending`, `accepted`)
* **created_at** – Timestamp when the invitation was created

Relationship:
Invitations allow users to join a course before creating an account or accepting access.
