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

for (const hook of hookPages) {
  test(`${hook.api} documentation is statically rendered`, async ({page}) => {
    const response = await page.goto(`hooks/${hook.slug}/`);
    expect(response?.ok()).toBe(true);
    await expect(page.locator('h1').first()).toContainText(hook.api);
    await expect(page.locator('pre code').first()).toBeVisible();
  });
}
