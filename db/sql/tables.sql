/* START DROPS */

DROP TABLE IF EXISTS
  password_tokens
, activation_tokens
, checked_out_books
, teacher_books
, librarian_details
, student_classes
, students
, teacher_classes
, classes
, teacher_details
, users
, user_roles;

/* END DROPS */

/* START CREATES */

CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY NOT NULL,
    name TEXT NOT NULL
); /* Administrator, Teacher, Librarian */

CREATE TABLE users (
    id TEXT PRIMARY KEY NOT NULL,
    username NETEXT NOT NULL,
    password NETEXT NOT NULL,
    salt TEXT NOT NULL,
    register_date BIGINT NOT NULL DEFAULT extract(epoch FROM now()),
    role_id INTEGER REFERENCES user_roles (id),
    activated BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE teacher_details (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL REFERENCES users (id),
    title NETEXT NOT NULL,
    first_name NETEXT NOT NULL,
    last_name NETEXT NOT NULL,
    email EMAIL NOT NULL,
    grade NETEXT NOT NULL,
    school_name NETEXT NOT NULL,
    zip ZIPCODE NOT NULL
);

CREATE TABLE classes (
    id SERIAL PRIMARY KEY NOT NULL,
    name NETEXT NOT NULL,
    year NETEXT NOT NULL,
    term TEXT,
    archived BOOLEAN NOT NULL DEFAULT FALSE,
    obsolete BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE teacher_classes (
    id SERIAL PRIMARY KEY NOT NULL,
    teacher_id TEXT NOT NULL REFERENCES teacher_details (id),
    class_id INTEGER NOT NULL REFERENCES classes (id)
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY NOT NULL,
    first_name NETEXT NOT NULL,
    last_name NETEXT NOT NULL,
    email EMAIL,
    reading_level TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    obsolete BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE student_classes (
    id SERIAL PRIMARY KEY NOT NULL,
    student_id INTEGER NOT NULL REFERENCES students (id),
    class_id INTEGER NOT NULL REFERENCES classes (id)
);

CREATE TABLE librarian_details (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL REFERENCES users (id),
    teacher_id TEXT NOT NULL REFERENCES teacher_details (id),
    student_id INTEGER NOT NULL REFERENCES students (id),
    first_name NETEXT NOT NULL,
    last_name NETEXT NOT NULL,
    email EMAIL NOT NULL,
    zip ZIPCODE NOT NULL,
    school_name NETEXT NOT NULL
);

CREATE TABLE teacher_books (
    id SERIAL PRIMARY KEY NOT NULL,
    teacher_id TEXT NOT NULL REFERENCES teacher_details (id),
    title NETEXT NOT NULL,
    author NETEXT NOT NULL,
    genres TEXT [] NOT NULL CHECK (genres <> '{}'),
    description TEXT,
    reading_level TEXT,
    number_in INTEGER NOT NULL,
    number_out INTEGER NOT NULL DEFAULT 0,
    available BOOLEAN NOT NULL DEFAULT TRUE,
    obsolete BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT valid_numbers CHECK (number_in >= 0 AND number_out >= 0),
    CONSTRAINT valid_total CHECK (number_in + number_out >= 1)
);

CREATE TABLE checked_out_books (
    id SERIAL PRIMARY KEY NOT NULL,
    teacher_id TEXT NOT NULL REFERENCES teacher_details (id),
    book_id INTEGER NOT NULL REFERENCES teacher_books (id),
    student_id INTEGER NOT NULL REFERENCES students (id),
    date_due BIGINT,
    date_out BIGINT NOT NULL,
    date_in BIGINT,
    obsolete BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT valid_date_due CHECK (date_due > date_out)
);

CREATE TABLE activation_tokens (
    id SERIAL PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL
);

CREATE TABLE password_tokens (
    id SERIAL PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL,
    exp BIGINT NOT NULL
);

/* END CREATES */
