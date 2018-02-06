/* START DROPS */

DROP VIEW IF EXISTS student_books_view;

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
        classes c,
        teacher_books b,
        checked_out_books ch
    WHERE
        ch.student_id = s.id AND
        ch.book_id = b.id AND
        s.class_id = c.id;

/* END CREATES */
