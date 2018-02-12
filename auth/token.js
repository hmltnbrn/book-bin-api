let jwt = require('jsonwebtoken'),
    moment = require('moment');

exports.checkToken = function (req, res, next) {
  if (req.headers && req.headers.authorization && req.headers.authorization.split(' ')[0] === 'BearerJWT') {
    jwt.verify(req.headers.authorization.split(' ')[1], process.env.JWT_TOKEN_SECRET, function(err, decode) {
      if (err) {
        if (err.name === 'TokenExpiredError') return res.status(401).json({ status: false, message: 'Your session has expired' });
        return res.status(500).json({ status: false, message: 'Authorization error' });
      }
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
