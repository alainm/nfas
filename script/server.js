// Exempo simples apenas para verificação
var nodePort = process.env.PORT || 8080;
var http = require('http');
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Bemvindo ao NFAS!\n\nServer='+process.env.HOSTNAME+'\nApp='+process.env.USER+'\nPORT='+nodePort+'\nROOT_URL='+process.env.ROOT_URL+'\n');
}).listen(nodePort);
console.log('Server running at port:'+nodePort);

