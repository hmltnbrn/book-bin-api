let books = require('./controllers/books/books'),
    auth = require('../auth');

module.exports = function(app) {

  app.all('/api/*', auth.checkToken);

  app.route('/api/Books')
    .get(books.getAllBooks);
  app.route('/api/Books/GetAllTeacherBooks')
    .get(books.getAllTeacherBooks);

}
