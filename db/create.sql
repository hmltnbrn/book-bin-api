-- DROP COMMANDS

DROP FUNCTION IF EXISTS cl_sign_up(u_input text, p_input password, t_input text, fn_input text, ln_input text, e_input text, z_input text, sn_input text, r_input integer);
DROP FUNCTION IF EXISTS cl_sign_in(u_input text, p_input text);
DROP FUNCTION IF EXISTS cl_password_token(e_input text);
DROP FUNCTION IF EXISTS cl_reset_password(e_input text, t_input text, p_input password);
DROP FUNCTION IF EXISTS cl_activate_account(t_input text);
DROP FUNCTION IF EXISTS cl_forgot_username(e_input text);
DROP FUNCTION IF EXISTS cl_check_out(t_input text, b_input integer, s_input integer, d_input bigint);
DROP FUNCTION IF EXISTS cl_check_in(t_input text, b_input integer, s_input integer);
DROP FUNCTION IF EXISTS cl_check_in_students(t_input text, b_input integer, s_input integer[]);
DROP FUNCTION IF EXISTS cl_delete_book(b_input integer, t_input text);
DROP FUNCTION IF EXISTS cl_overdue_books(t_input text);

DROP VIEW IF EXISTS student_books_view;

DROP TABLE IF EXISTS users
, user_roles
, teacher_details
, librarian_details
, teacher_books
, classes
, students
, checked_out_books
, activation_tokens
, password_tokens;

DROP DOMAIN IF EXISTS NETEXT;
DROP DOMAIN IF EXISTS PASSWORD;
DROP DOMAIN IF EXISTS EMAIL;
DROP DOMAIN IF EXISTS ZIPCODE;

-- CREATE DOMAINS

CREATE DOMAIN NETEXT AS TEXT
CONSTRAINT not_empty CHECK (LENGTH(VALUE) > 0);

CREATE DOMAIN PASSWORD AS TEXT
CONSTRAINT valid_password CHECK (VALUE ~ '^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()])[A-Za-z\d!@#$%^&*()]{8,}');

CREATE DOMAIN EMAIL AS TEXT
CONSTRAINT valid_email CHECK (VALUE ~ '^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$');

CREATE DOMAIN ZIPCODE AS TEXT
CONSTRAINT valid_zip CHECK (VALUE ~ '^\d{5}$');

-- CREATE TABLES

CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY NOT NULL,
    name TEXT NOT NULL
); /* Administrator, Teacher, Librarian */

CREATE TABLE users (
    id TEXT PRIMARY KEY NOT NULL,
    username NETEXT NOT NULL,
    password NETEXT NOT NULL,
    salt TEXT NOT NULL,
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
    zip ZIPCODE NOT NULL,
    school_name NETEXT NOT NULL
);

