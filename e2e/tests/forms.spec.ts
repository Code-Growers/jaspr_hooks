import {expect, test} from '@playwright/test';

test('form fields display client and server errors, then acknowledge a save', async ({page}) => {
  await page.goto('hooks/use-form/', {waitUntil: 'networkidle'});
  const demo = page.locator('[data-hook-demo="useForm"]');
  const name = demo.getByRole('textbox', {name: 'Name', exact: true});
  const save = demo.getByRole('button', {name: 'Save', exact: true});
  await save.click();
  await expect(demo.getByRole('alert')).toHaveText('Enter a name.');
  await name.fill('taken');
  await save.click();
  await expect(demo.getByRole('alert')).toHaveText('This name is already used.');
  await expect(demo).toContainText('Unsaved: true');
  await name.fill('Petra');
  await save.click();
  await expect(save).toBeDisabled();
  await expect(demo).toContainText('Unsaved: false; status: success; saved: Petra');
  await expect(demo.getByRole('alert')).toHaveCount(0);
});

test('form acknowledgements preserve edits made while a save is pending', async ({page}) => {
  await page.goto('hooks/use-form-state/', {waitUntil: 'networkidle'});
  const demo = page.locator('[data-hook-demo="useFormState"]');
  const name = demo.getByRole('textbox', {name: 'Name', exact: true});
  await name.fill('Petra');
  await demo.getByRole('button', {name: 'Save', exact: true}).click();
  await name.fill('Eva');
  await expect(demo).toContainText('status: success; saved: Petra');
  await expect(name).toHaveValue('Eva');
  await expect(demo).toContainText('Unsaved: true');
  await expect(demo).toContainText('Navigation requires confirmation: true');
  await name.fill('Petra');
  await expect(demo).toContainText('Navigation requires confirmation: false');
});

test('optional autosave acknowledges edits and reset clears the draft', async ({page}) => {
  await page.goto('hooks/use-form-autosave/', {waitUntil: 'networkidle'});
  const demo = page.locator('[data-hook-demo="useFormAutosave"]');
  const name = demo.getByRole('textbox', {name: 'Name', exact: true});
  await demo.getByRole('button', {name: 'Autosave: false', exact: true}).click();
  await name.fill('Petra');
  await expect(demo).toContainText('Unsaved: false; status: success; saved: Petra');
  await demo.getByRole('button', {name: 'Reset', exact: true}).click();
  await expect(name).toHaveValue('');
  await expect(demo).toContainText('Unsaved: false; status: idle');
});
