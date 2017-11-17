let db = require('../db'),
    jwt = require('jsonwebtoken'),
    moment = require('moment'),
    crypto = require('crypto');

require('dotenv-safe').load();

exports.signup = function(req, res, next) {
  return db.query("SELECT * FROM sign_up($1, $2, $3, $4, $5, $6, $7, $8)", [req.body.username, req.body.password, req.body.firstName, req.body.lastName, req.body.email, req.body.zip, req.body.schoolName, req.body.role], true, req.body.username + " sign up attempt")
    .then(user => {
      if(!user.sign_up) return res.json({ status: false, message: "Username or email already in use" });
      return res.status(200).json({ status: true, message: "User Added" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.signin = function(req, res, next) {
  return db.query("SELECT * FROM sign_in($1, $2)", [req.body.username, req.body.password], true, req.body.username + " sign in attempt")
    .then(user => {
      if(!user) return res.json({ status: false, message: "Incorrect username or password"})
      const payload = {
        exp: moment().add(14, 'days').unix(),
        iat: moment().unix(),
        sub: user.id
      };
      let token = jwt.sign(payload, process.env.TOKEN_SECRET);
      return res.status(200).json({ status: true, id: user.id, token: token });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.checkToken = function (req, res, next) {
  if (req.headers && req.headers.authorization && req.headers.authorization.split(' ')[0] === 'BearerJWT') {
    jwt.verify(req.headers.authorization.split(' ')[1], process.env.TOKEN_SECRET, function(err, decode) {
      if (err) return res.status(400).json({ status: false, message: 'Error in Authorization' });
      const now = moment().unix();
      if (now > decode.exp) return res.status(401).json({ status: false, message: 'Token Expired' });
      else {
        req.user = decode.sub;
        next();
      }
    });
  }
  else {
    return res.status(400).json({ status: false, message: 'Not Authorized' });
  }
}
