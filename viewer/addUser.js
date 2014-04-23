/******************************************************************************/
/* addUser.js -- Create a new user in the database
 *
 * addUser.js <user id> <user friendly name> <password> [-noweb] [-admin]
 *
 * Copyright 2012-2014 AOL Inc. All rights reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this Software except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*jshint
  node: true, plusplus: false, curly: true, eqeqeq: true, immed: true, latedef: true, newcap: true, nonew: true, undef: true, strict: true, trailing: true
*/
"use strict";
var Config = require("./config.js");
var Db = require ("./db.js");
var crypto = require('crypto');

var escInfo = Config.get("elasticsearch", "localhost:9200").split(':');
Db.initialize({host : escInfo[0], port: escInfo[1]});

function help() {
  console.log("addUser.js <user id> <user friendly name> <password> [<options>]");
  console.log("");
  console.log("Options:");
  console.log("  --admin      Has admin privileges");
  console.log("  --apionly    Can only use api, not web pages");
  console.log("  --email      Can do email searches");
  console.log("  --remove     Can remove data (scrub, delete tags)");
  console.log("  --webauth    Can auth using the web auth header");

  process.exit(0);
}

if (process.argv.length < 5) {
  help();
}

var nuser = {
  userId: process.argv[2],
  userName: process.argv[3],
  passStore: Config.pass2store(process.argv[2], process.argv[4]),
  enabled: true,
  webEnabled: true,
  headerAuthEnabled: false,
  emailSearch: false,
  createEnabled: false,
  removeEnabled: false
};

var i;
for (i = 5; i < process.argv.length; i++) {
  switch(process.argv[i]) {
  case "--admin":
  case "-admin":
    nuser.createEnabled = true;
    break;

  case "--remove":
  case "-remove":
    nuser.removeEnabled = true;
    break;

  case "--noweb":
  case "-noweb":
  case "--apionly":
    nuser.webEnabled = false;
    break;
    
  case "--webauth":
  case "-webauth":
    nuser.headerAuthEnabled = true;
    break;

  case "--email":
  case "-email":
    nuser.emailSearch = true;
    break;

  default:
    console.log("Unknown option", process.argv[i]);
    help();
  }
}

Db.indexNow("users", "user", process.argv[2], nuser, function(err, info) {
  if (err) {
    console.log("Elastic search error", err);
  }

  if (info.ok !== true) {
    console.log("Failed to add user\n", nuser, "\nError\n", info);
  } else {
    console.log("Added");
  }
  Db.close();
});
