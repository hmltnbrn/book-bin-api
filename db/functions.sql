CREATE OR REPLACE FUNCTION cl_sign_up(u_input TEXT, p_input TEXT, fn_input TEXT, ln_input TEXT, e_input TEXT, z_input TEXT, sn_input TEXT, r_input INTEGER)
RETURNS TEXT AS $$
DECLARE
    gen_user_id TEXT;
    gen_user_salt TEXT;
    hashed_pass TEXT;
    activation_token TEXT;
BEGIN
    IF EXISTS(SELECT u.username FROM users u, user_details d WHERE u.id = d.user_id AND (u.username = $1 OR d.email = $5)) THEN
        RETURN 'false';
    END IF;
    SELECT * INTO gen_user_id FROM encode(gen_random_bytes(16), 'hex');
    SELECT * INTO gen_user_salt FROM gen_salt('bf');
    SELECT * INTO hashed_pass FROM encode(digest($2 || gen_user_salt, 'sha256'), 'hex');
    SELECT * INTO activation_token FROM encode(gen_random_bytes(16), 'hex');
    INSERT INTO users (id, username, password, salt) VALUES (gen_user_id, $1, hashed_pass, gen_user_salt);
    INSERT INTO user_details (user_id, first_name, last_name, email, zip, school_name, role_id) VALUES (gen_user_id, $3, $4, $5, $6, $7, $8);
    INSERT INTO activation_tokens (user_id, token) VALUES (gen_user_id, activation_token);
    RETURN activation_token;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_sign_in(u_input TEXT, p_input TEXT)
RETURNS TABLE(id TEXT, username TEXT) AS $$
DECLARE
    user_salt TEXT;
    hashed_pass TEXT;
BEGIN
    SELECT u.salt INTO user_salt FROM users u WHERE u.username = $1 AND u.activated = TRUE;
    SELECT * INTO hashed_pass FROM encode(digest($2 || user_salt, 'sha256'), 'hex');
    RETURN QUERY SELECT u.id, u.username FROM users u WHERE u.username = $1 AND u.password = hashed_pass;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cl_password_token(e_input TEXT)
RETURNS TEXT AS $$
DECLARE
    get_user_id TEXT;
    gen_token TEXT;
    gen_exp BIGINT;
BEGIN
    SELECT d.user_id INTO get_user_id FROM user_details d WHERE d.email = $1;
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
RETURNS BOOLEAN AS $$
DECLARE
    get_user_id TEXT;
    get_exp BIGINT;
    gen_user_salt TEXT;
    hashed_pass TEXT;
BEGIN
    SELECT t.user_id, t.exp INTO get_user_id, get_exp FROM user_details d, password_tokens t WHERE t.user_id = d.user_id AND d.email = $1 AND t.token = $2;
    IF get_user_id IS NULL THEN
      RETURN FALSE;
    END IF;
    IF get_exp < extract(epoch from now()) THEN
      RETURN FALSE;
    END IF;
    SELECT * INTO gen_user_salt FROM gen_salt('bf');
    SELECT * INTO hashed_pass FROM encode(digest($3 || gen_user_salt, 'sha256'), 'hex');
    UPDATE users u SET password = hashed_pass, salt = gen_user_salt WHERE u.id = get_user_id;
    RETURN TRUE;
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
