let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.post = function (req, res, next) {
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

exports.postWithStudents = function (req, res, next) {
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
