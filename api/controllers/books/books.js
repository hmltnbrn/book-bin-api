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
    whereParts.push("title || author || genre ~* $" + values.length);
  }

  whereParts.push("available IS TRUE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(*) from books " + where;

  let sql = "SELECT id, title, author, genre, reading_level, number_in, number_out, available " +
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
    whereParts.push("title || author || genre ~* $" + values.length);
  }

  whereParts.push("available IS TRUE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(*) from books " + where;

  let sql = "SELECT id, title, author, genre, reading_level, number_in, number_out, available " +
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
