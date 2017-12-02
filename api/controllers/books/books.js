let db = require('../../../db');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAllBooks = function (req, res, next) {

  let pageSize = req.query.pageSize ? parseInt(req.query.pageSize) : 12,
      page = req.query.page ? parseInt(req.query.page) : 1,
      search = req.query.search,
      whereParts = [],
      values = [],
      totalItems = 0;

  if (search) {
    values.push(escape(search));
    whereParts.push("title || author ~* $" + values.length);
  }

  //whereParts.push("available IS TRUE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(*) from books " + where;

  let sql = "SELECT id, title, author, genres, description, reading_level " +
              "FROM books " + where +
              " ORDER BY title LIMIT $" + (values.length + 1) + " OFFSET $" + (values.length + 2);

  return db.query(countSql, values)
    .then(result => {
      totalItems = parseInt(result[0].count);
      return db.query(sql, values.concat([pageSize, ((page - 1) * pageSize)]))
    })
    .then(books => {
      pageTotal = Math.ceil(totalItems/pageSize);
      return res.status(200).json({"pageSize": pageSize, "page": page, "pageTotal": pageTotal, "totalItems": totalItems, "result": books});
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });

}

exports.getAllTeacherBooks = function (req, res, next) {

  let pageSize = req.query.pageSize ? parseInt(req.query.pageSize) : 12,
      page = req.query.page ? parseInt(req.query.page) : 1,
      search = req.query.search,
      whereParts = [],
      values = [],
      totalItems = 0;

  if (search) {
    values.push(escape(search));
    whereParts.push("COALESCE(NULLIF(t.title, ''), b.title) || COALESCE(NULLIF(t.author, ''), b.author) ~* $" + values.length);
  }

  whereParts.push("t.book_id = b.id");

  whereParts.push("t.teacher_id = '" + req.user.teacher_id + "'");

  whereParts.push("t.available IS TRUE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(*) from books b, teacher_books t " + where;

  let sql = "SELECT t.teacher_id, t.book_id, " +
    "COALESCE(NULLIF(t.title, ''), b.title) AS title, " +
    "COALESCE(NULLIF(t.author, ''), b.author) as author, " +
    "COALESCE(NULLIF(t.description, ''), b.description) as description, " +
    "COALESCE(NULLIF(t.reading_level, ''), b.reading_level) as reading_level, " +
    "CASE WHEN array_length(t.genres, 1) > 0 THEN t.genres ELSE b.genres END, t.number_in, t.number_out " +
    "FROM books b, teacher_books t " + where + 
    " ORDER BY title LIMIT $" + (values.length + 1) + " OFFSET $" + (values.length + 2);

  return db.query(countSql, values)
    .then(result => {
      totalItems = parseInt(result[0].count);
      return db.query(sql, values.concat([pageSize, ((page - 1) * pageSize)]))
    })
    .then(books => {
      pageTotal = Math.ceil(totalItems/pageSize);
      return res.status(200).json({"pageSize": pageSize, "page": page, "pageTotal": pageTotal, "totalItems": totalItems, "result": books});
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });

}

exports.getStudentsWithBook = function (req, res, next) {
  let sql = "SELECT s.id, s.first_name, s.last_name FROM students s, checked_out_books c " +
    "WHERE c.student_id = s.id AND c.date_in IS NULL AND teacher_id = $1 AND book_id = $2 ORDER BY s.last_name";

  return db.query(sql, [req.user.teacher_id, req.query.book_id])
    .then(students => {
      return res.status(200).json({ result: students });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.postCheckOutBook = function (req, res, next) {
  return db.query("SELECT * FROM cl_check_out($1, $2, $3, $4)", [req.user.teacher_id, req.body.book_id, req.body.student_id, req.body.date_due], true)
    .then(book => {
      if(!book.cl_check_out) return res.status(400).json({ status: false, message: "Student already has book" });
      return res.status(200).json({ status: true, message: "Book checked out" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.postCheckInBook = function (req, res, next) {
  if(!req.body.book_id || !req.body.student_id) return res.status(400).json({ status: false, message: "Invalid student. Please try again." });
  return db.query("SELECT * FROM cl_check_in($1, $2, $3)", [req.user.teacher_id, req.body.book_id, req.body.student_id], true)
    .then(book => {
      if(!book.cl_check_in) return res.status(400).json({ status: false, message: "Book already checked in. Please reload your library." });
      return res.status(200).json({ status: true, message: "Book checked in" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}
