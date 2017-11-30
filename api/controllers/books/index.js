let express = require('express'),
    router = express.Router();

let books = require('./books');

// api/Books
router.get('/', books.getAllBooks);

// api/Books/TeacherBooks
router.get('/TeacherBooks', books.getAllTeacherBooks);

// api/Books/CheckOut
router.post('/CheckOut', books.postCheckOutBook);

module.exports = router;
