let db = require('../../../db');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAllBooks = function (req, res, next) {

  return res.status(200).json({ status: true });

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
    whereParts.push("title || author ~* $" + values.length);
  }

  values.push(req.user.teacher_id);
  whereParts.push("teacher_id = $" + values.length);

  whereParts.push("available IS TRUE");

  whereParts.push("obsolete IS FALSE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(*) from teacher_books " + where;

  let sql = "SELECT * FROM teacher_books " + where +
    " ORDER BY title LIMIT $" + (values.length + 1) + " OFFSET $" + (values.length + 2);

  return db.query(countSql, values)
    .then(result => {
      totalItems = parseInt(result[0].count);
      return db.query(sql, values.concat([pageSize, ((page - 1) * pageSize)]))
    })
    .then(books => {
      pageTotal = Math.ceil(totalItems/pageSize);
      return res.status(200).json({ pageSize, page, pageTotal, totalItems, result: books });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });

}

exports.getBook = function (req, res, next) {
  let sql = "SELECT * FROM teacher_books WHERE id = $1";

  return db.query(sql, [req.params.id], true)
    .then(book => {
      if(!book) return res.status(404).json({ status: false, message: "Book doesn't exist" });
      return res.status(200).send(book);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.getTeacherBook = function (req, res, next) {

  let id = req.params.id || req.body.book_id,
      bookResult,
      studentCurrent;

  let sql = "SELECT * FROM teacher_books WHERE id = $1 AND teacher_id = $2";
  let sql2 = "SELECT s.*, c.* FROM students s, checked_out_books c WHERE s.id = c.student_id AND c.date_in IS NULL AND c.book_id = $1 AND c.teacher_id = $2 ORDER BY c.date_out DESC";
  let sql3 = "SELECT s.*, c.* FROM students s, checked_out_books c WHERE s.id = c.student_id AND c.date_in IS NOT NULL AND c.book_id = $1 AND c.teacher_id = $2 ORDER BY c.date_in DESC";

  return db.query(sql, [id, req.user.teacher_id], true)
    .then(book => {
      bookResult = book;
      return db.query(sql2, [id, req.user.teacher_id])
    })
    .then(students => {
      studentCurrent = students;
      return db.query(sql3, [id, req.user.teacher_id])
    })
    .then(students => {
      if(!bookResult) return res.status(404).json({ status: false, message: "Book doesn't exist" });
      return res.status(200).json({ book: bookResult, studentCurrent: studentCurrent, studentHistory: students });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.postTeacherBook = function (req, res, next) {
  let fields = Object.keys(req.body),
      values = Object.keys(req.body).map((k) => req.body[k]);

  let updateParts = "SET "
  for(var i=0;i<fields.length;i++) {
    updateParts += fields[i] + " = $" + (i + 1) + ", ";
  }

  let sql = "UPDATE teacher_books " + updateParts.slice(0, -2) + 
    " WHERE id = $" + (fields.length + 1) + " AND teacher_id = $" + (fields.length + 2) + " RETURNING *";

  return db.query(sql, values.concat([req.body.id, req.user.teacher_id]), true)
    .then(book => {
      return res.status(200).send(book);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.deleteTeacherBook = function (req, res, next) {
  return db.query("SELECT * FROM cl_delete_book($1, $2)", [req.params.id, req.user.teacher_id], true)
    .then(book => {
      if(!book.cl_delete_book) return res.status(400).json({ status: false, message: "Book is currently checked out. Please check all copies back in before removing it from your library." });
      return res.status(200).json({ status: true });
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

exports.postStudentsCheckInBook = function (req, res, next) {
  if(req.body.students.length == 0) return res.status(400).json({ status: false, message: "Invalid students. Please try again." });
  return db.query("SELECT * FROM cl_check_in_students($1, $2, $3)", [req.user.teacher_id, req.body.book_id, req.body.students], true)
    .then(book => {
      if(!book.cl_check_in_students) return res.status(400).json({ status: false, message: "Books already checked in. Please reload your library." });
      return next();
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}
