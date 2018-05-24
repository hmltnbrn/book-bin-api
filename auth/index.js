let express = require('express'),
    db = require('../db'),
    email = require('../email'),
    jwt = require('jsonwebtoken'),
    moment = require('moment'),
    checkToken = require('./token').checkToken,
    router = express.Router();

router.post('/SignUp', function(req, res, next) {
  return db.query("SELECT * FROM cl_sign_up($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)", [req.body.username, req.body.password, req.body.title, req.body.firstName, req.body.lastName, req.body.email, req.body.grade, req.body.schoolName, req.body.zip, req.body.role], true, req.body.username + " sign up attempt")
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
});

router.post('/Activate', function(req, res, next) {
  return db.query("SELECT * FROM cl_activate_account($1)", [req.body.token], true, "Activate account attempt")
    .then(user => {
      if(!user.cl_activate_account) return res.status(400).json({ status: false, message: "Token invalid" });
      return res.status(200).json({ status: true, message: "Activation successful" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
});

router.post('/SignIn', function(req, res, next) {
  return db.query("SELECT * FROM cl_sign_in($1, $2)", [req.body.username, req.body.password], true, req.body.username + " sign in attempt")
    .then(user => {
      if(!user) return res.status(400).json({ status: false, message: "Incorrect username or password"})
      const payload = {
        exp: moment().add(14, 'days').unix(),
        iat: moment().unix(),
        sub: user
      };
      let token = jwt.sign(payload, process.env.JWT_TOKEN_SECRET);
      return res.status(200).json({ status: true, id: user.user_id, token: token });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
});

router.post('/ForgotPassword', function(req, res, next) {
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
});

router.post('/ResetPassword', function(req, res, next) {
  return db.query("SELECT * FROM cl_reset_password($1, $2, $3)", [req.body.email, req.body.token, req.body.password], true, req.body.email + " reset password attempt")
    .then(token => {
      if(token.cl_reset_password == 'email') return res.status(400).json({ status: false, message: "Email or token invalid" });
      else if(token.cl_reset_password == 'expired') return res.status(400).json({ status: false, message: "Token expired" });
      return res.status(200).json({ status: true, message: "Password changed" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
});

router.post('/ForgotUsername', function(req, res, next) {
  return db.query("SELECT * FROM cl_forgot_username($1)", [req.body.email], true, req.body.email + " forgot username attempt")
    .then(user => {
      if(user.cl_forgot_username == 'false') return res.status(400).json({ status: false, message: "Email is not in use" });
      email.forgotUsername(req.body.email, user.cl_forgot_username, function(err, status) {
        if(err) return res.status(500).json({ status: false, message: err.message });
        return res.status(200).json({ status: true, message: "Email sent" });
      });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
});

router.post('/ChangePassword', checkToken, function(req, res, next) {
  return db.query("SELECT * FROM cl_change_password($1, $2, $3)", [req.user.user_id, req.body.oldPassword, req.body.newPassword], true, req.user.user_id + " change password attempt")
    .then(pass => {
      if(pass.cl_change_password == 'user') return res.status(400).json({ status: false, message: "User does not exist" });
      else if(pass.cl_change_password == 'password') return res.status(400).json({ status: false, message: "Old password does not match records" });
      return res.status(200).json({ status: true, message: "Password changed" });
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
});

router.get('/Profile', checkToken, function(req, res, next) {
  return db.query("SELECT * FROM teacher_details WHERE user_id = $1", [req.user.user_id], true, req.user.user_id + " get profile")
    .then(result => {
      return res.status(200).send(result);
    })
    .catch(err => {
      console.log(err);
      return res.status(500).json({ status: false, message: err.message });
    });
});

module.exports = router;
