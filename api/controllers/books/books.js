let db = require('../../../db');

exports.GetAll = function (req, res, next) {

  let pageSize = req.query.pageSize ? parseInt(req.query.pageSize) : 12,
      page = req.query.page ? parseInt(req.query.page) : 1,
      search = req.query.search,
      whereParts = [],
      values = [],
      total = 0;

  if (search) {
    values.push(escape(search));
    whereParts.push("title || author || genre ~* $" + values.length);
  }

  whereParts.push("available IS TRUE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(*) from books " + where;

  let sql = "SELECT id, title, author, genre, level, number_in, number_out, available " +
              "FROM books " + where +
              " ORDER BY title LIMIT $" + (values.length + 1) + " OFFSET $" + (values.length + 2);

  return db.query(countSql, values)
    .then(result => {
      total = parseInt(result[0].count);
      return db.query(sql, values.concat([pageSize, ((page - 1) * pageSize)]))
    })
    .then(books => {
      return res.json({"pageSize": pageSize, "page": page, "total": total, "books": books});
    })
    .catch(err => {
      console.log(err);
      return res.json({ message: err });
    });

}
