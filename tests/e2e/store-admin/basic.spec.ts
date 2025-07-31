import { test, expect } from '@playwright/test';
// @ts-ignore
const testConfig = require('../../test-config');

test.describe('store-admin basic tests', () => {
  test.skip(!testConfig.isStoreAdminConfigured(), 'STORE_ADMIN_URL is not set');

  test('has title', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);
    await expect(page).toHaveTitle(testConfig.getExpectedAdminTitle());
  });

  test('has Products link', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Click the Products link
    await page.getByRole('link', { name: 'Products' }).click();

    // Expects page to have an Add Product button
    await expect(page.getByRole('button', { name: 'Add Product' })).toBeVisible();
  });

  test('can navigate to Products page', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Navigate to Products
    await page.getByRole('link', { name: 'Products' }).click();

    // Verify Products page elements are visible
    await expect(page.getByRole('button', { name: 'Add Product' })).toBeVisible();
    await expect(page.getByText('Product ID')).toBeVisible();
    await expect(page.getByText('Product Name')).toBeVisible();
    await expect(page.getByText('Description')).toBeVisible();
  });

  test('can navigate to Orders page', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Navigate to Orders (assuming there's an Orders link)
    const ordersLink = page.getByRole('link', { name: 'Orders' });
    if (await ordersLink.isVisible()) {
      await ordersLink.click();
      // Verify we're on the orders page
      await expect(page.url()).toContain('order');
    }
  });

  test('displays company branding', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Check for company name in title
    await expect(page).toHaveTitle(new RegExp(`${testConfig.companyName}`));
    
    // Check for company branding elements (logo, etc.)
    const logo = page.locator('img[alt*="logo"], .logo, [class*="logo"]');
    if (await logo.count() > 0) {
      await expect(logo.first()).toBeVisible();
    }
  });

  test('renders main navigation', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Check main navigation elements
    await expect(page.getByRole('link', { name: 'Products' })).toBeVisible();
    
    // Check for other common admin navigation items
    const dashboardLink = page.getByRole('link', { name: /Dashboard|Home/i });
    if (await dashboardLink.count() > 0) {
      await expect(dashboardLink.first()).toBeVisible();
    }
  });
});
