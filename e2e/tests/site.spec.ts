import {expect, test, type Page} from '@playwright/test';

import {hookPages} from './catalog';

function collectRuntimeFailures(page: Page): string[] {
  const failures: string[] = [];
  page.on('console', (message) => {
    if (message.type() === 'error') failures.push(`console: ${message.text()}`);
  });
  page.on('pageerror', (error) => failures.push(`page: ${error.message}`));
  page.on('requestfailed', (request) => {
    failures.push(
      `network: ${request.method()} ${request.url()} ` +
        `(${request.failure()?.errorText ?? 'unknown error'})`,
    );
  });
  return failures;
}

async function setDocumentHidden(page: Page, hidden: boolean): Promise<boolean> {
  return page.evaluate((nextHidden) => {
    const testWindow = window as Window & {__jasprHooksHidden?: boolean};
    testWindow.__jasprHooksHidden = nextHidden;
    Object.defineProperty(document, 'hidden', {
      configurable: true,
      get: () => testWindow.__jasprHooksHidden,
    });
    for (const eventType of [
      'visibilitychange',
      'webkitvisibilitychange',
      'mozvisibilitychange',
      'msvisibilitychange',
    ]) {
      document.dispatchEvent(new Event(eventType));
    }
    return document.hidden;
  }, hidden);
}

test('home page uses base-aware assets and hydrates', async ({page}) => {
  const failures = collectRuntimeFailures(page);
  const response = await page.goto('./', {waitUntil: 'networkidle'});

  expect(response?.ok()).toBe(true);
  await expect(page).toHaveTitle(/jaspr_hooks/i);
  await expect(page.locator('main')).toContainText('jaspr_hooks');

  const mascot = page.locator('img[alt*="fishing" i], img[alt*="mascot" i]').first();
  await expect(mascot).toBeVisible();
  await expect
    .poll(() => mascot.evaluate((image: HTMLImageElement) => image.naturalWidth))
    .toBeGreaterThan(0);
  expect(failures).toEqual([]);
});

test('documentation theme styles survive client-island hydration', async ({page}) => {
  await page.goto('hooks/use-effect/', {waitUntil: 'networkidle'});
  await expect(page.getByTestId('hook-output').first()).toContainText(/effect runs 1/i);

  const styles = await page.evaluate(() => {
    const demo = document.querySelector<HTMLElement>('.hook-demo');
    if (demo == null) throw new Error('Hook demo was not rendered.');
    const bodyStyle = getComputedStyle(document.body);
    const demoStyle = getComputedStyle(demo);
    return {
      bodyFont: bodyStyle.fontFamily,
      bodyBackground: bodyStyle.backgroundColor,
      demoBorder: demoStyle.borderTopWidth,
    };
  });

  expect(styles.bodyFont).toMatch(/Open Sans|system-ui/i);
  expect(styles.bodyBackground).not.toBe('rgba(0, 0, 0, 0)');
  expect(styles.demoBorder).toBe('1px');
});

for (const hook of hookPages) {
  test(`${hook.api} page direct-loads with docs and demo`, async ({page}) => {
    const failures = collectRuntimeFailures(page);
    const response = await page.goto(`hooks/${hook.slug}/`, {
      waitUntil: 'networkidle',
    });

    expect(response?.ok()).toBe(true);
    await expect(page.locator('h1').first()).toContainText(hook.api);
    await expect(page.locator('pre code').first()).toBeVisible();
    await expect(page.locator(`[data-hook-demo="${hook.api}"]`)).toBeVisible();
    await expect(page.locator('meta[name="description"]')).toHaveAttribute(
      'content',
      /\S+/,
    );

    const action = page.getByTestId('hook-action');
    const output = page.getByTestId('hook-output');
    if ((await action.count()) > 0 && (await output.count()) > 0) {
      const before = await output.first().textContent();
      await action.first().click();
      await expect
        .poll(() => output.first().textContent())
        .not.toBe(before);
    }

    expect(failures).toEqual([]);
  });
}

test('preferred color scheme follows browser media changes', async ({page}) => {
  await page.emulateMedia({colorScheme: 'light'});
  await page.goto('hooks/use-preferred-color-scheme/', {waitUntil: 'networkidle'});
  const output = page.getByTestId('hook-output').first();
  await expect(output).toContainText(/light/i);

  await page.emulateMedia({colorScheme: 'dark'});
  await expect(output).toContainText(/dark/i);
});

test('preferred color scheme callback receives previous and current states', async ({page}) => {
  await page.emulateMedia({colorScheme: 'light'});
  await page.goto('hooks/use-on-preferred-color-scheme-change/', {
    waitUntil: 'networkidle',
  });
  const output = page.getByTestId('hook-output').first();
  await expect(output).toContainText(/no changes yet/i);

  await page.emulateMedia({colorScheme: 'dark'});
  await expect(output).toContainText(/light → dark/i);
  await page.emulateMedia({colorScheme: 'light'});
  await expect(output).toContainText(/dark → light/i);
});

test('document visibility reacts to browser visibility changes', async ({page}) => {
  await page.goto('hooks/use-document-visibility/', {waitUntil: 'networkidle'});
  const output = page.getByTestId('hook-output').first();
  await expect(output).toContainText(/visible/i);

  expect(await setDocumentHidden(page, true)).toBe(true);
  await expect(output).toContainText(/hidden/i);
  expect(await setDocumentHidden(page, false)).toBe(false);
  await expect(output).toContainText(/visible/i);
});

test('document visibility callback receives previous and current states', async ({page}) => {
  await page.goto('hooks/use-on-document-visibility-change/', {waitUntil: 'networkidle'});
  const output = page.getByTestId('hook-output').first();
  await expect(output).toContainText(/no changes yet/i);

  expect(await setDocumentHidden(page, true)).toBe(true);
  await expect(output).toContainText(/visible → hidden/i);
  expect(await setDocumentHidden(page, false)).toBe(false);
  await expect(output).toContainText(/hidden → visible/i);
});
