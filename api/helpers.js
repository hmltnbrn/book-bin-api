exports.insertHelper = function(fields, totalExtra = 0) { // totalExtra is the number of attributes that are before the fields array (defaults to 0)
  let insertParts = '';
  for (var i=0; i<fields.length; i++) {
    insertParts += fields[i];
    if(i !== fields.length - 1) {
      insertParts += ', ';
    }
    else {
      insertParts += ') VALUES (';
    }
  }
  for (var i=0; i<fields.length + totalExtra; i++) {
    insertParts += '$' + (i + 1);
    if(i !== fields.length + totalExtra - 1) {
      insertParts += ', ';
    }
    else {
      insertParts += ')';
    }
  }
  return insertParts;
}

exports.updateHelper = function(fields) {
  let updateParts = 'SET '
  for (var i=0; i<fields.length; i++) {
    updateParts += fields[i] + ' = $' + (i + 1) + ', ';
  }
  return updateParts.slice(0, -2);
}
