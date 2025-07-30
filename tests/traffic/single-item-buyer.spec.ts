import { test, expect } from '@playwright/test';
// @ts-ignore
const testConfig = require('../test-config');

/**
 * Single Item Buyer Simulation
 * 
 * This test simulates a focused customer who knows what they want,
 * quickly finds a specific product, and makes a single purchase.
 */
test.describe('Single Item Buyer Traffic Simulation', () => {
  test.skip(!testConfig.isStoreFrontConfigured(), 'Store front URL is not configured');

  test('focused buyer - direct product purchase', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    await expect(page).toHaveTitle(testConfig.getExpectedStoreFrontTitle());

    // Quick scan of available products
    await expect(page.locator('.product-list')).toBeVisible();
    
    // Find and click on the first product (simulating targeted selection)
    const firstProduct = page.locator('.product-list .product-card').first();
    await expect(firstProduct).toBeVisible();
    
    // Read product details quickly
    await firstProduct.click();
    
    // Wait a moment to "read" product information (realistic behavior)
    await page.waitForTimeout(1000);
    
    // Add to cart directly
    await page.getByRole('button', { name: /Add to Cart/i }).click();
    
    // Verify item was added to cart
    const cartLink = page.getByRole('link', { name: /Cart/i });
    await expect(cartLink).toContainText('1');
    
    // Navigate to cart to complete purchase
    await cartLink.click();
    
    // Simulate reviewing cart contents
    await page.waitForTimeout(500);
    
    // Look for checkout or place order button
    const checkoutButton = page.locator('button:has-text("Checkout"), button:has-text("Place Order"), button:has-text("Complete Order")').first();
    if (await checkoutButton.isVisible({ timeout: 2000 })) {
      await checkoutButton.click();
      // Wait for order processing
      await page.waitForTimeout(1000);
    }
  });

  test('impulse buyer - quick add from homepage', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // Briefly browse homepage products
    await expect(page.locator('.product-list')).toBeVisible();
    await page.waitForTimeout(800);
    
    // Get initial cart count
    const cartLink = page.getByRole('link', { name: /Cart/i });
    const initialCartText = await cartLink.textContent() || '';
    const initialCount = parseInt(initialCartText.match(/\\d+/)?.[0] || '0');
    
    // Quick impulse purchase - add first visible product
    const firstProductAddButton = page.locator('.product-list .product-controls').first()
      .getByRole('button', { name: /Add to Cart/i });
    await firstProductAddButton.click();
    
    // Verify cart updated
    await expect(cartLink).toContainText(`${initialCount + 1}`);
    
    // Navigate to cart immediately (impulse behavior)
    await cartLink.click();
    
    // Quick checkout
    await page.waitForTimeout(300);
    const checkoutButton = page.locator('button:has-text("Checkout"), button:has-text("Place Order"), button:has-text("Complete Order")').first();
    if (await checkoutButton.isVisible({ timeout: 2000 })) {
      await checkoutButton.click();
    }
  });

  test('price-conscious buyer - product comparison', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // Browse multiple products to compare (realistic behavior)
    const products = page.locator('.product-list .product-card');
    const productCount = await products.count();
    
    if (productCount > 1) {
      // Check first product
      await products.nth(0).click();
      await page.waitForTimeout(1500); // Time to read details and price
      
      // Go back to browse more
      await page.goBack();
      await page.waitForTimeout(500);
      
      // Check second product
      if (productCount > 1) {
        await products.nth(1).click();
        await page.waitForTimeout(1500); // Compare prices
        
        // Go back to make final decision
        await page.goBack();
        await page.waitForTimeout(300);
      }
    }
    
    // Make final purchase decision (choose first product)
    await products.first().click();
    await page.waitForTimeout(800); // Final consideration
    
    // Add to cart
    await page.getByRole('button', { name: /Add to Cart/i }).click();
    
    // Go to cart and checkout
    const cartLink = page.getByRole('link', { name: /Cart/i });
    await cartLink.click();
    
    const checkoutButton = page.locator('button:has-text("Checkout"), button:has-text("Place Order"), button:has-text("Complete Order")').first();
    if (await checkoutButton.isVisible({ timeout: 2000 })) {
      await checkoutButton.click();
    }
  });

  test('malicious buyer - attempting non-existent product purchase', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    await expect(page).toHaveTitle(testConfig.getExpectedStoreFrontTitle());

    // Attempt to navigate directly to non-existent product URLs
    const nonExistentProductUrls = [
      `${testConfig.storeFrontUrl}/product/999999`,
      `${testConfig.storeFrontUrl}/product/fake-product-id`,
      `${testConfig.storeFrontUrl}/product/admin-only-item`,
    ];

    for (const url of nonExistentProductUrls) {
      console.log(`Testing non-existent product URL: ${url}`);
      
      // Try to navigate to non-existent product
      const response = await page.goto(url, { waitUntil: 'networkidle' });
      
      // Application should handle gracefully (404, redirect, or error page)
      const statusCode = response?.status();
      console.log(`Non-existent product URL returned status: ${statusCode}`);
      
      // Should not expose sensitive information
      const pageContent = await page.textContent('body');
      expect(pageContent).not.toContain('Database error');
      expect(pageContent).not.toContain('Stack trace');
      expect(pageContent).not.toContain('Internal Server Error');
      
      // Try to add non-existent product to cart (should fail gracefully)
      const addToCartButton = page.getByRole('button', { name: /Add to Cart/i });
      if (await addToCartButton.isVisible({ timeout: 1000 })) {
        await addToCartButton.click();
        
        // Check if cart was manipulated (it shouldn't be)
        const cartLink = page.getByRole('link', { name: /Cart/i });
        await cartLink.click();
        
        // Verify no phantom products were added
        const cartContent = await page.textContent('body');
        expect(cartContent).not.toContain('999999');
        expect(cartContent).not.toContain('fake-product-id');
        expect(cartContent).not.toContain('admin-only-item');
        
        // Return to homepage for next iteration
        await page.goto(testConfig.storeFrontUrl);
      }
      
      await page.waitForTimeout(500);
    }
  });
});
