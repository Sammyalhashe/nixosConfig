import http from 'http';
import fs from 'fs';

const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    const data = {
      method: req.method,
      url: req.url,
      headers: req.headers,
      body: body
    };
    fs.writeFileSync('/home/salhashemi2/nc/request.json', JSON.stringify(data, null, 2));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ choices: [{ message: { content: 'mock' } }] }));
    setTimeout(() => process.exit(0), 100);
  });
});

server.listen(8082, '127.0.0.1', () => {
  console.log('Mock server listening on 8082');
});
