let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.get = function (req, res, next) {
  let response = {};

  let sql1 = "SELECT book_id, title, author, COUNT(book_id) AS check_out_total FROM student_books_view WHERE teacher_id = $1 GROUP BY book_id, title, author ORDER BY check_out_total DESC LIMIT 10";
  let sql2 = "SELECT student_id, first_name, last_name, class_name, COUNT(book_id) AS books_read FROM student_books_view WHERE teacher_id = $1 AND date_in IS NOT NULL GROUP BY student_id, first_name, last_name, class_name ORDER BY books_read DESC LIMIT 10";
  let sql3 = `SELECT * FROM (
    SELECT book_id, title, student_id, first_name, last_name, 'OUT' AS action, date_out AS date
    FROM student_books_view WHERE teacher_id = $1
    UNION
    SELECT book_id, title, student_id, first_name, last_name, 'IN' AS action, date_in AS date
    FROM student_books_view WHERE teacher_id = $1
    ) as activity WHERE date IS NOT NULL ORDER BY date DESC LIMIT 10`;

  return db.query(sql1, [req.user.teacher_id])
    .then(books => {
      response["top_books"] = books;
      return db.query(sql2, [req.user.teacher_id])
    })
    .then(students => {
      response["top_readers"] = students;
      return db.query("SELECT * FROM cl_overdue_books($1)", [req.user.teacher_id])
    })
    .then(books => {
      response["overdue_books"] = books;
      return db.query(sql3, [req.user.teacher_id])
    })
    .then(activity => {
      response["recent_activity"] = activity;
      return res.status(200).json(response);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}
