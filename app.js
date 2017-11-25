var express = require('express');
var path = require('path');
var favicon = require('serve-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var cors = require('cors');

var app = express();

app.use(cors());

require('dotenv-safe').load({
  allowEmptyValues: true
});

var index = require('./routes/index');
var auth = require('./auth');
var api = require('./api')(app);

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', index);

app.route('/auth/SignUp')
  .post(auth.signUp);

app.route('/auth/SignIn')
  .post(auth.signIn);

app.route('/auth/Activate')
  .post(auth.activateAccount);

app.route('/auth/ForgotPassword')
  .post(auth.forgotPassword);

app.route('/auth/ResetPassword')
  .post(auth.resetPassword);

app.route('/auth/ForgotUsername')
  .post(auth.forgotUsername);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
