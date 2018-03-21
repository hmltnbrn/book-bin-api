let db = require('../../../db');

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
    whereParts.push("first_name || last_name ~* $" + values.length);
  }

  values.push(req.user.teacher_id);
  whereParts.push("c.teacher_id = $" + values.length);

  whereParts.push("s.class_id = c.id");

  whereParts.push("s.active IS TRUE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(s.*) FROM students s, classes c " + where;

  let sql = `SELECT s.* FROM students s, classes c ${where} ORDER BY first_name LIMIT $${values.length + 1} OFFSET $${values.length + 2}`;

  return db.query(countSql, values)
    .then(result => {
      totalItems = parseInt(result[0].count);
      return db.query(sql, values.concat([pageSize, ((page - 1) * pageSize)]))
    })
    .then(students => {
      pageTotal = Math.ceil(totalItems/pageSize);
      return res.status(200).json({ pageSize, page, pageTotal, totalItems, result: students });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });

}
