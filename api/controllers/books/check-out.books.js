let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.post = function (req, res, next) {
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
