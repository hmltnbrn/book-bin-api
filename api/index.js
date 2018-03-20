let express = require('express'),
    books = require('./controllers/books'),
    dashboard = require('./controllers/dashboard'),
    students = require('./controllers/students'),
    auth = require('../auth/token'),
    router = express.Router();

router.all('/*', auth.checkToken);

router.use('/Books', books);
router.use('/Dashboard', dashboard);
router.use('/Students', students);

module.exports = router;
