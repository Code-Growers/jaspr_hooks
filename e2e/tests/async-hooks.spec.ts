import {randomUUID} from 'node:crypto';

import {expect, test, type APIRequestContext} from '@playwright/test';

const origin = 'http://127.0.0.1:4174';

interface Snapshot {
  events: string[];
  effects: number;
  contextMatches: boolean;
  lateError: string | null;
}

function endpoint(path: string, token: string, options: Record<string, string> = {}): string {
  return `${origin}/${path}?${new URLSearchParams({token, ...options})}`;
}

async function control(request: APIRequestContext, action: string, token: string, options: Record<string, string> = {}): Promise<Snapshot> {
  const response = await request.get(endpoint(action, token, options));
  expect(response.status()).toBe(200);
  return response.json() as Promise<Snapshot>;
}

async function awaitEvent(request: APIRequestContext, token: string, event: string): Promise<void> {
  await expect.poll(async () => {
    const response = await request.get(endpoint('__state', token));
    return response.ok() ? ((await response.json()) as Snapshot).events : [];
  }).toContain(event);
}

test('live HTTP requests interleave sequential awaits without sharing hook owners', async ({request}) => {
  const firstToken = `first-${randomUUID()}`;
  const secondToken = `second-${randomUUID()}`;
  const first = request.get(endpoint('page', firstToken, {hold: 'true'}), {timeout: 10_000});
  const second = request.get(endpoint('page', secondToken, {hold: 'true'}), {timeout: 10_000});
  await Promise.all([awaitEvent(request, firstToken, 'await:1'), awaitEvent(request, secondToken, 'await:1')]);

  await control(request, '__release', secondToken, {phase: '1'});
  await awaitEvent(request, secondToken, 'await:2');
  await control(request, '__release', firstToken, {phase: '1'});
  await awaitEvent(request, firstToken, 'await:2');
  await control(request, '__release', secondToken, {phase: '2'});
  const secondResponse = await second;
  expect(secondResponse.status()).toBe(200);
  const secondHtml = await secondResponse.text();
  expect(secondHtml).toContain(`before:${secondToken}|after:${secondToken}:`);
  expect(secondHtml).not.toContain(firstToken);
  await control(request, '__release', firstToken, {phase: '2'});
  const firstResponse = await first;
  expect(firstResponse.status()).toBe(200);
  const firstHtml = await firstResponse.text();
  expect(firstHtml).toContain(`before:${firstToken}|after:${firstToken}:`);
  expect(firstHtml).not.toContain(secondToken);

  for (const token of [firstToken, secondToken]) {
    const snapshot = await control(request, '__state', token);
    expect(snapshot.contextMatches).toBe(true);
    expect(snapshot.effects).toBe(0);
    expect(snapshot.events.filter((event) => event.startsWith('dispose:'))).toEqual([]);
    const late = await control(request, '__late', token);
    expect(late.lateError).toContain('completed or been unmounted');
    const disposed = await control(request, '__dispose', token);
    expect(disposed.events.filter((event) => event.startsWith('dispose:'))).toEqual(['dispose:after', 'dispose:before']);
  }
});

