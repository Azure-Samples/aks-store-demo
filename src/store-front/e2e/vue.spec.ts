import { test, expect } from '@playwright/test';

// See here how to get started:
// https://playwright.dev/docs/intro
test('visits the cart url', async ({ page }) => {
  await page.goto('/cart');
  await expect(page.locator('h3')).toHaveText('Your shopping cart is empty');
})
