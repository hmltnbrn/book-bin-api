let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {
  let sql = 'SELECT * FROM teacher_students_view WHERE teacher_id = $1';

  return db.query(sql, [req.user.teacher_id])
    .then(classes => {
      return res.status(200).json(classes);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.get = function (req, res, next) {
  let sql = 'SELECT * FROM teacher_students_view WHERE class_id = $1';

  return db.query(sql, [req.params.id], true)
    .then(roster => {
      if(!roster) return res.status(404).json({ status: false, message: "Class doesn't exist" });
      return res.status(200).json(cl);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}
