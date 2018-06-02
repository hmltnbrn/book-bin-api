"use strict";

let nodemailer = require('nodemailer');
let Email = require('email-templates');
let path = require('path');

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

exports.activateAccount = function (username, emailAddress, firstName, token, cb) {

  let url = `${baseUrl}/activate-account/${token}`;

  const email = new Email({
    message: {
      from: process.env.EMAIL
    },
    send: true,
    transport: transporter,
    views: {
      options: {
        extension: 'ejs'
      },
      root: path.join(__dirname, 'templates')
    },
    preview: false
  });

  email.send({
    template: 'welcome',
    message: {
      to: emailAddress
    },
    locals: {
      name: firstName,
      url: url
    }
  })
  .then(info => {
    console.log(`Message ${info.messageId} sent: ${info.response}`);
    return cb(null, true);
  })
  .catch(error => {
    console.log(error);
    return cb(error, false);
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
