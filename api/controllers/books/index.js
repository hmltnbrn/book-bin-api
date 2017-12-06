let express = require('express'),
    router = express.Router();

let books = require('./books');

// api/Books/TeacherBooks
router.get('/TeacherBooks', books.getAllTeacherBooks);

// api/Books/CheckOut
router.post('/CheckOut', books.postCheckOutBook);

// api/Books/CheckIn
router.post('/CheckIn', books.postCheckInBook);

// api/Books/Students
router.get('/Students', books.getStudentsWithBook);

// api/Books
router.get('/', books.getAllBooks);
router.get('/:id', books.getBook);

module.exports = router;
