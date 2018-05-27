/* START DROPS */

DROP FUNCTION IF EXISTS cl_alpha_numeric_code();
DROP FUNCTION IF EXISTS cl_sign_up(u_input text, p_input password, t_input text, fn_input text, ln_input text, e_input text, g_input text, sn_input text, z_input text, ut_input integer);
DROP FUNCTION IF EXISTS cl_sign_in(u_input text, p_input text);
DROP FUNCTION IF EXISTS cl_password_token(e_input text);
DROP FUNCTION IF EXISTS cl_reset_password(e_input text, t_input text, p_input password);
DROP FUNCTION IF EXISTS cl_change_password(u_input TEXT, op_input TEXT, np_input password);
DROP FUNCTION IF EXISTS cl_activate_account(t_input text);
DROP FUNCTION IF EXISTS cl_forgot_username(e_input text);
DROP FUNCTION IF EXISTS cl_check_out(t_input text, b_input integer, s_input integer, d_input bigint);
DROP FUNCTION IF EXISTS cl_check_in(t_input text, b_input integer, s_input integer);
DROP FUNCTION IF EXISTS cl_check_in_students(t_input text, b_input integer, s_input integer[]);
DROP FUNCTION IF EXISTS cl_delete_book(b_input integer, t_input text);
DROP FUNCTION IF EXISTS cl_overdue_books(t_input text);

/* END DROPS */

/* START CREATES */

CREATE OR REPLACE FUNCTION cl_alpha_numeric_code()
RETURNS char(6) AS $$
DECLARE
    code CHAR(6);
    i INTEGER;
    chars CHAR(36) = 'abcdefghijklmnopqrstuvwxyz0123456789';
BEGIN
    code = '';
    FOR i in 1 .. 6 LOOP
        code = code || substr(chars, int4(floor(random() * length(chars))) + 1, 1);
    END LOOP;
    RETURN UPPER(code);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_sign_up(u_input TEXT, p_input PASSWORD, t_input TEXT, fn_input TEXT, ln_input TEXT, e_input TEXT, g_input TEXT, sn_input TEXT, z_input TEXT, ut_input INTEGER)
RETURNS TEXT AS $$
DECLARE
    gen_user_id TEXT;
    gen_teacher_id TEXT;
    gen_user_salt TEXT;
    hashed_pass TEXT;
    activation_token TEXT;
BEGIN
    IF EXISTS(SELECT u.username FROM users u, teacher_details d WHERE u.id = d.user_id AND (u.username = $1 OR d.email = $5)) THEN
        RETURN 'false';
    END IF;
    SELECT * INTO gen_user_id FROM encode(gen_random_bytes(16), 'hex');
    SELECT * INTO gen_teacher_id FROM encode(gen_random_bytes(16), 'hex');
    SELECT * INTO gen_user_salt FROM gen_salt('bf');
    SELECT * INTO hashed_pass FROM encode(digest($2 || gen_user_salt, 'sha256'), 'hex');
    SELECT * INTO activation_token FROM encode(gen_random_bytes(16), 'hex');
    INSERT INTO users (id, username, password, salt, user_type_id) VALUES (gen_user_id, $1, hashed_pass, gen_user_salt, $10);
    INSERT INTO teacher_details (id, user_id, title, first_name, last_name, email, grade, school_name, zip) VALUES (gen_teacher_id, gen_user_id, $3, $4, $5, $6, $7, $8, $9);
    INSERT INTO activation_tokens (user_id, token) VALUES (gen_user_id, activation_token);
    RETURN activation_token;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_sign_in(u_input TEXT, p_input TEXT)
RETURNS TABLE(user_id TEXT, teacher_id TEXT, username NETEXT, user_type_id INTEGER) AS $$
DECLARE
    user_salt TEXT;
    hashed_pass TEXT;
BEGIN
    SELECT u.salt INTO user_salt FROM users u WHERE u.username = $1 AND u.activated = TRUE;
    SELECT * INTO hashed_pass FROM encode(digest($2 || user_salt, 'sha256'), 'hex');
    RETURN QUERY SELECT u.id AS user_id, t.id AS teacher_id, u.username, u.user_type_id AS user_type_id FROM users u, teacher_details t WHERE u.id = t.user_id AND u.username = $1 AND u.password = hashed_pass;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_password_token(e_input TEXT)
RETURNS TEXT AS $$
DECLARE
    get_user_id TEXT;
    gen_token TEXT;
    gen_exp BIGINT;
BEGIN
    SELECT d.user_id INTO get_user_id FROM teacher_details d WHERE d.email = $1;
    IF get_user_id IS NULL THEN
      RETURN 'false';
    END IF;
    SELECT * INTO gen_token FROM encode(gen_random_bytes(8), 'hex');
    SELECT * INTO gen_exp FROM extract(epoch from now());
    gen_exp := gen_exp + 60 * 60 * 24;
    INSERT INTO password_tokens (user_id, token, exp) VALUES (get_user_id, gen_token, gen_exp);
    RETURN gen_token;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_reset_password(e_input TEXT, t_input TEXT, p_input PASSWORD)
RETURNS TEXT AS $$
DECLARE
    get_user_id TEXT;
    get_exp BIGINT;
    gen_user_salt TEXT;
    hashed_pass TEXT;
