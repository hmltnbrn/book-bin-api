let express = require('express'),
    router = express.Router();

let students = require('./students');
let teacherStudents = require('./teacher-students.students');

// api/Students/TeacherStudents
router.get('/TeacherStudents', teacherStudents.getAll);

// api/Students
router.get('/', students.getAll);
router.get('/:id', students.get);
router.put('/', students.put);
router.patch('/', students.patch);
router.delete('/:id', students.delete);

module.exports = router;
