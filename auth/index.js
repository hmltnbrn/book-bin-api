let db = require('../db'),
    email = require('../email'),
    jwt = require('jsonwebtoken'),
    moment = require('moment'),
    crypto = require('crypto');

exports.signUp = function(req, res, next) {
  return db.query("SELECT * FROM cl_sign_up($1, $2, $3, $4, $5, $6, $7, $8, $9)", [req.body.username, req.body.password, req.body.title, req.body.firstName, req.body.lastName, req.body.email, req.body.zip, req.body.schoolName, req.body.role], true, req.body.username + " sign up attempt")
    .then(user => {
      if(user.cl_sign_up == 'false') return res.status(400).json({ status: false, message: "Username or email already in use" });
      email.activateAccount(req.body.username, req.body.email, user.cl_sign_up, function(err, status) {
        if(err) return res.status(500).json({ status: false, message: err.message });
        return res.status(200).json({ status: true, message: "Email sent" });
      });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.activateAccount = function(req, res, next) {
  return db.query("SELECT * FROM cl_activate_account($1)", [req.body.token], true, "Activate account attempt")
    .then(user => {
      if(!user.cl_activate_account) return res.status(400).json({ status: false, message: "Token invalid" });
      return res.status(200).json({ status: true, message: "Activation successful" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.signIn = function(req, res, next) {
  return db.query("SELECT * FROM cl_sign_in($1, $2)", [req.body.username, req.body.password], true, req.body.username + " sign in attempt")
    .then(user => {
      if(!user) return res.status(400).json({ status: false, message: "Incorrect username or password"})
      const payload = {
        exp: moment().add(14, 'days').unix(),
        iat: moment().unix(),
        sub: user.id
      };
      let token = jwt.sign(payload, process.env.JWT_TOKEN_SECRET);
      return res.status(200).json({ status: true, id: user.id, token: token });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.forgotPassword = function(req, res, next) {
  return db.query("SELECT * FROM cl_password_token($1)", [req.body.email], true)
    .then(token => {
      if(token.cl_password_token == 'false') return res.status(400).json({ status: false, message: "Email is not in use" });
      email.resetPassword(req.body.email, token.cl_password_token, function(err, status) {
        if(err) return res.status(500).json({ status: false, message: err.message });
        return res.status(200).json({ status: true, message: "Email sent" });
      });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.resetPassword = function(req, res, next) {
  return db.query("SELECT * FROM cl_reset_password($1, $2, $3)", [req.body.email, req.body.token, req.body.password], true, req.body.email + " reset password attempt")
    .then(token => {
      if(!token.cl_reset_password) return res.status(400).json({ status: false, message: "Token invalid or expired" });
      return res.status(200).json({ status: true, message: "Token created" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.forgotUsername = function(req, res, next) {
  return db.query("SELECT * FROM cl_forgot_username($1)", [req.body.email], true, req.body.email + " forgot username attempt")
    .then(user => {
      if(user.cl_forgot_username == 'false') return res.status(400).json({ status: false, message: "Email is not in use" });
      email.forgotUsername(req.body.email, user.cl_forgot_username, function(err, status) {
        if(err) return res.status(500).json({ status: false, message: err.message });
        return res.status(200).json({ status: true, message: "Email sent" });
      });
      return res.status(200).json({ status: true, message: "Email sent" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
}

exports.checkToken = function (req, res, next) {
  if (req.headers && req.headers.authorization && req.headers.authorization.split(' ')[0] === 'BearerJWT') {
    jwt.verify(req.headers.authorization.split(' ')[1], process.env.JWT_TOKEN_SECRET, function(err, decode) {
      if (err) return res.status(500).json({ status: false, message: 'Authorization error' });
      const now = moment().unix();
      if (now > decode.exp) return res.status(401).json({ status: false, message: 'Your session has expired' });
      else {
        req.user = decode.sub;
        next();
      }
    });
  }
  else {
    return res.status(401).json({ status: false, message: 'Not authorized' });
  }
}
