import {cpSync, existsSync, mkdirSync, renameSync, rmSync} from 'node:fs';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const e2eDirectory = fileURLToPath(new URL('.', import.meta.url));
const outputRoot = resolve(e2eDirectory, '../example/build/jaspr');
const projectRoot = resolve(outputRoot, 'jaspr_hooks');

if (!existsSync(resolve(outputRoot, 'index.html'))) {
  if (!existsSync(resolve(projectRoot, 'index.html'))) {
    throw new Error(
      `The built documentation site was not found at ${outputRoot}. ` +
        'Run "cd example && jaspr build" first.',
    );
  }
  process.exit(0);
}

const stagingRoot = resolve(e2eDirectory, '.staged-site');
rmSync(stagingRoot, {force: true, recursive: true});
rmSync(projectRoot, {force: true, recursive: true});
mkdirSync(stagingRoot, {recursive: true});
cpSync(outputRoot, resolve(stagingRoot, 'jaspr_hooks'), {
  recursive: true,
});
renameSync(resolve(stagingRoot, 'jaspr_hooks'), projectRoot);
