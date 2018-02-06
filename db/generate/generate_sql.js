var fs = require('fs');

let domains,
    tables,
    data,
    functions,
    views;

fs.readFileAsync = function(filename, parse, enc) {
  return new Promise(function(resolve, reject) {
    fs.readFile(filename, enc, function(err, data){
      if (err) 
        reject(err); 
      else
        parse ? resolve(parseFile(data)) : resolve(data);
    });
  });
};

fs.readFileAsync('./db/sql/domains.sql', true, 'utf8')
  .then(contents => {
    domains = contents;
  })
  .catch(err => {
    console.log(err);
  });

fs.readFileAsync('./db/sql/tables.sql', true, 'utf8')
  .then(contents => {
    tables = contents;
    createFile();
  })
  .catch(err => {
    console.log(err);
  });

fs.readFileAsync('./db/sql/data.sql', true, 'utf8')
  .then(contents => {
    data = contents;
  })
  .catch(err => {
    console.log(err);
  });

fs.readFileAsync('./db/sql/functions.sql', true, 'utf8')
  .then(contents => {
    functions = contents;
  })
  .catch(err => {
    console.log(err);
  });

fs.readFileAsync('./db/sql/views.sql', true, 'utf8')
  .then(contents => {
    views = contents;
    createFile();
  })
  .catch(err => {
    console.log(err);
  });

function parseFile(content) {
  var splitContent = content.split("\n");
  var dropContent = [];
  var createContent = [];
  var foundDrop = false;
  var foundCreate = false;
  for(var i=0;i<splitContent.length;i++) {
    if(splitContent[i].replace(/[\n\r]+/g, '') == '/* START DROPS */') {
      foundDrop = true;
      continue;
    }
    else if(splitContent[i].replace(/[\n\r]+/g, '') == '/* START CREATES */') {
      foundCreate = true;
      continue;
    }
    else if(splitContent[i].replace(/[\n\r]+/g, '') == '/* END DROPS */') {
      foundDrop = false;
      continue;
    }
    else if(splitContent[i].replace(/[\n\r]+/g, '') == '/* END CREATES */') {
      foundCreate = false;
      continue;
    }
    if(foundDrop) {
      dropContent.push(splitContent[i].replace(/[\n\r]+/g, ''));
    }
    if(foundCreate) {
      createContent.push(splitContent[i].replace(/[\n\r]+/g, ''));
    }
  }
  return { drops: dropContent, creates: createContent };
}

function createFile() {
  fs.readFileAsync('./db/generate/sql_template.txt', false, 'utf8')
    .then(contents => {
      var result = contents
        .replace('$function_drops', functions.drops.join("\n"))
        .replace('$view_drops', views.drops.join("\n"))
        .replace('$table_drops', tables.drops.join("\n"))
        .replace('$domain_drops', domains.drops.join("\n"))
        .replace('$domain_creates', domains.creates.join("\n"))
        .replace('$table_creates', tables.creates.join("\n"))
        .replace('$data_creates', data.creates.join("\n"))
        .replace('$function_creates', functions.creates.join("\n"))
        .replace('$view_creates', views.creates.join("\n"));

      fs.writeFile('./db/generate/test.sql', result, 'utf8', function (err) {
         if (err) return console.log(err);
      });
    })
    .catch(err => {
      console.log(err);
    });
}
