let express = require('express'),
    books = require('./controllers/books'),
    classes = require('./controllers/classes'),
    dashboard = require('./controllers/dashboard'),
    librarians = require('./controllers/librarians'),
    students = require('./controllers/students'),
    auth = require('../auth/token'),
    router = express.Router();

router.all('/*', auth.checkToken);

router.use('/Books', books);
router.use('/Classes', classes);
router.use('/Dashboard', dashboard);
router.use('/Librarians', librarians);
router.use('/Students', students);

module.exports = router;
