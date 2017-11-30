let express = require('express'),
    router = express.Router();

let students = require('./students');

// api/Students/ActiveStudents
router.get('/ActiveStudents', students.getAllActiveStudents);

module.exports = router;