test('server-only async hooks render into generated boundaries and hydrate matching IDs', async ({page, request}) => {
  const token = `hydrate-${randomUUID()}`;
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  page.on('console', (message) => { if (message.type() === 'error') errors.push(message.text()); });
  let releaseScripts!: () => void;
  const ready = new Promise<void>((resolve) => { releaseScripts = resolve; });
  await page.route('**/*.js', async (route) => { await ready; await route.continue(); });
  try {
    const response = await page.goto(endpoint('page', token), {waitUntil: 'commit'});
    expect(response?.status()).toBe(200);
    const content = page.locator('[data-async-content]');
    await content.waitFor({state: 'attached'});
    const originalIds = await page.locator('[data-server-card] [id]').evaluateAll((nodes) => nodes.map((node) => node.id));
    const originalContent = await content.elementHandle();
    releaseScripts();
    await page.waitForLoadState('networkidle');

    await page.getByRole('button', {name: `Expand ${token}`}).click();
    await expect(content).toContainText(`nested:${token}`);
    await expect(content).toContainText(`sync:${token}`);
    const counter = content.locator('[data-server-counter]');
    await counter.click();
    await expect(counter).toHaveText('Nested count: 1');
    await page.getByRole('button', {name: `Collapse ${token}`}).click();
    await page.getByRole('button', {name: `Expand ${token}`}).click();
    await expect(counter).toHaveText('Nested count: 1');
    const hydratedIds = await page.locator('[data-server-card] [id]').evaluateAll((nodes) => nodes.map((node) => node.id));
    expect(hydratedIds).toEqual(originalIds);
    expect(new Set(hydratedIds).size).toBe(hydratedIds.length);
    expect(await originalContent!.evaluate((node) => node === document.querySelector('[data-async-content]'))).toBe(true);

    const late = await control(request, '__late', token);
    expect(late.lateError).toContain('completed or been unmounted');
    const disposed = await control(request, '__dispose', token);
    expect(disposed.contextMatches).toBe(true);
    expect(disposed.effects).toBe(0);
    expect(disposed.events.filter((event) => event.startsWith('dispose:'))).toEqual(['dispose:after', 'dispose:before']);
    await counter.click();
    await expect(counter).toHaveText('Nested count: 2');
    expect(errors).toEqual([]);
  } finally {
    releaseScripts();
  }
});

test('failures before/after await and forbidden live state finish with 500 and reverse cleanup', async ({request}) => {
  for (const failure of ['before', 'after', 'source', 'state']) {
    const token = `failure-${failure}-${randomUUID()}`;
    const response = await request.get(endpoint('page', token, {fail: failure}), {timeout: 5_000});
    expect(response.status()).toBe(500);
    const snapshot = await control(request, '__late', token);
    expect(snapshot.lateError).toContain('completed or been unmounted');
    expect(snapshot.effects).toBe(0);
    const expected = failure === 'before' ? ['dispose:before'] : ['dispose:after', 'dispose:before'];
    expect(snapshot.events.filter((event) => event.startsWith('dispose:'))).toEqual(expected);
    const disposed = await control(request, '__dispose', token);
    expect(disposed.events.filter((event) => event.startsWith('dispose:'))).toEqual(expected);
  }
});

test('unmount while awaiting ends the response and rejects hooks from a late completion', async ({request}) => {
  const token = `cancel-${randomUUID()}`;
  const pending = request.get(endpoint('page', token, {hold: 'true'}), {timeout: 5_000});
  await awaitEvent(request, token, 'await:1');
  const removed = await control(request, '__unmount', token);
  expect(removed.events.filter((event) => event.startsWith('dispose:'))).toEqual(['dispose:before']);
  const response = await pending;
  expect(response.status()).toBe(200);
  expect(await response.text()).not.toContain('data-async-content');
  await control(request, '__release', token, {phase: '1'});
  await awaitEvent(request, token, 'cancelled-hook-rejected');
  const snapshot = await control(request, '__late', token);
  expect(snapshot.lateError).toContain('completed or been unmounted');
  expect(snapshot.events.filter((event) => event.startsWith('dispose:'))).toEqual(['dispose:before']);
  await control(request, '__dispose', token);
});

test('a loader error after unmount is observed without breaking later HTTP requests', async ({request}) => {
  const token = `cancel-error-${randomUUID()}`;
  const pending = request.get(endpoint('page', token, {hold: 'true'}), {timeout: 5_000});
  await awaitEvent(request, token, 'await:1');
  await control(request, '__unmount', token);
  expect((await pending).status()).toBe(200);
  await control(request, '__reject', token);
  await awaitEvent(request, token, 'loader-error:1');
  const healthy = await request.get(`${origin}/__health`);
  expect(healthy.status()).toBe(200);
  const snapshot = await control(request, '__dispose', token);
  expect(snapshot.events.filter((event) => event.startsWith('dispose:'))).toEqual(['dispose:before']);
});
