import {createReadStream, existsSync, statSync} from 'node:fs';
import {createServer} from 'node:http';
import {extname, join, normalize, resolve, sep} from 'node:path';
import {fileURLToPath} from 'node:url';

const host = process.env.E2E_HOST ?? '127.0.0.1';
const port = Number.parseInt(process.env.E2E_PORT ?? '4173', 10);
const basePath = '/jaspr_hooks/';
const e2eDirectory = fileURLToPath(new URL('.', import.meta.url));
const siteRoot = resolve(e2eDirectory, '../example/build/jaspr');

const contentTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.ico', 'image/x-icon'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.map', 'application/json; charset=utf-8'],
  ['.png', 'image/png'],
  ['.svg', 'image/svg+xml'],
  ['.webmanifest', 'application/manifest+json'],
  ['.woff', 'font/woff'],
  ['.woff2', 'font/woff2'],
]);

if (!existsSync(join(siteRoot, 'index.html'))) {
  throw new Error(
    `The built documentation site was not found at ${siteRoot}. ` +
      'Run "cd example && jaspr build" first.',
  );
}

function resolveRequest(requestUrl) {
  const url = new URL(requestUrl, `http://${host}:${port}`);
  if (!url.pathname.startsWith(basePath)) return null;

  const relativePath = decodeURIComponent(url.pathname.slice(basePath.length));
  const cleanPath = normalize(relativePath).replace(/^([/\\])+/, '');
  const stagedRoot = join(siteRoot, 'jaspr_hooks');
  const contentRoot = existsSync(join(stagedRoot, 'index.html')) ? stagedRoot : siteRoot;
  let candidate = resolve(contentRoot, cleanPath);
  if (candidate !== contentRoot && !candidate.startsWith(`${contentRoot}${sep}`)) {
    return null;
  }

  if (existsSync(candidate) && statSync(candidate).isDirectory()) {
    candidate = join(candidate, 'index.html');
  } else if (!extname(candidate)) {
    candidate = join(candidate, 'index.html');
  }

  if (!existsSync(candidate) || !statSync(candidate).isFile()) return null;
  return candidate;
}

createServer((request, response) => {
  if (request.url === '/jaspr_hooks') {
    response.writeHead(308, {location: basePath});
    response.end();
    return;
  }

  const file = resolveRequest(request.url ?? '/');
  if (file == null) {
    response.writeHead(404, {'content-type': 'text/plain; charset=utf-8'});
    response.end('Not found');
    return;
  }

  response.writeHead(200, {
    'cache-control': 'no-store',
    'content-type': contentTypes.get(extname(file)) ?? 'application/octet-stream',
  });
  createReadStream(file).pipe(response);
}).listen(port, host, () => {
  process.stdout.write(`Serving ${siteRoot} at http://${host}:${port}${basePath}\n`);
});
