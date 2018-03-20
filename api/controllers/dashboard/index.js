let express = require('express'),
    router = express.Router();

let dashboard = require('./dashboard');

// api/Dashboard
router.get('/', dashboard.get);

module.exports = router;
