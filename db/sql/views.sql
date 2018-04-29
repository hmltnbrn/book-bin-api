/* START DROPS */

DROP VIEW IF EXISTS student_books_view;
DROP VIEW IF EXISTS teacher_students_view;

/* END DROPS */

/* START CREATES */

CREATE OR REPLACE VIEW student_books_view
AS
    SELECT
        s.id AS student_id,
        s.first_name,
        s.last_name,
        s.email,
        s.reading_level AS student_reading_level,
        s.active,
        c.id AS class_id,
        c.name AS class_name,
        c.year AS class_year,
        c.term AS class_term,
        b.id AS book_id,
        b.title,
        b.author,
        b.genres,
        b.description,
        b.reading_level AS book_reading_level,
        ch.date_due,
        ch.date_out,
        ch.date_in,
        ch.teacher_id
    FROM
        students s,
        student_classes sc,
        classes c,
        teacher_books b,
        checked_out_books ch
    WHERE
        ch.student_id = s.id AND
        ch.book_id = b.id AND
        sc.class_id = c.id AND
        sc.student_id = s.id;

CREATE OR REPLACE VIEW teacher_students_view
AS
    SELECT
        t.id AS teacher_id,
        t.title AS teacher_title,
        t.first_name AS teacher_first_name,
        t.last_name AS teacher_last_name,
        t.email AS teacher_email,
        t.grade,
        t.school_name,
        t.zip,
        c.id AS class_id,
        c.name AS class_name,
        c.year AS class_year,
        c.term AS class_term,
        s.id AS student_id,
        s.first_name AS student_first_name,
        s.last_name AS student_last_name,
        s.email AS student_email,
        s.reading_level,
        s.active
    FROM
        teacher_details t,
        students s,
        classes c,
        student_classes sc,
        teacher_classes tc
    WHERE
        sc.student_id = s.id AND
        sc.class_id = c.id AND
        tc.class_id = c.id AND
        tc.teacher_id = t.id AND
        c.obsolete IS NOT TRUE AND
        s.obsolete IS NOT TRUE;

/* END CREATES */
