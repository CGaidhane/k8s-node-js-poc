var http = require('http');
var url = require('url');
var server = http.createServer(function(req, res) {
 var page = url.parse(req.url).pathname;
 console.log(page);
 res.writeHead(200, {"Content-Type": "text/plain"});
 
 if (page == '/') {
   res.write('HOMEPAGE');
 }
 else if (page == '/dir1') {
  res.write('WELCOME PAGE');
 }
 else if (page == '/dir2/person/1') {
  res.write('REQUIRED INFORMATION');
 }
 res.end();
});
server.listen(8080);