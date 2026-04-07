# PeerAssess — Project Context

PeerAssess is a mobile application built with Flutter that allows students to evaluate the performance and commitment of their peers in collaborative course activities. It is a single app with role-based access (teacher and student).

## Roles

- **Teachers**: Create and manage courses, invite users, trigger assessments, view scoring results.
- **Students**: Join courses, participate in assessments by evaluating peers.

## Core Entities

### Courses
- A teacher can invite users to join a course (invitations must be private or include a verification method).
- A teacher can have multiple courses.
- A student can join multiple courses.

### Groups
- Groups are NOT created in the app. They are formed in Brightspace (known as **group categories**) and imported into the app.
- Updates to imported groups are also possible.
- Multiple group categories are possible on one course.

### Assessments
- Teachers can trigger assessments on any category of the course.
- An assessment gives each member of a group the opportunity to evaluate the work and attitude of their peers.
- **There is no self-evaluation.**

### Assessment Parameters
Each assessment includes:
- **Name**
- **Time window** (duration of availability in minutes or hours)
- **Visibility**:
  - Public: results are shown to group members (criteria scores + general score)
  - Private: results are visible only to the teacher

## Scoring Access (Teacher View)
- Activity average (all groups)
- Group average (across activities)
- Student average (across activities)
- Detailed results per group > student > criteria score

## Assessment Criteria (Rubric)

Each criterion is scored on a scale: Needs Improvement (2.0), Adequate (3.0), Good (4.0), Excellent (5.0).

### Punctuality
- 2.0: Late or absent for most sessions, negatively impacting the team.
- 3.0: Frequently arrived late or missed sessions.
- 4.0: Generally punctual and attended most sessions.
- 5.0: Consistently punctual and attended all team sessions.

### Contributions
- 2.0: Acted mostly as a passive observer, contributed little or nothing.
- 3.0: Participated occasionally in discussions and teamwork.
- 4.0: Made several contributions; could be more critical or proactive.
- 5.0: Provided relevant and enriching contributions that improved the team's work.

### Commitment
- 2.0: Showed little commitment to tasks or roles.
- 3.0: Occasionally showed lack of commitment, which affected team progress.
- 4.0: Demonstrated responsibility and commitment most of the time.
- 5.0: Consistently committed to tasks and roles, showing strong engagement.

### Attitude
- 2.0: Displayed a negative or indifferent attitude toward team tasks.
- 3.0: Occasionally showed a positive attitude, but not enough to positively impact the team.
- 4.0: Mostly displayed a positive and open attitude that helped the team.
- 5.0: Always demonstrated a positive attitude and willingness to contribute with quality work.

## Coding Requirements
1. The app must adhere to clean architecture principles.
2. The app must use **GetX** for state management, navigation, and dependency injection.
3. Location and background work permissions must be requested and given.
4. Authentication and data storage services should use **Roble**.
