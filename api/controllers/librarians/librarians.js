let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {
  let sql = 'SELECT * FROM librarians WHERE obsolete IS NOT TRUE';

  return db.query(sql)
    .then(librarians => {
      return res.status(200).json(librarians);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.get = function (req, res, next) {
  let sql = 'SELECT * FROM librarians WHERE id = $1';

  return db.query(sql, [req.params.id], true)
    .then(librarian => {
      if(!librarian) return res.status(404).json({ status: false, message: "Librarian doesn't exist" });
      return res.status(200).json(librarian);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.put = function (req, res, next) {
  let fields = Object.keys(req.body),
      values = fields.map((k) => req.body[k]);

  let sql = `INSERT INTO librarians (${helper.insertHelper(fields, 1)} RETURNING *`;

  return db.query(sql, values, true)
    .then(librarian => {
      return res.status(200).json(librarian);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.patch = function (req, res, next) {
  let fields = Object.keys(req.body),
      values = fields.map((k) => req.body[k]);

  let sql = `UPDATE librarians ${helper.updateHelper(fields)} WHERE id = $${fields.length + 1} RETURNING *`;

  return db.query(sql, values.concat([req.body.id]), true)
    .then(librarian => {
      return res.status(200).json(librarian);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.delete = function (req, res, next) {
  let sql = "UPDATE librarians SET obsolete = TRUE WHERE id = $1"

  return db.query(sql, [req.params.id], true)
    .then(librarian => {
      return res.status(200).json({ status: true });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}
