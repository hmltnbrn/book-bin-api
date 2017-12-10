exports.updateHelper = function(fields) {
  let updateParts = "SET "
  for(var i=0;i<fields.length;i++) {
    updateParts += fields[i] + " = $" + (i + 1) + ", ";
  }
  return updateParts.slice(0, -2);
}
