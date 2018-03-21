let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {
  let sql = 'SELECT s.* FROM students s WHERE obsolete IS NOT TRUE';

  return db.query(sql)
    .then(students => {
      return res.status(200).json(students);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}


exports.get = function (req, res, next) {
  let sql = 'SELECT s.* FROM students s WHERE s.id = $1';

  return db.query(sql, [req.params.id], true)
    .then(student => {
      if(!student) return res.status(404).json({ status: false, message: "Student doesn't exist" });
      return res.status(200).json(student);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.put = function (req, res, next) {
  let fields = Object.keys(req.body),
      values = fields.map((k) => req.body[k]);

  let sql = `INSERT INTO students (${helper.insertHelper(fields)} RETURNING *`;

  return db.query(sql, values, true)
    .then(student => {
      return res.status(200).json(student);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.patch = function (req, res, next) {
  let fields = Object.keys(req.body),
      values = fields.map((k) => req.body[k]);

  let sql = `UPDATE students ${helper.updateHelper(fields)} WHERE id = $${fields.length + 1} RETURNING *`;

  return db.query(sql, values.concat([req.body.id]), true)
    .then(student => {
      return res.status(200).json(student);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.delete = function (req, res, next) {
  let sql = "UPDATE students SET obsolete = TRUE WHERE id = $1"

  return db.query(sql, [req.params.id], true)
    .then(student => {
      return res.status(200).json({ status: true });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}
