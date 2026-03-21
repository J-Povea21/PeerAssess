CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    role VARCHAR(20) CHECK (role IN ('teacher','student')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    teacher_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES users(id)
);

CREATE TABLE group_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    course_id INTEGER,
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE group_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    course_id INTEGER,
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE assessments (
    id SERIAL PRIMARY KEY,
    group_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id)
);

CREATE TABLE evaluations (
    id SERIAL PRIMARY KEY,
    assessment_id INTEGER,
    evaluator_id INTEGER,
    evaluated_id INTEGER,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id),
    FOREIGN KEY (evaluator_id) REFERENCES users(id),
    FOREIGN KEY (evaluated_id) REFERENCES users(id)
);

CREATE TABLE criteria_scores (
    id SERIAL PRIMARY KEY,
    evaluation_id INTEGER,
    punctuality DECIMAL(2,1),
    contributions DECIMAL(2,1),
    commitment DECIMAL(2,1),
    attitude DECIMAL(2,1),
    FOREIGN KEY (evaluation_id) REFERENCES evaluations(id)
);

CREATE TABLE invitations (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    course_id INTEGER,
    role VARCHAR(20),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

INSERT INTO users (name, email, role)
VALUES ('Augusto Salazar', 'augusto.salazar@peerassess.com', 'teacher');

