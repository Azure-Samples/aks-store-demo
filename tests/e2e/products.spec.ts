import { test, expect } from '@playwright/test';

test.use({ baseURL: process.env.STORE_ADMIN_URL });

test('renders functionally', async ({ page }) => {
  await page.goto('/');

  // Click the get started link.
  await page.getByRole('link', { name: 'Products' }).click();

  // Expects page to have an Add Product button.
  await expect(page.getByRole('button', { name: 'Add Product' })).toBeVisible();
  await expect(page.getByText('Product ID')).toBeVisible();
  await expect(page.getByText('Product Name')).toBeVisible();
  await expect(page.getByText('Description')).toBeVisible();
});
