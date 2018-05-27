let express = require('express'),
    router = express.Router();

let librarians = require('./librarians');

// api/Librarians
router.get('/', librarians.getAll);
router.get('/:id', librarians.get);
router.put('/', librarians.put);
router.patch('/', librarians.patch);
router.delete('/:id', librarians.delete);

module.exports = router;
