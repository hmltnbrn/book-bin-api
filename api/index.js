let books = require('./controllers/books/books'),
    students = require('./controllers/students/students'),
    auth = require('../auth');

module.exports = function(app) {

  app.all('/api/*', auth.checkToken);

  app.route('/api/Books')
    .get(books.getAllBooks);
  app.route('/api/Books/GetAllTeacherBooks')
    .get(books.getAllTeacherBooks);
  app.route('/api/Books/CheckOutBook')
    .post(books.postCheckOutBook);

  app.route('/api/Students/GetAllActiveStudents')
    .get(students.getAllActiveStudents);

}
