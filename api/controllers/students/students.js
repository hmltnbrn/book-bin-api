let db = require('../../../db');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAllActiveStudents = function (req, res, next) {

  let sql = 'SELECT s.* FROM students s, classes c WHERE s.class_id = c.id AND s.active IS TRUE AND c.teacher_id = $1';

  return db.query(sql, [req.user.teacher_id])
    .then(students => {
      return res.status(200).json({"result": students});
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });

}
