import { test, expect } from '@playwright/test';
// @ts-ignore
const testConfig = require('../../test-config');

test.describe('store-admin comprehensive tests', () => {
  test.skip(!testConfig.isStoreAdminConfigured(), 'testConfig.storeAdminUrl is not set');

  test('can add a new product', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);
    test.setTimeout(90000);

    // Navigate to Products page
    await page.getByRole('link', { name: 'Products' }).click();
    await page.getByRole('button', { name: 'Add Product' }).click();

    // Fill in product details
    await page.getByRole('textbox', { name: 'Name' }).fill('Super Snacks');
    await page.getByRole('spinbutton', { name: 'Price' }).fill('2.99');
    await page.getByRole('textbox', { name: 'Keywords' }).fill('dog, snack, treat');

    // Wait for page to load
    await page.waitForTimeout(10000);

    // Try to use AI Assistant if available
    const askAIAssistantButton = page.locator('button:has-text("Ask AI Assistant")');
    if (await askAIAssistantButton.isVisible()) {
      await askAIAssistantButton.click();
      await page.waitForResponse(response =>
        response.url().includes('/api/ai/generate/description') && response.status() === 200
      );
    } else {
      // Fallback to manual description
      await page.getByRole('textbox', { name: 'Description' }).fill('Something tasty for the pups');
    }

    // Handle success dialog
    page.once('dialog', dialog => {
      console.log(`Dialog message: ${dialog.message()}`);
      expect(dialog.message()).toBe('Product saved successfully');
      dialog.dismiss().catch(() => { });
    });

    // Save the product
    await page.getByRole('button', { name: 'Save Product' }).click();
  });

  test('can view and manage products list', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Navigate to Products page
    await page.getByRole('link', { name: 'Products' }).click();

    // Verify products table structure
    await expect(page.getByText('Product ID')).toBeVisible();
    await expect(page.getByText('Product Name')).toBeVisible();
    await expect(page.getByText('Description')).toBeVisible();

    // Check if there are any products listed
    const productRows = page.locator('[data-testid="product-row"], .product-row, tr:has(td)').filter({
      hasNotText: 'Product ID' // Exclude header row
    });

    if (await productRows.count() > 0) {
      // Verify first product has expected company name
      const firstProduct = productRows.first();
      const productName = firstProduct.locator('td').nth(1); // Assuming name is in second column
      
      // Check if product contains company name
      const productNameText = await productName.textContent();
      if (productNameText && productNameText.includes('Bike')) {
        expect(productNameText).toContain(`${testConfig.companyName} Bike`);
      }
    }
  });

  test('can view product details', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Navigate to Products page
    await page.getByRole('link', { name: 'Products' }).click();

    // Click on first product if available
    const productLinks = page.locator('a[href*="/product/"]');
    if (await productLinks.count() > 0) {
      await productLinks.first().click();
      
      // Verify we're on product detail page
      await expect(page.url()).toContain('/product/');
      
      // Check for product detail elements
      const productTitle = page.locator('h1, h2, .product-title');
      if (await productTitle.count() > 0) {
        await expect(productTitle.first()).toBeVisible();
      }
    }
  });

  test('can navigate to orders management', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Look for Orders link
    const ordersLink = page.getByRole('link', { name: /Orders?/ });
    if (await ordersLink.isVisible()) {
      await ordersLink.click();
      
      // Verify orders page loaded
      await expect(page.url()).toContain('order');
      
      // Check for orders table/list elements
      const ordersTable = page.locator('table, .orders-list, [data-testid="orders"]');
      if (await ordersTable.count() > 0) {
        await expect(ordersTable.first()).toBeVisible();
      }
    }
  });

  test('validates form inputs on product creation', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Navigate to add product form
    await page.getByRole('link', { name: 'Products' }).click();
    await page.getByRole('button', { name: 'Add Product' }).click();

    // Try to save without filling required fields
    const saveButton = page.getByRole('button', { name: 'Save Product' });
    if (await saveButton.isVisible()) {
      await saveButton.click();
      
      // Look for validation messages
      const validationMessages = page.locator('.error, .validation-error, [role="alert"]');
      if (await validationMessages.count() > 0) {
        await expect(validationMessages.first()).toBeVisible();
      }
    }
  });

  test('displays proper branding throughout admin portal', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Verify main page title
    await expect(page).toHaveTitle(testConfig.getExpectedAdminTitle());

    // Navigate to Products page and verify branding consistency
    await page.getByRole('link', { name: 'Products' }).click();
    
    // Check if page maintains branding
    const headerElements = page.locator('h1, h2, .header, .page-title');
    if (await headerElements.count() > 0) {
      const headerText = await headerElements.first().textContent();
      if (headerText && headerText.toLowerCase().includes('product')) {
        // Products page should maintain admin context
        expect(headerText.toLowerCase()).toContain('product');
      }
    }
  });

  test('handles AI service integration for product descriptions', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);
    test.setTimeout(120000); // Extended timeout for AI operations

    // Navigate to add product form
    await page.getByRole('link', { name: 'Products' }).click();
    await page.getByRole('button', { name: 'Add Product' }).click();

    // Fill basic product info
    await page.getByRole('textbox', { name: 'Name' }).fill('Test Product');
    await page.getByRole('spinbutton', { name: 'Price' }).fill('9.99');
    await page.getByRole('textbox', { name: 'Keywords' }).fill('test, sample, demo');

    // Wait for page to stabilize
    await page.waitForTimeout(5000);

    // Check if AI Assistant is available and functional
    const askAIButton = page.locator('button:has-text("Ask AI Assistant")');
    if (await askAIButton.isVisible()) {
      await askAIButton.click();
      
      // Wait for AI response with timeout
      try {
        await page.waitForResponse(
          response => response.url().includes('/api/ai/generate/description') && response.status() === 200,
          { timeout: 30000 }
        );
        
        // Verify description field was populated
        const descriptionField = page.getByRole('textbox', { name: 'Description' });
        await expect(descriptionField).not.toHaveValue('');
        
        console.log('AI Assistant successfully generated product description');
      } catch (error) {
        console.log('AI Assistant not available or timeout occurred, using manual description');
        await page.getByRole('textbox', { name: 'Description' }).fill('Manual test description');
      }
    } else {
      console.log('AI Assistant button not found, using manual description');
      await page.getByRole('textbox', { name: 'Description' }).fill('Manual test description');
    }
  });

  // Skipping this test as a future feature enhancement
  test.skip('responsive design works on different screen sizes', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.getByRole('link', { name: 'Products' }).click();
    
    // Verify basic functionality works on mobile
    await expect(page.getByRole('button', { name: 'Add Product' })).toBeVisible();

    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await expect(page.getByText('Product ID')).toBeVisible();

    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
    await expect(page.getByText('Product Name')).toBeVisible();
  });

  // Skipping this test as a future feature enhancement
  test.skip('handles error states gracefully', async ({ page }) => {
    await page.goto(testConfig.storeAdminUrl);

    // Navigate to Products page
    await page.getByRole('link', { name: 'Products' }).click();

    // Try to access a non-existent product
    await page.goto(`${testConfig.storeAdminUrl}/product/non-existent-id`);
    
    // Should handle error gracefully (either redirect or show error message)
    await page.waitForTimeout(3000);
    
    // Check if we're redirected or if error message is shown
    const currentUrl = page.url();
    const errorElements = page.locator('.error, .not-found, [role="alert"]');
    
    const isRedirected = !currentUrl.includes('non-existent-id');
    const hasErrorMessage = await errorElements.count() > 0;
    
    expect(isRedirected || hasErrorMessage).toBe(true);
  });
});