CREATE TABLE classes (
    id SERIAL PRIMARY KEY NOT NULL,
    teacher_id TEXT NOT NULL REFERENCES teacher_details (id),
    name NETEXT NOT NULL,
    obsolete BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE students (
    id SERIAL PRIMARY KEY NOT NULL,
    first_name NETEXT NOT NULL,
    last_name NETEXT NOT NULL,
    email EMAIL,
    reading_level TEXT,
    class_id INTEGER NOT NULL REFERENCES classes (id),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    obsolete BOOLEAN NOT NULL DEFAULT FALSE
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

-- INSERT DUMMY DATA

INSERT INTO user_roles (name) VALUES
 ('Administrator')
,('Teacher')
,('Librarian');

INSERT INTO users (id, username, password, salt, role_id, activated) VALUES
 ('317a22933f23e46593fbabe76ff82d1e','hmltnbrn','e970fab4c326d04961148e659985994c183f08a966bb8d725f35dc748699f795','$2a$06$qiGav.GHV1Z3rljxUZcxye',2,TRUE);

INSERT INTO teacher_details (id, user_id, title, first_name, last_name, email, zip, school_name) VALUES
 ('9a237f7c6bbd539586f27b43d87183e5','317a22933f23e46593fbabe76ff82d1e','Mr.','Brian','Hamilton','hmltnbrn@gmail.com','11105','Wagner Middle School');

INSERT INTO classes (teacher_id, name) VALUES
 ('9a237f7c6bbd539586f27b43d87183e5', '613')
,('9a237f7c6bbd539586f27b43d87183e5', '614')
,('9a237f7c6bbd539586f27b43d87183e5', '615');

INSERT INTO students (first_name, last_name, email, reading_level, class_id) VALUES
 ('Brian','Roberts','brian.roberts@school.com','Z',1)
,('Kevin','Costner','kevin.costner@school.com','H',1)
,('Hiram','Catz','hiram.catz@school.com','F',1)
,('David','Yahoo','david.yahoo@school.com','Y',1)
,('Olivia','Wilde','olivia.wilde@school.com','W',1)
,('Barack','Obama','barack.obama@school.com','Z',2)
,('Helen','Keller','helen.keller@school.com','O',2)
,('Donald','Trump','donald.trump@school.com','A',2)
,('George','Bush','george.bush@school.com','D',2)
,('Beverly','Crusher','beverly.crusher@school.com','W',2)
,('Hillary','Clinton','hillary.clinton@school.com','J',2)
,('James','Cook','james.cook@school.com','J',3)
,('Eleanor','Roosevelt','eleanor.roosevelt@school.com','U',3)
,('Bill','James','bill.james@school.com','V',3)
,('Joseph','Biden','joseph.biden@school.com','O',3)
,('Jane','Seymour','jane.seymour@school.com','H',3);

INSERT INTO teacher_books (teacher_id, title, author, genres, description, reading_level, number_in, number_out) VALUES
 ('9a237f7c6bbd539586f27b43d87183e5','1984','George Orwell','{"Classics","Science Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','145th Street: Short Stories','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Break with Charity: A Story About the Salem Witch Trials','Ann Rinaldi','{"Historical Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Cool Moonlight','Angela Johnson','{"Realistic Fiction"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Corner of the Universe','Ann M. Martin','{"Realistic Fiction"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A James Bond Adventure: Hurricane Gold','Charlie Higson','{"Adventure"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Jigsaw Jones Mystery: The Case of the Christmas Snowman (Book 2)','James Preller','{"Mystery"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Jigsaw Jones Mystery: The Case of the Secret Valentine (Book 3)','James Preller','{"Mystery"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Jigsaw Jones Mystery: The Case of the Spooky Sleepover (Book 4)','James Preller','{"Mystery"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Jigsaw Jones Mystery: The Case of the Stolen Baseball Cards (Book 5)','James Preller','{"Mystery"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Little Princess','Frances Hodgson Burnett','{"Classics"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Long Walk to Water','Linda Sue Park','{"Realistic Fiction"}','Description of book goes here.','RST',6,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: A Matter of Trust','Anne Schraff','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Austere Academy (Book 5)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Bad Beginning (Book 1)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Carniverous Carnival (Book 9)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The End (Book 13)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Ersatz Elevator (Book 6)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Grim Grotto (Book 11)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Miserable Mill (Book 4)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Penultimate Peril (Book 12)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Reptile Room (Book 2)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Slippery Slope (Book 10)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Vile Village (Book 7)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Wide Window (Book 3)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Series of Unfortunate Events: The Hostile Hospital (Book 8)','Lemony Snicket','{"Adventure"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Single Shard','Linda Sue Park','{"Historical Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Step From Heaven','An Na','{"Multicultural"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Swiftly Tilting Planet','Madeleine L''Engle','{"Science Fiction"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Tale Dark and Grimm','Adam Gidwitz','{"Mystery/Horror"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Wind in the Door','Madeleine L''Engle','{"Fantasy"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Wrinkle in Time','Madeleine L''Engle','{"Science Fiction"}','Description of book goes here.','W',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','A Zombie''s Guide to the Human Body: Tasty Tidbits From Head to Toe','Paul Beck','{"Non-Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Adam Canfield of the Slash','Michael Winerip','{"Mystery"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Adrift: Seventy-six Days Lost at Sea','Steven Callahan','{"Memoir"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Adventures of Amelia Bedelia','Peggy Parish','{"Humor"}','Description of book goes here.','L',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alex Rider: Ark Angel (Book 6)','Anthony Horowitz','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alex Rider: Crocodile Tears (Book 8)','Anthony Horowitz','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alex Rider: Eagle Strike (Book 4)','Anthony Horowitz','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alex Rider: Point Blank (Book 2)','Anthony Horowitz','{"Adventure"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alex Rider: Scorpia Rising (Book 9)','Anthony Horowitz','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alex Rider: Skeleton Key (Book 3)','Anthony Horowitz','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alex Rider: Snakehead (Book 7)','Anthony Horowitz','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alice''s Adventure in Wonderland','Lewis Carroll','{"Classics"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Alien on a Rampage','Clete Barrett Smith','{"Science Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Almost Home','Joan Bauer','{"Realistic Fiction"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','An Island Like You: Stories of the Barrio','Judith Ortiz Cofer','{"Short Stories"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Alien (Book 8)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Beginning (Book 54)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Change (Book 13)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Conspiracy (Book 31)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Departure (Book 19)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Discovery (Book 20)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Encounter (Book 3)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Escape (Book 15)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Forgotten (Book 11)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Invasion (Book 1)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Predator (Book 5)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Pretender (Book 23)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Prophesy (Book 34)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Return (Book 48)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Secret (Book 9)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Separation (Book 32)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Sickness (Book 29)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Suspicion (Book 24)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Threat (Book 21)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Unknown (Book 14)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Animorphs: The Warning (Book 16)','K.A. Applegate','{"Science Fiction"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Any Small Goodness: A novel of the Barrio','Tony Johnston','{"Multicultural"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Are You There God? It''s Me, Margaret.','Judy Blume','{"Realistic Fiction"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Artemis Fowl: Artemis Fowl (Book 1)','Eoin Colfer','{"Fantasy"}','Description of book goes here.','X',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','Artemis Fowl: The Enternity Code (Book 3)','Eoin Colfer','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Artemis Fowl: The Eternity Code (Book 3)','Eoin Colfer','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Artemis Fowl: The Opal Deception (Book 4)','Eoin Colfer','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Artemis Fowl: The Time Paradox (Book 6)','Eoin Colfer','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','At Her Majesty''s Request: An African Princess in Victorian England','Walter Dean Myers','{"Historical Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bad Boy','Walter Dean Myers','{"Memoir"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Baseball in April and Other Stories','Gary Soto','{"Short Stories"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Beast Quest: Ferno The Fire Dragon (Book 1)','Adam Blade','{"Fantasy"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Beast Quest: Sepron The Sea Serpent (Book 2)','Adam Blade','{"Fantasy"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Beauty: A Retelling of the Story of Beauty and the Beast','Robin McKinley','{"Fantasy"}','Description of book goes here.','Y',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Because of Mr. Terupt','Rob Buyea','{"Realistic Fiction"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Because of Winn-Dixie','Kate DiCamillo','{"Realistic Fiction"}','Description of book goes here.','M',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Becoming Joe DiMaggio','Maria Testa','{"Poetry"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Becoming Naomi Leon','Pam Munoz Ryan','{"Realistic Fiction"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Before We Were Free','Julia Alvarez','{"Historical Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Between Madison and Palmetto','Jacqueline Woodson','{"Realistic Fiction"}','Description of book goes here.','OPQ',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Between Shades of Gray','Ruta Sepetys','{"Historical Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Beyond Magenta: Transgender Teens Speak Out','Susan Kuklin','{"Non-Fiction/LGBT"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Big Mouth & Ugly Girl','Joyce Carol Oates','{"Realistic Fiction"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Black Potatoes: The Story of the Great Irish Famine, 1845-1850','Susan Campbell Bartoletti','{"Non-Fiction"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Blink: The Power of Thinking Without Thinking','Malcolm Gladwell','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bloomability','Sharon Creech','{"Realistic Fiction"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Blubber','Judy Blume','{"Realistic Fiction"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: A Matter of Trust (Book 2)','Anne Schraff','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: Blood Is Thicker (Book 8)','Paul Langan & D.M. Blackwell','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: Brothers in Arms (Book 9)','Paul Langan & Ben Alirez','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: Lost and Found (Book 1)','Anne Schraff','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: Payback (Book 6)','Paul Langan','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: Secrets in the Shadows (Book 3)','Anne Schraff','{"Realistic Fiction"}','Description of book goes here.','Z',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: Someone to Love Me (Book 4)','Anne Schraff','{"Realistic Fiction"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: Summer of Secrets (Book 10)','Paul Langan','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: The Bully (Book 5)','Paul Langan','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bluford High: The Fallen (Book 11)','Paul Langan','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bomb: The Race to Build--and Steal--the World''s Most Dangerous Weapon','Steve Sheinkin','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bound to You','Christopher Pike','{"Romance/Thriller"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bridge to Terabithia','Katherine Paterson','{"Fantasy"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bronx Masquerade','Nikki Grimes','{"Realistic Fiction/Poetry"}','Description of book goes here.','Z',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bud, Not Buddy','Christopher Paul Curtis','{"Historical Fiction"}','Description of book goes here.','U',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Bunnicula: A Rabbit-Tale of Mystery','James Howe','{"Mystery"}','Description of book goes here.','Q',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Call Me Maria','Judith Ortiz Coler','{"Realistic Fiction"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Cam Jansen: The Mystery at the Haunted House (Book 13)','David A. Adler','{"Mystery"}','Description of book goes here.','L',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Cam Jansen: The Mystery of the Dinosaur Bones (Book 3)','David A. Adler','{"Mystery"}','Description of book goes here.','L',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Cam Jansen: The Mystery of the U.F.O. (Book 2)','David A. Adler','{"Mystery"}','Description of book goes here.','L',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Charlie and the Great Glass Elevator','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','R',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Charlie and the Chocolate Factory','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','R',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Charlie Bone and the Hidden King (Book 5)','Jenny Nimmo','{"Adventure"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Charlotte''s Web','E.B. White','{"Fantasy/Classics"}','Description of book goes here.','R',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Chet Gecko Mysteries: Farewell, My Lunchbag (Book 3)','Bruce Hale','{"Mystery"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Chet Gecko Mysteries: The Malted Falcon (Book 7)','Bruce Hale','{"Mystery"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Chicken Boy','Frances O''Roark Dowell','{"Realistic Fiction"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Children of the River','Linda Crew','{"Multicultural"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Childtimes: A Three-Generation Memoir','Eloise Greenfield & Lessie Jones Little','{"Memoir"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Chinatown Mystery: The Case of the Goblin Pearls (Book 1)','Christopher Yip','{"Mystery"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Chronicles of Ancient Darkness: Soul Eater (Book 3)','Michelle Paver','{"Adventure"}','Description of book goes here.','OPQ',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Chronicles of Ancient Darkness: Spirit Walker (Book 2)','Michelle Paver','{"Adventure"}','Description of book goes here.','OPQ',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Chronicles of Ancient Darkness: Wolf Brother (Book 1)','Michelle Paver','{"Adventure"}','Description of book goes here.','OPQ',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Circle of Magic: Daja''s Book (Book 3)','Tamora Pierce','{"Fantasy"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Circle of Magic: Sandry''s Book (Book 1)','Tamora Pierce','{"Fantasy"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Circle of Magic: Tris''s Book (Book 2)','Tamora Pierce','{"Fantasy"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Cirque Du Freak: Tunnels of Blood (Book 3)','Darren Shan','{"Mystery/Horror"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Code Talker: A Novel About the Navajo Marines of World War Two','Joseph Bruchac','{"Historical Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Come A Stranger','Cynthia Voigt','{"Realistic Fiction"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Confessions of a Murder Suspect','James Patterson & Maxine Paetro','{"Adventure"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Coraline','Neil Gaiman','{"Mystery"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Cover-Up: Mystery at the Super Bowl','John Feinstein','{"Mystery/Sports"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Crystal','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','W',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Curveball, The Year I Lost My Grip','Jordan Sonnenblick','{"Realistic Fiction/Sports"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Daniel X: The Dangerous Days Daniel X (Book 1)','James Patterson & Michael Ledwidge','{"Science Ficiton"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Daniel X: Watch the Skies (Book 2)','James Patterson & Ned Rust','{"Science Ficiton"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Danny the Champion of the World','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dare Truth or Promise','Paula Boock','{"Realistic Fiction/LQBT"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dark Victory: A Novel is the Alien Resistance','Brendan DuBois','{"Science Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Darkness Before Dawn','Sharon M. Draper','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Darnell Rock Reporting','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','S',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: A Coal Miner''s Bride: The Diary of Anetka Kaminska','Susan Campbell Bartoletti','{"Historical Fiction"}','Description of book goes here.','UVW',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: A Light in the Storm: The Civil War Diary of Amelia Martin','Karen Hesse','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: A Picture of Freedom: The Diary of Clotee, a Slave Girl','Patricia C. Mckissack','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: A Time for Courage: The Suffragette Diary of Kathleen Bowen','Kristina Gregory','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: A Time for Courage: The Suffragette Diary of Kathleen Bowen','Kathryn Lasky','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: Dreams in the Golden Country: The Diary of Zipporah Feldman, a Jewish Immigrant Girl','Kathryn Lasky','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: Early Sunday Morning: The Pearl Harbor Diary of Amber Billows','Barry Denenberg','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: My Secret War: The World War II Diary of Madeline Beck','Mary Pope Osborne','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: Seeds of Hope: The Gold Rush Diary of Susanna FairChild','Kristina Gregory','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: So Far from Home: The Diary of Mary Driscoll, an Irish Mill Girl','Barry Denenberg','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: Standing in the Light: The Captide Diary of Catharine Carey Logan','Mary Pope Osborne','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: The Great Railroad Race: The Diary of Libby West','Kristina Gregory','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: The Winter of Red Snow: The Revolutionary war Diary of Abgail Jane Stewart','Kristina Gregory','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear America: When Will This Cruel Was be Over?: The Civil War Diary of Emma Simpson','Barry Denenberg','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear Dr. Bell... Your Friend, Helen Keller','Judith St. Geroge','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dear Mr. Henshaw','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','Q',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Decisive: How to Make Better Choices in Life and Work','Chip Heath & Dan Heath','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Define "Normal"','Julie Anne Peters','{"Realistic Fiction"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Deltora Quest: City of The Rats (Book 3)','Emily Rodda','{"Fantasy"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Deltora Quest: Dread Mountain (Book 5)','Emily Rodda','{"Fantasy"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Deltora Quest: The Forests of Silence (Book 1)','Emily Rodda','{"Fantasy"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Deltora Quest: The Lake of Tears (Book 2)','Emily Rodda','{"Fantasy"}','Description of book goes here.','N',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Deltora Quest: The Shifting Sands (Book 4)','Emily Rodda','{"Fantasy"}','Description of book goes here.','N',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Deltora ShadowLands:  The ShadowLands (Book 3)','Emily Rodda','{"Fantasy"}','Description of book goes here.','N',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','Diary of a Wimpy Kid (Book 1)','Jeff Kinney','{"Humor"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Diary of a Wimpy Kid: Hard Luck','Jeff Kinney','{"Humor"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tillerman: Dicey''s Song (Book 2)','Cynthia Voigt','{"Realistic Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dog Walker','Karen Spafford-Fitz','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dogsong','Gary Paulson','{"Adventure"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Double Dutch','Sharon M. Draper','{"Realistic Fiction"}','Description of book goes here.','T',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Dragon Rider','Cornelia Funke','{"Fantasy"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Drums, Girls, and Dangerous Pie','Jordan Sonnenblick','{"Realistic Fiction"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Eating Animals','Jonathan Safran Foer','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','El Guero: A True Adventure Story','Elizabeth Borton de Trevino','{"Multicultural"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Elephant Run','Roland Smith','{"Historical Fiction"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Eleven','Patricia Reilly Giff','{"Mystery"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ella Enchanted','Gail Carson Levine','{"Fantasy"}','Description of book goes here.','U',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Emily Windsnap and the Castle in the Mist','Liz Kessler','{"Fantasy"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Empty','Suzanne Weyn','{"Adventure"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ender''s Game','Orson Scott Card','{"Science Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ereth''s Birthday','Avi','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Escape From Mr. Lemoncello''s Library','Chris Grabenstein','{"Mystery"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Esio Trot','Roald Dahl','{"Humor"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Esperanza Rising','Pam Munoz Ryan','{"Multicultural"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Everest: The Climb (Book 2)','Gordon Korman','{"Adventure"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Everest: The Contest (Book 1)','Gordon Korman','{"Adventure"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Everest: The Summit (Book 3)','Gordon Korman','{"Adventure"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Every You, Every Me','David Levithan','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Fairest','Gail Carson Levine','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Fairway Phenom','Matt Christopher','{"Realistic Fiction/Sports"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Famous Dead People: Henry VIII and His Chopping Block','Alan Macdonald','{"Biography"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Fantastic Mr. Fox','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Far Flung Adventures: Corby Flood (Book 2)','Paul Stewart & Chris Riddell','{"Adventure"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Far Flung Adventures: Fergus Crane (Book 1)','Paul Stewart & Chris Riddell','{"Adventure"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Flesh and Blood So Cheap: The Triangle Fire and Its Legacy','Albert Marrin','{"Non-Fiction"}','Description of book goes here.','XYZ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Flowers for Algernon','Daniel Keyes','{"Science Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Flush','Carl Hiaasen','{"Realistic Fiction"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Fourth Grade Rats','Jerry Spinelli','{"Realistic Fiction"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Freedom''s Children: Young Civil Roghts Activists Tell Their Own Stories','Ellen Levine','{"Memoir"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Friction','E.R. Frank','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Gathering Blue','Lois Lowry','{"Dytopian"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Geek Girl (Book 1)','Holly Smale','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Geek Magnet','Kieran Scott','{"Realistic Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Generation Green: The Ultimate Teen Guide to Living an Eco-Friendly Life','Linda Silvertsen & Tosh Silvertsen','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Genius of Common Sense: Jane Jacobs and the Story of the Death and Life of Great American Cities','Glenna Lang & Marjory Wunsch','{"Non-Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Geoge''s Marvelous Medicine','Roald Dahl','{"Humor"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','George Washington''s Socks','Elvira Woodruff','{"Historical Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','George''s Secret Key to the Universe (Book 1)','Lucy Hawking & Stephen Hawking','{"Science Fiction"}','Description of book goes here.','U',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Go and Come Back','Joan Abelove','{"Multicultural"}','Description of book goes here.','OPQ',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Going Solo','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','T',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: Attack of the Mutant','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: Beware, the Snowman!','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: How to Kill a Monster','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: It Came From Beneath the Sink','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: Stay Out of the Basement','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: The Blob That Ate Everyone','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: Why I''m Afraid of Bees','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Goosebumps: You Can''t Scare Me!','R.L. Stine','{"Mystery/Horror"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Guardians of Ga''Hoole: The Capture (Book 1)','Kathryn Lasky','{"Fantasy"}','Description of book goes here.','R',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Guardians of Ga''Hoole: The Rescue (Book 3)','Kathryn Lasky','{"Fantasy"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Guardians of Ga''Hoole: The Shattering (Book 5)','Kathryn Lasky','{"Fantasy"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Guardians of Ga''Hoole: The Siege (Book 4)','Kathryn Lasky','{"Fantasy"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Habibi','Naomi Shihab Nye','{"Multicultural"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Handbook for Boys','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hannah Montana: Rock the Waves','Suzanne Harper','{"Realistic Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hard Drive to Short','Matt Christopher','{"Realistic Fiction/Sports"}','Description of book goes here.','M',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Harriet Tubman, Secret Agent: How Daring Slaves and Free Blacks Spied for the Union During the Civil War','Thomas B. Allen','{"Biography"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Harry Potter and the Deathly Hallows (Book 7)','J.K. Rowling','{"Fantasy/Adventure"}','Description of book goes here.','Z',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Harry Potter and the Goblet of Fire (Book 4)','J.K. Rowling','{"Fantasy/Adventure"}','Description of book goes here.','W',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Harry Potter and the Half-Blood Prince (Book 6)','J.K. Rowling','{"Fantasy/Adventure"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Harry Potter and the Order of the Phoenix (Book 5)','J.K. Rowling','{"Fantasy/Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Harry Potter and the Prisoner of Azkaban (Book 3)','J.K. Rowling','{"Fantasy/Adventure"}','Description of book goes here.','W',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hatchet','Gary Paulson','{"Adventure"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Heartbeat','Sharon Creech','{"Realistic Fiction/Poetry"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Heat','Mike Lupica','{"Realistic Fiction/Sports"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Henry and the Paper Route','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Henry Huggins','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Heroes of Olympus: The Demigod Diaries (Extra)','Rick Riordan','{"Fantasy"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Heroes of Olympus: The Lost Hero (Book 1)','Rick Riordan','{"Fantasy"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Heroes of Olympus: The Mark of Athena (Book 3)','Rick Riordan','{"Fantasy"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Heroes of Olympus: The Son of Neptune (Book 2)','Rick Riordan','{"Fantasy"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','His Dark Materials: The Amber Spyglass (Book 3)','Philip Pullman','{"Fantasy"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Holes','Louis Sachar','{"Realistic Fiction"}','Description of book goes here.','V',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','Homeboyz','Alan Lawrence Sitomer','{"Realistic Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Homeless Bird','Gloria Whelan','{"Multicultural"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hoops','Walter Dean Myers','{"Realistic Fiction/Sports"}','Description of book goes here.','X',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','How I Survived Being a Girl','Wendelin Can Draanen','{"Realistic Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','How to Rock Braces and Glasses','Meg Haston','{"Realistic Fiction"}','Description of book goes here.',NULL,2,0)
,('9a237f7c6bbd539586f27b43d87183e5','How to Write Haiku and Other Short Poems','Paul Janeczko','{"How To/Poetry"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Howliday Inn','James Howe','{"Mystery"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hunger Games Trilogy: Catching Fire (Book 2)','Suzanne Collins','{"Fantasy/Dystopian"}','Description of book goes here.','Z',6,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hunger Games Trilogy: Mockingjay (Book 3)','Suzanne Collins','{"Fantasy/Dystopian"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hunger Games Trilogy: The Hunger Games (Book 1)','Suzanne Collins','{"Fantasy/Dystopian"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Hush','Jacqueline Woodson','{"Realistic Fiction"}','Description of book goes here.','Y',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','I Am Malala: How One Girl Stood Up for Education and Changed the World','Malala Yousafzai','{"Autobiography"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','I Can''t Believe I Have to do This','Jan Alford','{"Realistic Fiction"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','I Know Caged Bird Sings','Maya Angelou','{"Memoir"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','I Was a Rat!','Philip Pullman','{"Adventure"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','I''m nobody! Who are you?: Poems by Emily Dickinson','Emily Dickinson','{"Poetry"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ice Magic','Matt Christopher','{"Realistic Fiction/Sports"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ida B','Katherine Hannigan','{"Realistic Fiction"}','Description of book goes here.','S',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Identical','Ellen Hopkins','{"Poetry/Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Iggie''s House','Judy Blume','{"Realistic Fiction"}','Description of book goes here.','R',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Illusion','Christina Yelich-Koth','{"Science Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','In the Time of the Butterflies','Julia Alvarez','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Indigo Star','Hilary McKay','{"Realistic Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Island of the Blue Dolphins','Scott O''Dell','{"Historical Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','It''s Not the End of the World','Judy Blume','{"Realistic Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Jacob I Have Loved','Katherine Paterson','{"Realistic Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','James and the Giant Peach','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','Q',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Jane Eyre','Charlotte Bronte','{"Classics"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Joey Pigza Swallowed the Key','Jack Gantos','{"Realistic Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones and a Little Monkey Business (Book 2)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones and Her Big Fat Mouth (Book 3)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones and Some Sneaky Peeky Spying (Book 4)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones and the Yucky Blucky Fruitcake (Book 5)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones Has a Monster Under Her Bed (Book 8)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones Has a Peep in Her Pocket (Book 15)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones Is a Party Animal (Book 10)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Junie B. Jones Loves Handsome Warren (Book 7)','Barbara Park','{"Humor"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Just as Long as We''re Together','Judy Blume','{"Realistic Fiction"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Kinda Like Brothers','Coe Booth','{"Realistic Fiction"}','Description of book goes here.','OPQ',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Kiss Me, Kill Me','Lauren Henderson','{"Mystery"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Knots in My Yo-Yo String','Jerry Spinelli','{"Autobiography"}','Description of book goes here.','U',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Last Summer with Maizon','Jacqueline Woodson','{"Realistic Fiction"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Leap Day','Wendy Mass','{"Fantasy"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Letter from a Nut','Jed L. Nancy','{"Realistic Fiction/Humor"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Letters From Rifka','Karen Hesse','{"Historical Fiction"}','Description of book goes here.','S',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Leven Thumps and The Ruins of Alder (Book 1)','Obert Skye','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Leven Thumps and the Whispered Secret (Book 2)','Obert Skye','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Like Sisters on the Homefront','Rita Williams-Garcia','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Lincoln: A Photobiography','Russell Freedman','{"Non-Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Listening for Lions','Gloria Whelan','{"Historical Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Little Women','Louisa May Alcott','{"Classics"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Living Up the Street','Gary Soto','{"Realistic Fiction"}','Description of book goes here.','Y',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Lizzie Bright and the Buckminster Boy','Gary D. Schmidt','{"Historical Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Locomotion','Jacqueline Woodson','{"Realistic Fiction/Poetry"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Looking for Red','Angela Johnson','{"Realistic Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Lord Edgware Dies','Agatha Christie','{"Mystery"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Lord of the Flies','William Golding','{"Classics"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Loser','Jerry Spinelli','{"Realistic Fiction"}','Description of book goes here.','U',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Love That Dog','Sharon Creech','{"Realistic Fiction/Poetry"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Magic Can Be Murder','Vivian Vande Velde','{"Mystery/Romance"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Magnus Chase and the Gods of Asgard: The Sword of Summer (Book 1)','Rick Riordan','{"Adventure"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Malcolm X: By Any Means Necessary','Walter Dean Myers','{"Biography"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Maniac Magee','Jerry Spinelli','{"Realistic Fiction"}','Description of book goes here.','W',6,0)
,('9a237f7c6bbd539586f27b43d87183e5','Marie Antoinette, Serial Killer','Katie Alender','{"Historical Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Marvin Redpost: Alone in His Teacher''s House (Book 4)','Louis Sachar','{"Humor"}','Description of book goes here.','L',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Marvin Redpost: Is He a Girl? (Book 3)','Louis Sachar','{"Humor"}','Description of book goes here.','M',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Matilda','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','May I Bring a Friend?','Beatrice Schenk De Regniers','{"Learning to Read"}','Description of book goes here.','I',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Me and Earl and the Dying Girl','Jesse Andrews','{"Realistic Fiction"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Me, Mop, and the Moondance Kid','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','S',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Melindy''s Medal','Georgene Faulkner & John Becker','{"Adventure"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Messenger','Lois Lowry','{"Dytopian"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Miracle''s Boys','Jacqueline Woodson','{"Realistic Fiction"}','Description of book goes here.','Z',6,0)
,('9a237f7c6bbd539586f27b43d87183e5','Miss Peregrine''s Peculiar Children (Book 1)','Ransom Riggs','{"Fantasy"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Miss Peregrine''s Peculiar Children: Hollow City (Book 2)','Ransom Riggs','{"Fantasy"}','Description of book goes here.','Z',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Moon Base Alpha: Space Case','Stuart Gibbs','{"Science Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Mouse Tales','Arnold Lobel','{"Learning to Read"}','Description of book goes here.','J',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Mr. Popper''s Penguins','Richard and Floreance Atwater','{"Fantasy/Classic"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Mr. Terupt Falls Again','Rob Buyea','{"Realistic Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Mrs. Frisby and the Rats of Nimh','Robert C. O''Brien','{"Fantasy"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Muggie Maggie','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Life With the Chimpanzees: The Fascinating Story of the World''s Most Celebrated Naturalist','Jane Goodalll','{"Non-Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Name is America: A Journey to the New World: The Diary of Remember Patience Whipple','Kathryn Lasky','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Name is America: The Journal of Biddy Owens: The Negro Leagues','Walter Dean Myers','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Name is America: The Journal of Douglas Allen Deeds: The Donner Party Expedition','Rodman Philbrick','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Name is America: The Journal of James Edmond Pease: A Civil War Union Soldier','Jim Murphy','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Name is America: The Journal of Otto Peltonen: A Finnish Immigrant','William Durbin','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Name is America: The Journal of Scott Penleton Collins: A World War II Soldier','Walter Dean Myers','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Secret Guide to Paris','Lisa Schroeder','{"Realistic Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','My Sister''s Keeper','Jody Piccoult','{"Realistic Fiction"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Naomi and Ely''s No Kiss List','Rachel Cohn & David Levithan','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: A Midsummer Night''s Dream','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: Anthony and Cleopatra','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: As You Like It','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: Henry V','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: Julius Caesar','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: King Lear','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: Macbeth','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: Much Ado About Nothing','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: Romeo and Juliet','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: Sonnets','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: The Merchant of Venice','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: The Taming of the Shrew','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No Fear Shakespeare: The Tempest','William Shakespeare','{"Play"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','No More Dead Dogs','Gordon Korman','{"Realistic Fiction/Humor"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Nobody Was Here: Seventh Grade in the Life of...','Alison Pollet','{"Realistic Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Number the Stars','Lois Lowry','{"Historical Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Oddballs','William Sleator','{"Realistic Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Oh, the Places He Went: A Story About Dr. Seuss','Maryann N. Weidt','{"Biography"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','On the Devil''s Court','Carol Deuker','{"Realistic Fiction/Sports"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','On the Far Side of the Mountain','Jean Craighead George','{"Adventure"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','One + One = Blue','MJ Auch','{"Realistic Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','One Came Home','Amy Timberlake','{"Mystery"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','One Crazy Summer','Rita Williams-Garcia','{"Historical Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Orca: Breathless','Pam Withers','{"Realistic Fiction"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Orca: Daredevil Club','Pam Withers','{"Realistic Fiction"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Orca: Fastback Beach','Shirlee Smith Matheson','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Orca: Flower Power','Ann Walsh','{"Realistic Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Orca: Kicker','Michele Martin Bossley','{"Realistic Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Orca: The Shade','K.L.Denman','{"Realistic Fiction"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Orca: Who Owns Kelly Paddik?','Beth Goobie','{"Adventure"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Out of My Mind','Sharon M. Draper','{"Realistic Fiction"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Out of the Dust','Karen Hesse','{"Historical Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Over Sea, Under Stone','Susan Cooper','{"Adventure"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Peeled','Joan Bauer','{"Realistic Fiction"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pendragon: Black Water (Book 5)','D.J. MacHale','{"Fantasy"}','Description of book goes here.','X',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pendragon: The Lost City of Faar (Book 2)','D.J. MacHale','{"Fantasy"}','Description of book goes here.','X',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pendragon: The Merchant of Death (Book 1)','D.J. MacHale','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pendragon: The Never War (Book 3)','D.J. MacHale','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pendragon: The Reality Bug (Book 4)','D.J. MacHale','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pendragon: The Rivers of Zadaa (Book 6)','D.J. MacHale','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Percy Jackson and the Olympians: The Last Olympian (Book 5)','Rick Riordan','{"Adventure"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Percy Jackson and the Olympians: The Lightning Thief (Book 1)','Rick Riordan','{"Adventure"}','Description of book goes here.','S',6,0)
,('9a237f7c6bbd539586f27b43d87183e5','Percy Jackson and the Olympians: The Lightning Thief (Book 1, Graphic Novel)','Rick Riordan','{"Adventure"}','Description of book goes here.','S',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Percy Jackson and the Olympians: The Sea of Monsters (Book 2)','Rick Riordan','{"Adventure"}','Description of book goes here.','S',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Percy Jackson and the Olympians: The Titan''s Curse (Book 3)','Rick Riordan','{"Adventure"}','Description of book goes here.','S',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Persepolis 2: The Story of a Return','Marijane Satrapi','{"Graphic Novel/Memoir"}','Description of book goes here.','XYZ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Peter Nimble and His Fantastic Eyes','Jonathan Auxier','{"Fantasy"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Peter Pan','J.M. Barrie','{"Classics"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pinky and Rex','James Howe','{"Humor"}','Description of book goes here.','L',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pippa''s Perfect Ponytail','Julie Nickerson','{"Realistic Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pocahontas','Joseph Bruchac','{"Historical Fiction"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Poetry U.S.A.','Paul Molloy (editor)','{"Poetry"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Poop Fountain!','Tom Angleberger','{"Humor"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Poppy','Avi','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Powers','Ursula K. Le Guin','{"Fantasy"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pretty Little Liars','Sara Shepard','{"Mystery"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Pride and Prejudice','Jane Austen','{"Classics"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Project Mulberry','Linda Sue Park','{"Realistic Fiction"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Racing the Sun','Paul Pitts','{"Multicultural"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ragtime','E.L. Doctorow','{"Historical Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ralph S. Mouse','Beverly Clearly','{"Fantasy"}','Description of book goes here.','O',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ramona and her Mother','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ramona Quimby, Age 8','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ramona the Brave','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ramona the Pest','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ramona''s World','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Rat Life','Tedd Arnold','{"Mystery"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Rebel','Willo Davis Roberts','{"Realistic Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Red Thread Sisters','Carol Antoinette Peacock','{"Realistic Fiction"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Redwall','Brian Jacques','{"Fantasy"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Remember Me to Harold Square','Paula Danziger','{"Realistic Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Rescue Josh McGuire','Ben Mikaelsen','{"Adventure"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Return to Howliday Inn','James Howe','{"Mystery"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Revolution','Deborah Wiles','{"Historical Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ribsy','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Rio Grande Stories','Caroline Meyer','{"Multicultural"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ripper','Stefan Petrucha','{"Mystery"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Rissa Bartholomew''s Declaration of Independence','Lynda B. Comerford','{"Realistic Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Rocket Boys','Homer H. Hickam, Jr.','{"Memoir"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Roll of Thunder, Hear My Cry','Mildred D. Taylor','{"Historical Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ruby Holler','Sharon Creech','{"Realistic Fiction"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ruby''s Slippers','Tricia Rayburn','{"Realistic Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Rules of the Road','Joan Bauer','{"Realistic Fiction"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Runaway Ralph','Beverly Clearly','{"Fantasy"}','Description of book goes here.','O',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Sammy Keyes and the Curse of the Moustache Mary','Wendelin Van Draanen','{"Mystery/Adventure"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Scorpion','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Sees Behind Trees','Michael Dorris','{"Historical Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Selection: The Elite (Book 2)','Kiera Cass','{"Fantasy/Romance"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Selection: The Selection (Book 1)','Kiera Cass','{"Fantasy/Romance"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Sense and Sensibility','Jane Austen','{"Classics"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Shadow','Michael Morpurgo','{"Adventure"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Shattered: Stories of Children and War','Jennifer Armstrong (editor)','{"Memoir"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Shooter','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Shooting Kabul','N.H. Senzai','{"Multicultural"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Smiles to Go','Jerry Spinelli','{"Realistic Fiction"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','So You Want to Be a Wizard','Diane Duane','{"Fantasy"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Sold','Patricia McCormick','{"Multicultural"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Soldier Boy','Brian Burks','{"Historical Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Son','Lois Lowry','{"Dystopian"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Song of the Lioness: Alanna the First Adventure (Book 1)','Tamora Pierce','{"Adventure"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Spies of Mississippi: The True Story of the Spy Network That Tried to Destroy the Civil Rights Movement','Rick Bowers','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Spongebob Squarepants: Man Sponge Saves the Day','Sarah Willson','{"Humor"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Spongebob Squarepants: UFO!','Adam Beechen','{"Humor"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Stand Tall','Joan Bauer','{"Realistic Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Stanford Wong Flunks Big-Time','Lisa Yee','{"Realistic Fiction/Sports"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Stargirl','Jerry Spinelli','{"Realistic Fiction"}','Description of book goes here.','V',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','Strider','Beverly Clearly','{"Realistic Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Stuck In Neutral','Terry Trueman','{"Mystery"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Sugar','Jewel Parker Rhodes','{"Historical Fiction"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Superfudge','Judy Blume','{"Realistic Fiction/Humor"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Surprises According to Humphrey','Betty G. Birney','{"Humor"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tales of a Fourth Grade Nothing','Judy Blume','{"Realistic Fiction/Humor"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tangerine','Edward Bloor','{"Realistic Fiction/Sports"}','Description of book goes here.','U',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Ten Great Mysteries','Edgar Allen Poe','{"Mystery/Short Story"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tex','S.E. Hinton','{"Realistic Fiction"}','Description of book goes here.','UVW',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','That Was Then, This Is Now','S.E. Hinton','{"Realistic Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The 39 Clues: In Too Deep (Book 6)','Jude Watson','{"Mystery"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Adventures Huckleberry Finn','Mark Twain','{"Classics"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Autobiography of Malcolm X','Alex Haley','{"Auto-Biography"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Bar Code Tattoo','Suzanne Weyn','{"Mystery"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Best Poems Ever: A Collection of Poetry''s Greatest Voices','Edric S. Mesmer (editor)','{"Poetry"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The BFG','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','U',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Body in the Woods','April Henry','{"Adventure"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Book of Blood: From Legends and Leeches to Vanpires and Veins','HP Newquist','{"Non-Fiction"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Books of Ember: The City of Ember (Book 1)','Jeanne Duprau','{"Fantasy/Dystopian"}','Description of book goes here.','W',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Books of Ember: The Diamon of Darkhold (Book 4)','Jeanne DuPrau','{"Fantasy/Dystopian"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Books of Ember: The People of Sparks (Book 2)','Jeanne Duprau','{"Fantasy/Dystopian"}','Description of book goes here.','W',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Books of Ember: The Prophet of Yonwood (Book 3)','Jeanne DuPrau','{"Fantasy/Dystopian"}','Description of book goes here.','W',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Celery Stalks at Midnight','James Howe','{"Mystery"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Chocolate War','Robert Cormler','{"Realistic Fiction"}','Description of book goes here.','Z',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Chosen','Chaim Potok','{"Classics"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Christopher Killer','Alane Ferguson','{"Mystery"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Chronicles of Narnia: Prince Caspian (Book 4)','C.S. Lewis','{"Fantasy"}','Description of book goes here.','T',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Chronicles of Narnia: The Last Battle (Book 7)','C.S. Lewis','{"Fantasy"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Chronicles of Narnia: The Lion, the Witch, and the Wardrobe (Book 2)','C.S. Lewis','{"Fantasy"}','Description of book goes here.','T',13,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Chronicles of Narnia: The Silver Chair (Book 6)','C.S. Lewis','{"Fantasy"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Chronicles of Narnia: The Voyage of the Dawn Treader (Book 5)','C.S. Lewis','{"Fantasy"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Cupcake Queen','Heather Hepler','{"Realistic Fiction"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Dark-Thirty: Southern Tales of the Supernatural','Patricia C. McKissack','{"Historical Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Dead and the Gone','Susan Beth Pfeffer','{"Science Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Dead Gentleman','Matthew Cody','{"Fantasy"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Demonata: BEC (Book 4)','Darren Shan','{"Mystery/Horror"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Desperate Message from Freeman''s Island','Rachel Nickerson Luna','{"Mystery"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Diary of a Young Girl','Anne Frank','{"Memoir"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Divergent Series: Allegiant (Book 3)','Veronica Roth','{"Fantasy/Dystopian"}','Description of book goes here.','Z',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Divergent Series: Divergent (Book 1)','Veronica Roth','{"Fantasy/Dystopian"}','Description of book goes here.','Z',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Divergent Series: Insurgent (Book 2)','Veronica Roth','{"Fantasy/Dystopian"}','Description of book goes here.','Z',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Dogs','Allan Stratton','{"Mystery"}','Description of book goes here.',NULL,2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Dream Keeper and Other Poems','Langston Hughes','{"Poetry"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Fault in Our Stars','John Green','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The First Part Last','Angela Johnson','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Five Ancestors: Eagle (Book 5)','Jeff Stone','{"Adventure"}','Description of book goes here.','R',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Five Ancestors: Mouse (Book 6)','Jeff Stone','{"Adventure"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Five Ancestors: Snake (Book 3)','Jeff Stone','{"Adventure"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Freedom Writers Diary','The Freedom Writers & Erin Gruwell','{"Memoir"}','Description of book goes here.','Z',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Giver','Lois Lowry','{"Dystopian"}','Description of book goes here.','Y',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Glory Field','Walter Dean Myers','{"Historical Ficiton"}','Description of book goes here.','X',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Goldern Goblet','Eloise Jarvis McGraw','{"Historical Fiction/Mystery"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Greatest Muhammed Ali','Walter Dean Myers','{"Biography"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Heroes of Olympus: The Mark of Athena (Book 4)','Rick Riordan','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Higher Power of Lucky','Susan Patron','{"Realistic Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Hollow','Agatha Christie','{"Mystery"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The House of the Scorpion','Nancy Farmer','{"Adventure"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The House on Mango Street','Sandra Cisneeros','{"Short Stories"}','Description of book goes here.','W',6,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Inheritance Cycle: Eldest (Book 2)','Christopher Paolini','{"Fantasy"}','Description of book goes here.','Y',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Inheritance Cycle: Eragon (Book 1)','Christopher Paolini','{"Fantasy"}','Description of book goes here.','Y',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Inheritance Cycle: Inheritance (Book 4)','Christopher Paolini','{"Fantasy"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Inkheart Trilogy: Inkdeath (Book 3)','Cornelia Funke','{"Fantasy"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Inkheart Trilogy: Inkheart (Book 1)','Cornelia Funke','{"Fantasy"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Inkheart Trilogy: Inkspell (Book 2)','Cornelia Funke','{"Fantasy"}','Description of book goes here.','T',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Iron King','Julie Kagawa','{"Romance/Fantasy"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Kane Chroncles: The Throne of Fire (Book 2)','Rick Riordan','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Kane Chronicles: The Red Pyramid (Book 1)','Rick Riordan','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Kane Chronicles: The Serpent''s Shadow (Book 3)','Rick Riordan','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Kane Chronicles: The Throne of Fire (Book 2)','Rick Riordan','{"Fantasy"}','Description of book goes here.','X',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Keys to the Kingdom: Grim Tuesday (Book 2)','Garth Nix','{"Fantasy"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Keys to the Kingdom: Sir Thursday (Book 4)','Garth Nix','{"Fantasy"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Keys to the Kingdom: Superior Saturday (Book 6)','Garth Nix','{"Fantasy"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Land of Stories: The Wishing Spell (Book 1)','Chris Colfer','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Last Dragon Chronicles: Dark Fire (Book 5)','Chris D''Lacey','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Last Dragon Chronicles: Fire World (Book 6)','Chris ''D Lacey','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Last Dragon Chronicles: Icefire (Book 2)','Chris ''D Lacey','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Last Dragon Chronicles: The Fire Ascending (Book 7)','Chris D''Lacey','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Last Dragon Chronicles: The Fire Eternal (Book 4)','Chris D''Lacey','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Last Dragon Chronicles: The Fire Within (Book 1)','Chris D''Lacey','{"Fantasy"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Lemonade War','Jacqueline Davies','{"Realistic Fiction/Humor"}','Description of book goes here.','S',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Line','Teri Hall','{"Dystopian"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Little Pince','Antoine De Saint-Exupery','{"Classics"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Lorien Legacies: I Am Number Four (Book 1)','Pittacus Lore','{"Fantasy"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Lovely Bones','Alice Sebold','{"Mystery"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Lunar Chronicles: Cinder (Book 1)','Marissa Meyer','{"Fantasy"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Lunar Chronicles: Scarlet (Book 2)','Marissa Meyer','{"Fantasy"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Magic Finger','Roald Dahl','{"Humor"}','Description of book goes here.','N',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Matched Trilogy: Matched (Book 1)','Ally Conde','{"Fantasy"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Mazerunner Series: The Death Cure (Book 3)','James Dashner','{"Dystopian"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Mortal Instruments: City of Ashes (Book 2)','Cassandra Clare','{"Fantasy"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Mouse and the Motorcycle','Beverly Clearly','{"Fantasy"}','Description of book goes here.','O',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Mouse Rap','Walter Dean Myers','{"Realistic Fiction"}','Description of book goes here.','W',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Mummy''s Mother','Tony Johnston','{"Historical Fiction"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Mysterious Affair at Styles','Agatha Christie','{"Mystery"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Mysterious Benedict Society and The Perilous Journey (Book 2)','Trenton Lee Stewart','{"Adventure"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Night Tourist','Katherine Marsh','{"Fantasy"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Opposite of Hallelujah','Anna Jarzab','{"Realistic Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Perilous Road','William O. Steele','{"Historical Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Phantom Tollbooth','Norton Juster','{"Fantasy/Classics"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Physics of Star Trek','Lawrence M. Krauss','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Pigman','Paul Zindel','{"Realistic Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Prince and the Pauper','Mark Twain','{"Classics"}','Description of book goes here.','XYZ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Puzzling World of Winston Breen','Eric Berlin','{"Adventure"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Red Badge of Courage','Stephen Crane','{"Classics"}','Description of book goes here.','LMN',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Red Pony','John Steinbeck','{"Classics"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Royal Diaries: Cleopatra VII, Daughter of the Nile','Kristina Gregory','{"Historical Fiction"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Royal Treatment','Lindsey Leavitt','{"Fantasy"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The School Story','Andrew Clements','{"Realistic Fiction"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secret Series: The Name of This Book is Secret (Book 1)','Pseudonymous Bosch','{"Adventure"}','Description of book goes here.','U',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of Droon: City in the Clouds (Book 4)','Tony Abbott','{"Fantasy"}','Description of book goes here.','N',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of Droon: Journey to the Volcano Palace (Book 2)','Tony Abbott','{"Fantasy"}','Description of book goes here.','N',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of Droon: The Great Ice Battle (Book 5)','Tony Abbott','{"Fantasy"}','Description of book goes here.','N',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of Droon: The Hidden Stairs and the Magic Carpet (Book 1)','Tony Abbott','{"Fantasy"}','Description of book goes here.','N',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of Droon: The Sleeping Giant of Goll (Book 6)','Tony Abbott','{"Fantasy"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of Droon: Under the Serpent Sea (Book 12)','Tony Abbott','{"Fantasy"}','Description of book goes here.','N',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of the Immortal Nicholas Flamel: The Alchemyst (Book 1)','Michael Scott','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of the Immortal Nicholas Flamel: The Magician (Book 2)','Michael Scott','{"Fantasy"}','Description of book goes here.','X',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Secrets of the Immortal Nicholas Flamel: The Sorceress (Book 3)','Michael Scott','{"Fantasy"}','Description of book goes here.','X',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Shadow Children Sequence: Among the Betrayed (Book 3)','Margaret Peterson Haddix','{"Science Fiction/Dystopian"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Shiver Series: Linger (Book 3)','Maggie Stiefvater','{"Fantasy"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Slated Trilogy: Fractured (Book 2)','Teri Terry','{"Science Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The SpiderWick Chronicles: The Field Guide (Book 1)','Tony Diterlizzi & Holly Black','{"Fantasy"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Summer of the Swans','Betsy Byars','{"Adventure"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Supernaturalist','Eoin Colfer','{"Science Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Tail of Emily Windsnap','Liz Kessler','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Tale of Despereaux','Kate Dicamillo','{"Adventure"}','Description of book goes here.','U',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Terrible Two Get Worse (Book 2)','Jory John & Mac Barnett','{"Humor"}','Description of book goes here.','LMN',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Thief Lord','Cornelia Funke','{"Fantasy"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: 2095 (Book 5)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Hey Kid, Want To Buy A Bridge? (Book 11)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: It''s All Greek To Me (Book 8)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Knights of the Kitchen Table (Book 1)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Me Oh Maya (Book 13)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Not-So-Jolly Roger (Book 2)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Sam Samurai (Book 10)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: See You Later, Gladiator (Book 9)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Summer Reading Is Killing Me! (Book 7)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: The Good, the Bad, and the Goofy (Book 3)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Tut, Tut (Book 6)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Vilking It And Liking It (Book 12)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Time Warp Trio: Your Mother Was a Neanderthal (Book 4)','Jon Scieszka','{"Adventure/Humor"}','Description of book goes here.','P',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Trumpeter of Krakow','Eric P. Kelly','{"Historical Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Twilight Saga: Breaking Dawn (Book 4)','Stephenie Meyer','{"Romance/Fantasy"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Twilight Saga: Eclipse (Book 3)','Stephenie Meyer','{"Romance/Fantasy"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Twilight Saga: New Moon (Book 2)','Stephenie Meyer','{"Romance/Fantasy"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Twits','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','S',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Uglies Series: Extras (Book 4)','Scott Westerfeld','{"Fantasy/Dystopian"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Uglies Series: Pretties (Book 2)','Scott Westerfeld','{"Fantasy/Dystopian"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Uglies Series: Specials (Book 3)','Scott Westerfeld','{"Fantasy/Dystopian"}','Description of book goes here.','Z',3,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Uglies Series: Uglies (Book 1)','Scott Westerfeld','{"Fantasy/Dystopian"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Underland Chronicles: Gregor and the Code of the Claw (Book 5)','Suzanne Collins','{"Fantasy/Mystery"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Underland Chronicles: Gregor and the Curse of Warmbloods (Book 3)','Suzanne Collins','{"Fantasy/Mystery"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Underland Chronicles: Gregor and the Marks of Secret (Book 4)','Suzanne Collins','{"Fantasy/Mystery"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Underland Chronicles: Gregor and the Prophecy of Bane (Book 2)','Suzanne Collins','{"Fantasy/Mystery"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Vicar of Nibbleswicke','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','O',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The View from Saturday','E.L. Konigsburg','{"Realistic Fiction"}','Description of book goes here.','U',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Walking Dead: Rise of the Governor (Book 1)','Robert Kirkman & Jay Bonansinga','{"Dystopian/Thriller"}','Description of book goes here.',NULL,2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Wanderer','Sharon Creech','{"Adventure"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Watsons Go to Birmingham--1963','Christopher Paul Curtis','{"Historical Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Westing Game','Ellen Raskin','{"Mystery"}','Description of book goes here.','V',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Wheel of the School','Meindert DeJong','{"Adventure"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Wildwood Chronicles: Under Wildwood','Colin Meloy','{"Adventure/Fantasy"}','Description of book goes here.','UVW',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Wind in the Willows','Kenneth Grahame','{"Classics"}','Description of book goes here.','Q',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Witch of Blackbird Pond','Elizabeth George Speare','{"Historical Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Witches','Roald Dahl','{"Fantasy/Humor"}','Description of book goes here.','R',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Wright 3','Blue Balliett','{"Mystery"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Year of the Dog','Grace Lin','{"Realistic Fiction"}','Description of book goes here.','Q',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Young Black Stallion','Walter Farley & Steven Farley','{"Adventure"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','The Zodiac Legacy: The Dragon''s Return (Book 2)','Stan Lee & Stuart Moore','{"Fantasy"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Then Again, Maybe I Won''t','Judy Blume','{"Realistic Fiction"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','They All Fall Down','Roxanne St. Claire','{"Mystery/Thriller"}','Description of book goes here.',NULL,2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Thirteen Reasons Why','Jay Asher','{"Realistic Fiction/Mystery"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','This Side of Wild','Gary Paulson','{"Realistic Fiction"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Three Cups of Tea: One Man''s Journey to Change the World... One Child at a Time','Greg Mortenson & David Oliver Relin','{"Biography"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Throwing Shadows','E.L. Konigsburg','{"Short Stories"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tiger Eyes','Judy Blume','{"Realistic Fiction"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Timmy Failure, Mistakes Were Made','Stephan Pastic','{"Mystery/Humor"}','Description of book goes here.','T',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tomorrow When the War Began','John Marsden','{"Dystopian"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tomorrow''s Girls: Behind the Gates (Book 1)','Eva Gray','{"Dystopian"}','Description of book goes here.','R',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Tracker','Gary Paulsen','{"Adventure"}','Description of book goes here.','W',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Vampire Academy (Book 1)','Richelle Mead','{"Fantasy"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Vampire Academy: Blood Promose (Book 4)','Richelle Mead','{"Fantasy"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Vampire Academy: Frostbite (Book 2)','Richelle Mead','{"Fantasy"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Vampire Academy: Shadow Kiss (Book 3)','Richelle Mead','{"Fantasy"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Vampire Academy: Spirit Bound (Book 5)','Richelle Mead','{"Fantasy"}','Description of book goes here.','OPQ',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Voices From the Disaster: Titanic','Deborah Hopkinson','{"Historical Fiction"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Waiting for Normal','Leslie Connor','{"Realistic Fiction"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Wake Me in Spring','James Preller','{"Learning to Read/Humor"}','Description of book goes here.','J',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Walk Two Moons','Sharon Creech','{"Realistic Fiction"}','Description of book goes here.','W',5,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors Don''t Cry: The Searing Memoir of the Battle to Integrate Little Rock''s Central High','Melba Pattillo Beals','{"Memoir"}','Description of book goes here.','X',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: A Dangerous Path (Book 5)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Fire and Ice (Book 2)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Into the Wild (Book 1)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Omen of the Starts: The Last Hope (Book 6)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Power of Three: Dark River (Book 2)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Power of Three: Eclipse (Book 4)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Power of Three: Long Shadows (Book 5)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Power of Three: Outcast (Book 3)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Power of Three: Sunrise (Book 6)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Power of Three: The Sight (Book 1)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: Rising Storm (Book 4)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: The Darkest Hour (Book 6)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: The New Prophesy: Dawn (Book 3)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: The New Prophesy: Midnight (Book 1)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: The New Prophesy: Moonrise (Book 2)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: The New Prophesy: Starlight (Book 4)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: The New Prophesy: Sunset (Book 6)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Warriors: The New Prophesy: Twilight (Book 5)','Erin Hunter','{"Fantasy"}','Description of book goes here.','S',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Whales, Dolphins, and Other Marine Mammals','George S. Fichter','{"Non-Fiction"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','When Plague Strikes: The Black Death, Smallpox, AIDS','James Cross Giblin','{"Non-Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','White Fang','Jack London','{"Adventure/Classics"}','Description of book goes here.','Y',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','White Star, Dog on the Titanic','Marty Crisp','{"Historical Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Who Ran My Underwear Up the Flagpole?','Jerry Spinelli','{"Realistic Fiction"}','Description of book goes here.','U',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Witness','Karen Hesse','{"Historical Fiction/Poetry"}','Description of book goes here.','W',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Woman Hollering Creek','Sandra Cisneros','{"Multicultural"}','Description of book goes here.','Z',2,0)
,('9a237f7c6bbd539586f27b43d87183e5','Wonder','R.J. Palacio','{"Realistic Fiction"}','Description of book goes here.','U',4,0)
,('9a237f7c6bbd539586f27b43d87183e5','Woodsong','Gary Paulson','{"Adventure"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Writing Incredibily Short Plays Poems Stories','Norton Gretton','{"How To/Creative Writing"}','Description of book goes here.',NULL,1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Wuthering Heights','Emily Bronte','{"Classics"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','You Want Women to Vote, Lizzie Stanton?','Jean Fritz','{"Historical Fiction"}','Description of book goes here.','T',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Young Samurai: The Way of the Dragon','Chris Bradford','{"Historical Fiction"}','Description of book goes here.','V',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Zazoo','Richard Mosher','{"Realistic Fiction"}','Description of book goes here.','Z',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Zipped','Laura McNeal & Tom McNeal','{"Mystery"}','Description of book goes here.','RST',1,0)
,('9a237f7c6bbd539586f27b43d87183e5','Zlata''s Diary: A Child''s Life in Sarajevo','Zlata Filipovic','{"Autobiography"}','Description of book goes here.','X',1,0);

-- CREATE FUNCTIONS

CREATE OR REPLACE FUNCTION cl_sign_up(u_input TEXT, p_input PASSWORD, t_input TEXT, fn_input TEXT, ln_input TEXT, e_input TEXT, z_input TEXT, sn_input TEXT, r_input INTEGER)
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
RETURNS TABLE(user_id TEXT, teacher_id TEXT, username NETEXT, role_id INTEGER) AS $$
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

-- CREATE VIEWS

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