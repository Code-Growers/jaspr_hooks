import {expect, test} from '@playwright/test';

interface ServerSnapshot {
  ids: string[];
  nodes: Element[];
}

test('generated client boundaries preserve scoped IDs and server DOM through interaction', async ({page}) => {
  const failures: string[] = [];
  page.on('pageerror', (error) => failures.push(error.message));
  page.on('console', (message) => {
    if (message.type() === 'error' || message.text().includes('Warning: Server component')) {
      failures.push(message.text());
    }
  });
  let releaseScripts!: () => void;
  const scriptsReady = new Promise<void>((resolve) => { releaseScripts = resolve; });
  await page.route('**/*.js', async (route) => {
    await scriptsReady;
    await route.continue();
  });

  try {
    const response = await page.goto('guides/server-components/', {waitUntil: 'commit'});
    expect(response?.ok()).toBe(true);
    const demo = page.locator('[data-server-composition]');
    await demo.waitFor({state: 'attached'});
    await page.evaluate(() => {
      const demo = document.querySelector('[data-server-composition]')!;
      (window as Window & {__serverSnapshot?: ServerSnapshot}).__serverSnapshot = {
        ids: Array.from(demo.querySelectorAll('[id]'), (node) => node.id),
        nodes: Array.from(demo.querySelectorAll('[data-server-content], [data-server-content] > p')),
      };
    });
    releaseScripts();
    await page.waitForLoadState('networkidle');

    const first = page.locator('[data-server-card="First card"]');
    const second = page.locator('[data-server-card="Second card"]');
    await expect(first.locator('[data-server-panel]')).toBeHidden();
    await first.getByRole('button', {name: 'Expand First card'}).click();
    await expect(first.locator('[data-server-panel]')).toBeVisible();
    await expect(first.locator('[data-server-content]')).toContainText('read from a file on the server');
    const counter = first.locator('[data-server-counter]');
    await counter.click();
    await expect(counter).toHaveText('Nested count: 1');
    await first.getByRole('button', {name: 'Collapse First card'}).click();
    await first.getByRole('button', {name: 'Expand First card'}).click();
    await expect(counter).toHaveText('Nested count: 1');
    await second.getByRole('button', {name: 'Expand Second card'}).click();
    await expect(second.locator('[data-server-counter]')).toHaveText('Nested count: 0');

    const result = await page.evaluate(() => {
      const demo = document.querySelector('[data-server-composition]')!;
      const snapshot = (window as Window & {__serverSnapshot?: ServerSnapshot}).__serverSnapshot!;
      const ids = Array.from(demo.querySelectorAll('[id]'), (node) => node.id);
      const nodes = Array.from(demo.querySelectorAll('[data-server-content], [data-server-content] > p'));
      return {
        originalIds: snapshot.ids,
        ids,
        unique: new Set(ids).size === ids.length,
        sameNodes: nodes.every((node, index) => node === snapshot.nodes[index]),
        linked: Array.from(demo.querySelectorAll('[aria-controls], [aria-labelledby]')).every((node) =>
          ['aria-controls', 'aria-labelledby'].every((attribute) =>
            !node.hasAttribute(attribute) || document.getElementById(node.getAttribute(attribute)!) !== null,
          ),
        ),
      };
    });
    expect(result.ids).toEqual(result.originalIds);
    expect(result.unique).toBe(true);
    expect(result.sameNodes).toBe(true);
    expect(result.linked).toBe(true);

    const oldCounter = await counter.elementHandle();
    await demo.getByRole('button', {name: 'Remove cards'}).click();
    await expect(page.locator('[data-server-card]')).toHaveCount(0);
    // Removed nodes must not retain handlers that mutate disposed hook state.
    await oldCounter!.evaluate((node) => node.dispatchEvent(new MouseEvent('click')));
    expect(failures).toEqual([]);
  } finally {
    releaseScripts();
  }
});
