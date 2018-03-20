let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {

  let pageSize = req.query.pageSize ? parseInt(req.query.pageSize) : 12,
      page = req.query.page ? parseInt(req.query.page) : 1,
      search = req.query.search,
      readingLevel = req.query.readingLevel,
      whereParts = [],
      values = [],
      totalItems = 0;

  if (search) {
    values.push(escape(search));
    whereParts.push("title || author ~* $" + values.length);
  }

  if (readingLevel) {
    values.push(escape(readingLevel));
    whereParts.push("reading_level ~* $" + values.length);
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

exports.get = function (req, res, next) {

  let id = req.params.id || req.body.book_id,
      response = {};

  let sql = "SELECT * FROM teacher_books WHERE id = $1 AND teacher_id = $2";
  let sql2 = "SELECT s.*, c.* FROM students s, checked_out_books c WHERE s.id = c.student_id AND c.date_in IS NULL AND c.book_id = $1 AND c.teacher_id = $2 ORDER BY c.date_out DESC";
  let sql3 = "SELECT s.*, c.* FROM students s, checked_out_books c WHERE s.id = c.student_id AND c.date_in IS NOT NULL AND c.book_id = $1 AND c.teacher_id = $2 ORDER BY c.date_in DESC";

  return db.query(sql, [id, req.user.teacher_id], true)
    .then(book => {
      response["book"] = book;
      return db.query(sql2, [id, req.user.teacher_id])
    })
    .then(students => {
      response["student_current"] = students;
      return db.query(sql3, [id, req.user.teacher_id])
    })
    .then(students => {
      response["student_history"] = students;
      if(!response["book"]) return res.status(404).json({ status: false, message: "Book doesn't exist" });
      return res.status(200).json(response);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.put = function (req, res, next) {
  let fields = Object.keys(req.body),
      values = fields.map((k) => req.body[k]);

  let sql = `INSERT INTO teacher_books (teacher_id, ${helper.insertHelper(fields, 1)} RETURNING *`;

  return db.query(sql, [req.user.teacher_id].concat(values), true)
    .then(book => {
      return res.status(200).json(book);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.patch = function (req, res, next) {
  let fields = Object.keys(req.body),
      values = fields.map((k) => req.body[k]);

  let sql = "UPDATE teacher_books " + helper.updateHelper(fields) + 
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

exports.delete = function (req, res, next) {
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
