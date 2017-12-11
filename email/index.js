"use strict";

let nodemailer = require('nodemailer');

let transporter = nodemailer.createTransport({
  service: 'Gmail',
  auth: {
    type: 'OAuth2',
    user: process.env.EMAIL,
    clientId: process.env.CLIENT_ID,
    clientSecret: process.env.CLIENT_SECRET,
    refreshToken: process.env.REFRESH_TOKEN,
    accessToken: process.env.ACCESS_TOKEN,
    expires: 3600
  }
});

let baseUrl = process.env.BASE_URL;

exports.activateAccount = function (username, email, token, cb) {

  let url = baseUrl + '/activate-account/'+ token;

  let bodyText = 'Hello, ' + username + '!\n\nPlease follow the link below to activate your account:\n\n' + url + '\n\nSincerely,\nThe Classroom Library';
  let bodyHTML = 'Hello, ' + username + '!<br/><br/>Please follow the link below to activate your account:<br/><br/>' + url + '<br/><br/>Sincerely,<br/>The Classroom Library';

  // setup email data
  let mailOptions = {
    from: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    sender: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    replyTo: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    to: email, // list of receivers
    subject: "Activate your account with the Classroom Library",
    html: bodyHTML,
    text: bodyText
  };

  // send mail with defined transport object
  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.log(error);
      return cb(error, false);
    }
    console.log('Message %s sent: %s', info.messageId, info.response);
    return cb(null, true);
  });

};

exports.resetPassword = function (email, token, cb) {

  let url = baseUrl + '/reset-password?email=' + email + '&token=' + token;

  let bodyText = 'Hello, user!\n\nPlease follow the link below to reset your password:\n\n' + url + '\n\nSincerely,\nThe Classroom Library';
  let bodyHTML = 'Hello, user!<br/><br/>Please follow the link below to reset your password:<br/><br/>' + url + '<br/><br/>Sincerely,<br/>The Classroom Library';

  // setup email data
  let mailOptions = {
    from: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    sender: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    replyTo: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    to: email, // list of receivers
    subject: "Reset your password with the Classroom Library",
    html: bodyHTML,
    text: bodyText
  };

  // send mail with defined transport object
  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.log(error);
      return cb(error, false);
    }
    console.log('Message %s sent: %s', info.messageId, info.response);
    return cb(null, true);
  });

};

exports.forgotUsername = function (email, username, cb) {

  let url = baseUrl + '/signin';

  let bodyText = 'Hello, ' + username + '!\n\nYour username is ' + username + '. ' + 'Please follow the link below to sign in:\n\n' + url + '\n\nSincerely,\nThe Classroom Library';
  let bodyHTML = 'Hello, ' + username + '!<br/><br/>Your username is <strong>' + username + '</strong>. ' + 'Please follow the link below to sign in:<br/><br/>' + url + '<br/><br/>Sincerely,<br/>The Classroom Library';

  // setup email data
  let mailOptions = {
    from: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    sender: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    replyTo: {
      name: "Classroom Library",
      address: process.env.EMAIL
    },
    to: email, // list of receivers
    subject: "Your username with the Classroom Library",
    html: bodyHTML,
    text: bodyText
  };

  // send mail with defined transport object
  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.log(error);
      return cb(error, false);
    }
    console.log('Message %s sent: %s', info.messageId, info.response);
    return cb(null, true);
  });

};
