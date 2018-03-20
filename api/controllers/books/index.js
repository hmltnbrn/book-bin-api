let express = require('express'),
    router = express.Router();

let books = require('./books');
let checkOut = require('./check-out.books');
let checkIn = require('./check-in.books');
let teacherBooks = require('./teacher-books.books');
let students = require('./students.books');

// api/Books/TeacherBooks
router.get('/TeacherBooks', teacherBooks.getAll);
router.get('/TeacherBooks/:id', teacherBooks.get);
router.put('/TeacherBooks', teacherBooks.put);
router.patch('/TeacherBooks', teacherBooks.patch);
router.delete('/TeacherBooks/:id', teacherBooks.delete);

// api/Books/CheckOut
router.post('/CheckOut', checkOut.post);

// api/Books/CheckIn
router.post('/CheckIn', checkIn.post);
router.post('/CheckIn/Students', checkIn.postWithStudents, teacherBooks.get);

// api/Books/Students
router.get('/Students', students.getAll);

// api/Books
router.get('/', books.getAll);
router.get('/:id', books.get);

module.exports = router;
