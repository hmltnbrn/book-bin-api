let db = require('../../../db'),
    helper = require('../../helpers');

let escape = s => s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

exports.getAll = function (req, res, next) {
  return res.status(200).json({ status: true });
}

exports.get = function (req, res, next) {
  let sql = "SELECT * FROM teacher_books WHERE id = $1";

  return db.query(sql, [req.params.id], true)
    .then(book => {
      if(!book) return res.status(404).json({ status: false, message: "Book doesn't exist" });
      return res.status(200).send(book);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}
