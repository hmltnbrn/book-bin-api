let express = require('express'),
    router = express.Router();

let classes = require('./classes');
let roster = require('./roster.classes');

// api/Classes/Roster
router.get('/Roster', roster.getAll);
router.get('/Roster/:id', roster.get);

// api/Classes
router.get('/', classes.getAll);
router.get('/:id', classes.get);
router.put('/', classes.put);
router.patch('/', classes.patch);
router.delete('/:id', classes.delete);

module.exports = router;
