import {expect, test} from '@playwright/test';

import {hookPages} from './catalog';

test('the home page remains useful without JavaScript', async ({page}) => {
  const response = await page.goto('./');
  expect(response?.ok()).toBe(true);
  await expect(page.locator('main')).toContainText('jaspr_hooks');
  await expect(page.locator('main')).toContainText(/hooks/i);
  await expect(page.getByTestId('ai-install-prompt')).toBeVisible();
});

test('AI agent documentation remains useful without JavaScript', async ({page}) => {
  const response = await page.goto('guides/ai-agents/');
  expect(response?.ok()).toBe(true);
  await expect(page.locator('h1').first()).toContainText(/AI agents/i);
  await expect(page.locator('main')).toContainText(/dart pub add jaspr_hooks/i);
  await expect(page.locator('main')).toContainText(/llms\.txt/i);
});

test('async server content and nested counters are present before hydration', async ({page}) => {
  const response = await page.goto('guides/server-components/');
  expect(response?.ok()).toBe(true);
  const demo = page.locator('[data-server-composition]');
  await expect(demo.locator('[data-server-content]')).toHaveCount(2);
  await expect(demo.locator('[data-server-counter]')).toHaveCount(2);
  expect(await demo.locator('[data-server-content]').first().textContent()).toContain('read from a file on the server');
  const ids = await demo.locator('[id]').evaluateAll((nodes) => nodes.map((node) => node.id));
  expect(new Set(ids).size).toBe(ids.length);
});

for (const hook of hookPages) {
  test(`${hook.api} documentation is statically rendered`, async ({page}) => {
    const response = await page.goto(`hooks/${hook.slug}/`);
    expect(response?.ok()).toBe(true);
    await expect(page.locator('h1').first()).toContainText(hook.api);
    await expect(page.locator('pre code').first()).toBeVisible();
  });
}
