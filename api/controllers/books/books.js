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

exports.postCheckOutBook = function (req, res, next) {
  console.log(req.body)
  return res.status(200).json({ status: true });
}