BEGIN
    SELECT t.user_id, t.exp INTO get_user_id, get_exp FROM teacher_details d, password_tokens t WHERE t.user_id = d.user_id AND d.email = $1 AND t.token = $2;
    IF get_user_id IS NULL THEN
      RETURN 'email';
    END IF;
    IF get_exp < extract(epoch from now()) THEN
      RETURN 'expired';
    END IF;
    SELECT * INTO gen_user_salt FROM gen_salt('bf');
    SELECT * INTO hashed_pass FROM encode(digest($3 || gen_user_salt, 'sha256'), 'hex');
    UPDATE users u SET password = hashed_pass, salt = gen_user_salt WHERE u.id = get_user_id;
    RETURN 'true';
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_change_password(u_input TEXT, op_input TEXT, np_input PASSWORD)
RETURNS TEXT AS $$
DECLARE
    old_user_salt TEXT;
    old_hashed_pass TEXT;
    new_user_salt TEXT;
    new_hashed_pass TEXT;
BEGIN
    SELECT salt INTO old_user_salt FROM users WHERE id = $1 AND activated = TRUE;
    IF old_user_salt IS NULL THEN
      RETURN 'user';
    END IF;
    SELECT * INTO old_hashed_pass FROM encode(digest($2 || old_user_salt, 'sha256'), 'hex');
    IF NOT EXISTS(SELECT * FROM users WHERE id = $1 AND password = old_hashed_pass) THEN
        RETURN 'password';
    END IF;
    SELECT * INTO new_user_salt FROM gen_salt('bf');
    SELECT * INTO new_hashed_pass FROM encode(digest($3 || new_user_salt, 'sha256'), 'hex');
    UPDATE users SET password = new_hashed_pass, salt = new_user_salt WHERE id = $1;
    RETURN 'true';
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_activate_account(t_input TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    get_user_id TEXT;
BEGIN
    SELECT t.user_id INTO get_user_id FROM activation_tokens t WHERE t.token = $1;
    IF get_user_id IS NULL THEN
      RETURN FALSE;
    END IF;
    UPDATE users u SET activated = TRUE WHERE u.id = get_user_id;
    RETURN TRUE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_forgot_username(e_input TEXT)
RETURNS TEXT AS $$
DECLARE
    get_username TEXT;
BEGIN
    SELECT u.username INTO get_username FROM users u, teacher_details d WHERE u.id = d.user_id AND d.email = $1;
    IF get_username IS NULL THEN
      RETURN 'false';
    END IF;
    RETURN get_username;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_check_out(t_input TEXT, b_input INTEGER, s_input INTEGER, d_input BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
    gen_date BIGINT;
BEGIN
    IF EXISTS(SELECT * FROM checked_out_books WHERE teacher_id = $1 AND book_id = $2 AND student_id = $3 AND date_in IS NULL) THEN
        RETURN FALSE;
    END IF;
    SELECT * INTO gen_date FROM extract(epoch from now() at time zone 'utc');
    INSERT INTO checked_out_books (teacher_id, book_id, student_id, date_due, date_out) VALUES ($1, $2, $3, $4, gen_date);
    UPDATE teacher_books SET number_in = number_in - 1, number_out = number_out + 1 WHERE teacher_id = $1 AND id = $2;
    RETURN TRUE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_check_in(t_input TEXT, b_input INTEGER, s_input INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    gen_date BIGINT;
BEGIN
    IF NOT EXISTS(SELECT * FROM checked_out_books WHERE teacher_id = $1 AND book_id = $2 AND student_id = $3 AND date_in IS NULL) THEN
        RETURN FALSE;
    END IF;
    SELECT * INTO gen_date FROM extract(epoch from now() at time zone 'utc');
    UPDATE checked_out_books SET date_in = gen_date WHERE teacher_id = $1 AND book_id = $2 AND student_id = $3 AND date_in IS NULL;
    UPDATE teacher_books SET number_in = number_in + 1, number_out = number_out - 1 WHERE teacher_id = $1 AND id = $2;
    RETURN TRUE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_check_in_students(t_input TEXT, b_input INTEGER, s_input INTEGER[])
RETURNS BOOLEAN AS $$
DECLARE
    x INTEGER;
    gen_date BIGINT;
BEGIN
    FOREACH x IN ARRAY $3
    LOOP
        IF NOT EXISTS(SELECT * FROM checked_out_books WHERE teacher_id = $1 AND book_id = $2 AND student_id = x AND date_in IS NULL) THEN
            RETURN FALSE;
        END IF;
        SELECT * INTO gen_date FROM extract(epoch from now() at time zone 'utc');
        UPDATE checked_out_books SET date_in = gen_date WHERE teacher_id = $1 AND book_id = $2 AND student_id = x AND date_in IS NULL;
        UPDATE teacher_books SET number_in = number_in + 1, number_out = number_out - 1 WHERE teacher_id = $1 AND id = $2;
    END LOOP;
    RETURN TRUE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_delete_book(b_input INTEGER, t_input TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF EXISTS(SELECT * FROM checked_out_books WHERE book_id = $1 AND teacher_id = $2 AND date_in IS NULL) THEN
        RETURN FALSE;
    END IF;
    UPDATE teacher_books SET obsolete = TRUE WHERE id = $1 AND teacher_id = $2;
    RETURN TRUE;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_overdue_books(t_input TEXT)
RETURNS TABLE(student_id INTEGER, first_name NETEXT, last_name NETEXT, book_id INTEGER, title NETEXT, date_due BIGINT) AS $$
DECLARE
    gen_date BIGINT;
BEGIN
    SELECT * INTO gen_date FROM extract(epoch from now() at time zone 'utc');
    RETURN QUERY SELECT c.student_id, s.first_name, s.last_name, c.book_id, b.title, c.date_due FROM teacher_books b, students s, checked_out_books c WHERE b.id = c.book_id AND s.id = c.student_id AND c.teacher_id = $1 AND c.date_due < gen_date AND c.date_due IS NOT NULL AND c.date_in IS NULL ORDER BY c.date_due DESC, s.last_name;
END
$$ LANGUAGE plpgsql;

/* END CREATES */
