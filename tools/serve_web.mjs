// Serves build/web with a single-page-app fallback, like Firebase Hosting.
// Run: node tools/serve_web.mjs [port]
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const root = new URL('../build/web/', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const port = Number(process.argv[2] ?? 8080);
const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.wasm': 'application/wasm',
  '.mp4': 'video/mp4', '.glb': 'model/gltf-binary', '.pdf': 'application/pdf', '.otf': 'font/otf', '.ttf': 'font/ttf',
  '.bin': 'application/octet-stream', '.ico': 'image/x-icon',
};

createServer(async (req, res) => {
  let path = normalize(decodeURIComponent(req.url.split('?')[0])).replace(/^([\/])+/, '');
  let file = join(root, path);
  try {
    if (!(await stat(file)).isFile()) throw new Error();
  } catch {
    file = join(root, 'index.html');
  }
  try {
    const body = await readFile(file);
    res.writeHead(200, { 'Content-Type': types[extname(file)] ?? 'application/octet-stream' });
    res.end(body);
  } catch {
    res.writeHead(404).end('Not found');
  }
}).listen(port, () => console.log(`Serving build/web on http://localhost:${port}`));
