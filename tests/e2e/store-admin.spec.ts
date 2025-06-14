import { test, expect } from '@playwright/test';

const STORE_ADMIN_URL = process.env.STORE_ADMIN_URL || 'http://';

test.describe('store-front tests', () => {
  test.skip(STORE_ADMIN_URL === 'http://', 'STORE_ADMIN_URL is not set');

  test('has title', async ({ page }) => {
    await page.goto(STORE_ADMIN_URL);
    await expect(page).toHaveTitle(/Contoso Pet Store Admin Portal/);
  });


  test('can add product ', async ({ page }) => {
    await page.goto(STORE_ADMIN_URL);
    test.setTimeout(90000);

    await page.getByRole('link', { name: 'Products' }).click();
    await page.getByRole('button', { name: 'Add Product' }).click();

    await page.getByRole('textbox', { name: 'Name' }).fill('Super Snacks');
    await page.getByRole('spinbutton', { name: 'Price' }).fill('2.99');
    await page.getByRole('textbox', { name: 'Keywords' }).fill('dog, snack, treat');

    const askOpenAI = page.getByRole('button', { name: 'Ask AI Assistant' });

    if (await askOpenAI.isVisible()) {
      const aiApiCall = page.waitForResponse('/api/ai/generate/description');
      await askOpenAI.click();
      await aiApiCall;
    }
    else {
      await page.getByRole('textbox', { name: 'Description' }).fill('Something tasty for the pups');
    }

    page.once('dialog', dialog => {
      console.log(`Dialog message: ${dialog.message()}`);
      expect(dialog.message()).toBe('Product saved successfully');
      dialog.dismiss().catch(() => { });
    });

    await page.getByRole('button', { name: 'Save Product' }).click();
  });
});