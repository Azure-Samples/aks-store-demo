import { test, expect } from '@playwright/test';

test.use({ baseURL: process.env.STORE_ADMIN_URL });

test('has title', async ({ page }) => {
  await page.goto('/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Contoso Pet Store Admin Portal/);
});

test('has Products link', async ({ page }) => {
  await page.goto('/');

  // Click the get started link.
  await page.getByRole('link', { name: 'Products' }).click();

  // Expects page to have an Add Product button.
  await expect(page.getByRole('button', { name: 'Add Product' })).toBeVisible();
});
