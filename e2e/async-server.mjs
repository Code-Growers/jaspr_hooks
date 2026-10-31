import {spawn} from 'node:child_process';
import {existsSync, mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';

const exampleRoot = fileURLToPath(new URL('../example/', import.meta.url));
const webRoot = fileURLToPath(new URL('../example/build/jaspr/jaspr_hooks/', import.meta.url));
const deadline = Date.now() + 30_000;
while (!existsSync(`${webRoot}/index.html`)) {
  if (Date.now() > deadline) throw new Error('Build and stage the documentation before running async hook E2E tests.');
  await new Promise((resolve) => setTimeout(resolve, 50));
}

const executable = `${exampleRoot}/build/async-hooks-e2e${process.platform === 'win32' ? '.exe' : ''}`;
mkdirSync(`${exampleRoot}/build`, {recursive: true});
let child = spawn('dart', [
  'compile', 'exe', 'test/support/async_hooks_e2e.dart',
  '-o', executable, '-Djaspr.flags.release=true',
], {cwd: exampleRoot, stdio: 'inherit'});
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => child.kill(signal));
await new Promise((resolve, reject) => {
  child.on('error', reject);
  child.on('exit', (code) => code === 0 ? resolve() : reject(new Error(`Async fixture compilation failed: ${code}`)));
});

child = spawn(executable, [], {
  cwd: exampleRoot,
  stdio: 'inherit',
  env: {...process.env, JASPR_HOOKS_E2E_WEB: webRoot},
});
child.on('error', (error) => { throw error; });
child.on('exit', (code) => { process.exitCode = code ?? 0; });
