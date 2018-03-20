let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {
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
