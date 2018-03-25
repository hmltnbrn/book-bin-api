let db = require('../../../db');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {
  let returnAll = req.query.returnAll,
      pageSize = req.query.pageSize ? parseInt(req.query.pageSize) : 12,
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
  whereParts.push("teacher_id = $" + values.length);

  whereParts.push("active IS TRUE");

  let where = whereParts.length > 0 ? ("WHERE " + whereParts.join(" AND ")) : "";

  let countSql = "SELECT COUNT(*) FROM teacher_students_view " + where;

  let sql = `SELECT student_id AS id, student_first_name AS first_name, student_last_name AS last_name, student_email AS email FROM teacher_students_view ${where} ORDER BY first_name`;
  
  if(!returnAll) sql += ` LIMIT $${values.length + 1} OFFSET $${values.length + 2}`;

  return db.query(countSql, values)
    .then(result => {
      totalItems = parseInt(result[0].count);
      return db.query(sql, returnAll ? values : values.concat([pageSize, ((page - 1) * pageSize)]))
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
