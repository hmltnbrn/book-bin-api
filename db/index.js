"use strict";

let pg = require('pg'),
    config = require('./config'),
    databaseURL = config.databaseURL;

exports.query = function (sql, values, singleItem, dontLog) {

  if (!dontLog) {
    console.log(sql, values);
  }

  const client = new pg.Client({
    connectionString: databaseURL
  });

  return new Promise((resolve, reject) => {

      client.connect((err) => {
        if (err) {
          reject(err);
        }
        client.query(sql, values, function (err, res) {
          if (err) {
            client.end();
            reject(err);
          } else {
            client.end();
            resolve(singleItem ? res.rows[0] : res.rows);
          }
        });
      });

  });

};
