import { test, expect } from '@playwright/test';

const STORE_FRONT_URL = process.env.STORE_FRONT_URL || 'http://';

test.describe('store-front tests', () => {
  test.skip(STORE_FRONT_URL === 'http://', 'STORE_FRONT_URL is not set');

  test('has title', async ({ page }) => {
    await page.goto(STORE_FRONT_URL);
    await expect(page).toHaveTitle(/Contoso Pet Store/);
  });

  test('has products and cart links', async ({ page }) => {
    await page.goto(STORE_FRONT_URL);
    await page.getByRole('link', { name: /Products/ }).click();
    await page.getByRole('link', { name: /Cart/ }).click();
  });

  test('can navigate to product details and add one to cart', async ({ page }) => {
    await page.goto(STORE_FRONT_URL);

    await page.locator('.product-list .product-card').first().click()
    await expect(page.url()).toContain('product')
    await expect(page.locator('.product-info h2')).toHaveText("Contoso Catnip's Friend");

    const cartLink = page.getByRole('link', { name: /Cart \(\d+\)/ });
    const initialCartCount = parseInt((await cartLink.textContent() || '').match(/\d+/)?.[0] || '0');

    await page.getByRole('button', { name: /Add to Cart/ }).click();
    await expect(cartLink).toHaveText(`Cart (${initialCartCount + 1})`);
  });

  test('can add one to cart from home page', async ({ page }) => {
    await page.goto(STORE_FRONT_URL);

    await expect(page.locator('.product-list')).toBeVisible();

    const cartLink = page.getByRole('link', { name: /Cart \(\d+\)/ });
    const initialCartCount = parseInt((await cartLink.textContent() || '').match(/\d+/)?.[0] || '0');

    const firstProduct = page.locator('.product-list .product-controls').first();
    await firstProduct.getByRole('button', { name: /Add to Cart/ }).click();

    await expect(cartLink).toHaveText(`Cart (${initialCartCount + 1})`);
  });

  test('can add multiple items to cart from home page', async ({ page }) => {
    await page.goto(STORE_FRONT_URL);

    await expect(page.locator('.product-list')).toBeVisible();

    const cartLink = page.getByRole('link', { name: /Cart \(\d+\)/ });
    const initialCartCount = parseInt((await cartLink.textContent() || '').match(/\d+/)?.[0] || '0');

    const firstProduct = page.locator('.product-list .product-controls').first();
    await firstProduct.getByRole('button', { name: /Add to Cart/ }).click();

    const lastProduct = page.locator('.product-list .product-controls').last();
    await lastProduct.getByRole('button', { name: /Add to Cart/ }).click();

    await expect(cartLink).toHaveText(`Cart (${initialCartCount + 2})`);
  });

  test('can place an order', async ({ page }) => {
    await page.goto(STORE_FRONT_URL);

    await expect(page.locator('.product-list')).toBeVisible();

    const firstProduct = page.locator('.product-list .product-controls').first();
    await firstProduct.getByRole('button', { name: /Add to Cart/ }).click();

    const lastProduct = page.locator('.product-list .product-controls').last();
    await lastProduct.getByRole('button', { name: /Add to Cart/ }).click();

    await page.getByRole('link', { name: /Cart \(\d+\)/ }).click();
    await page.getByRole('button', { name: 'Checkout' }).click();

    page.on('dialog', async dialog => {
      expect(dialog.message()).toContain('Order submitted successfully');
      await dialog.accept();
    });
  });
});