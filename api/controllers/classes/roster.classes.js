let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {
  let sql = 'SELECT * FROM teacher_students_view WHERE teacher_id = $1';

  let sqlObject = `select row_to_json(t)
                    from (
                      select c.name,
                        (
                          select array_to_json(array_agg(row_to_json(d)))
                          from (
                            select *
                            from teacher_students_view
                            where class_id = c.id
                          ) d
                        ) as students
                      from classes c, teacher_classes tc
                      where tc.teacher_id = $1 AND c.id = tc.class_id
                    ) t`;

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
