import {defineConfig, devices} from '@playwright/test';

const baseURL = 'http://127.0.0.1:4173/jaspr_hooks/';

export default defineConfig({
  testDir: './tests',
  outputDir: './test-results',
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI
    ? [['github'], ['html', {open: 'never', outputFolder: 'playwright-report'}]]
    : [['list'], ['html', {open: 'never', outputFolder: 'playwright-report'}]],
  use: {
    baseURL,
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
  webServer: [{
    command: 'node stage.mjs && node server.mjs',
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  }, {
    command: 'node async-server.mjs',
    url: 'http://127.0.0.1:4174/__health',
    reuseExistingServer: false,
    timeout: 60_000,
  }],
  projects: [
    {
      name: 'chromium',
      testIgnore: /static\.spec\.ts/,
      use: {...devices['Desktop Chrome']},
    },
    {
      name: 'firefox',
      testIgnore: /static\.spec\.ts/,
      use: {...devices['Desktop Firefox']},
    },
    {
      name: 'webkit',
      testIgnore: /static\.spec\.ts/,
      use: {...devices['Desktop Safari']},
    },
    {
      name: 'static-chromium',
      testMatch: /static\.spec\.ts/,
      use: {...devices['Desktop Chrome'], javaScriptEnabled: false},
    },
  ],
});
