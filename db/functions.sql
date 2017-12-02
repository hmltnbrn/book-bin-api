CREATE OR REPLACE FUNCTION cl_sign_up(u_input TEXT, p_input TEXT, t_input TEXT, fn_input TEXT, ln_input TEXT, e_input TEXT, z_input TEXT, sn_input TEXT, r_input INTEGER)
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
    INSERT INTO users (id, username, password, salt, role_id) VALUES (gen_user_id, $1, hashed_pass, gen_user_salt, $9);
    INSERT INTO teacher_details (id, user_id, title, first_name, last_name, email, zip, school_name) VALUES (gen_teacher_id, gen_user_id, $3, $4, $5, $6, $7, $8);
    INSERT INTO activation_tokens (user_id, token) VALUES (gen_user_id, activation_token);
    RETURN activation_token;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_sign_in(u_input TEXT, p_input TEXT)
RETURNS TABLE(user_id TEXT, teacher_id TEXT, username TEXT, role_id INTEGER) AS $$
DECLARE
    user_salt TEXT;
    hashed_pass TEXT;
BEGIN
    SELECT u.salt INTO user_salt FROM users u WHERE u.username = $1 AND u.activated = TRUE;
    SELECT * INTO hashed_pass FROM encode(digest($2 || user_salt, 'sha256'), 'hex');
    RETURN QUERY SELECT u.id AS user_id, t.id AS teacher_id, u.username, u.role_id AS role_id FROM users u, teacher_details t WHERE u.id = t.user_id AND u.username = $1 AND u.password = hashed_pass;
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

CREATE OR REPLACE FUNCTION cl_reset_password(e_input TEXT, t_input TEXT, p_input TEXT)
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
    SELECT * INTO gen_date FROM extract(epoch from now());
    gen_date := gen_date + 60 * 60 * 24;
    INSERT INTO checked_out_books (teacher_id, book_id, student_id, date_due, date_out) VALUES ($1, $2, $3, $4, gen_date);
    UPDATE teacher_books SET number_in = number_in - 1, number_out = number_out + 1 WHERE teacher_id = $1 AND book_id = $2;
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
    SELECT * INTO gen_date FROM extract(epoch from now());
    gen_date := gen_date + 60 * 60 * 24;
    UPDATE checked_out_books SET date_in = gen_date WHERE teacher_id = $1 AND book_id = $2 AND student_id = $3 AND date_in IS NULL;
    UPDATE teacher_books SET number_in = number_in + 1, number_out = number_out - 1 WHERE teacher_id = $1 AND book_id = $2;
    RETURN TRUE;
END
$$ LANGUAGE plpgsql;
