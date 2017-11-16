let db = require('../db'),
    jwt = require('jsonwebtoken'),
    moment = require('moment'),
    crypto = require('crypto');

require('dotenv-safe').load();

const createId = () => crypto.randomBytes(16).toString('hex'); //creates id
const createSalt = () => crypto.randomBytes(32).toString('hex'); //creates salt for password
const createHash = (string) => crypto.createHash('sha256').update(string).digest('hex'); //hashes password

exports.register = function(req, res, next) {
  return db.query("SELECT u.username FROM users u, user_details d WHERE u.id = d.user_id AND (u.username = $1 OR d.email = $2)", [req.body.username, req.body.email], true)
    .then(user => {
      if(user) {
        res.json({ status: false, message: "Username or email already in use" });
        throw new Error('abort');
      }
      let id = createId();
      let salt = createSalt();
      let hashedPassword = createHash(req.body.password + salt);
      return db.query("INSERT INTO users (id, username, password, salt) VALUES ($1, $2, $3, $4) RETURNING id", [id, req.body.username, hashedPassword, salt], true)
    })
    .then(user => {
      return db.query("INSERT INTO user_details (user_id, first_name, last_name, email, zip, school_name, role_id) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING user_id", [user.id, req.body.firstName, req.body.lastName, req.body.email, req.body.zip, req.body.schoolName, 1], true)
    })
    .then(user => {
      return res.json({ status: true, message: "User Added" });
    })
    .catch(err => {
      console.log(err);
      if(err.message !== 'abort') return res.json({ status: false, message: err.message });
    });
}

exports.signin = function(req, res, next) {
  return db.query("SELECT salt FROM users WHERE username = $1", [req.body.username], true)
    .then(user => {
      if(!user) {
        res.json({ status: false, message: "Incorrect username or password" });
        throw new Error('abort');
      }
      return db.query("SELECT id, username FROM users WHERE username = $1 AND password = $2", [req.body.username, createHash(req.body.password + user.salt)], true)
    })
    .then(user => {
      if(!user) return res.json({ status: false, message: "Incorrect username or password"})
      const payload = {
        exp: moment().add(14, 'days').unix(),
        iat: moment().unix(),
        sub: user.id
      };
      let token = jwt.sign(payload, process.env.TOKEN_SECRET);
      return res.json({ status: true, id: user.id, token: token });
    })
    .catch(err => {
      console.log(err);
      if(err.message !== 'abort') return res.json({ status: false, message: err.message });
    });
}

exports.checkToken = function (req, res, next) {
  if (req.headers && req.headers.authorization && req.headers.authorization.split(' ')[0] === 'BearerJWT') {
    jwt.verify(req.headers.authorization.split(' ')[1], process.env.TOKEN_SECRET, function(err, decode) {
      if (err) return res.status(400).json({ status: false, message: 'Error in Authorization' });
      const now = moment().unix();
      if (now > decode.exp) return res.status(401).json({ status: false, message: 'Token Expired' });
      else next();
    });
  }
  else {
    return res.status(400).json({ status: false, message: 'Not Authorized' });
  }
}
