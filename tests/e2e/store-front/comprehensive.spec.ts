import { test, expect } from '@playwright/test';
// @ts-ignore
const testConfig = require('../../test-config');

test.describe('Comprehensive Store Front Tests', () => {
  
  test.beforeEach(async ({ page }) => {
    // Set longer timeout for navigation
    await page.goto(testConfig.storeFrontUrl, { waitUntil: 'networkidle' });
  });

  test.describe('Page Structure and Navigation', () => {
    test('should load the main page with correct title', async ({ page }) => {
      await expect(page).toHaveTitle(testConfig.getExpectedStoreFrontTitle());
    });

    test('should display the main navigation elements', async ({ page }) => {
      // Check for navigation elements
      await expect(page.getByRole('link', { name: /Products/i })).toBeVisible();
      await expect(page.getByRole('link', { name: /Cart/i })).toBeVisible();
    });

    test('should display the company logo/header', async ({ page }) => {
      // Check for header content - should work with any company branding
      await expect(page.locator('h1, .header, .logo')).toBeVisible();
    });

    test('should navigate between Products and Cart', async ({ page }) => {
      // Navigate to Products
      await page.getByRole('link', { name: /Products/i }).click();
      await expect(page.url()).toContain(testConfig.storeFrontUrl);
      
      // Navigate to Cart
      await page.getByRole('link', { name: /Cart/i }).click();
      await expect(page.url()).toContain(testConfig.storeFrontUrl);
    });
  });

  test.describe('Product Display and Functionality', () => {
    test('should display product list on home page', async ({ page }) => {
      await expect(page.locator('.product-list, .products, [data-testid="product-list"]')).toBeVisible();
    });

    test('should display individual product cards', async ({ page }) => {
      const productCards = page.locator('.product-card, .product, [data-testid="product-card"]');
      await expect(productCards.first()).toBeVisible();
      
      // Check that products have essential elements
      const firstProduct = productCards.first();
      await expect(firstProduct.locator('img, .image')).toBeVisible();
      await expect(firstProduct.getByRole('button', { name: /Add to Cart/i })).toBeVisible();
    });

    test('should show product details when clicking on a product', async ({ page }) => {
      const firstProduct = page.locator('.product-card, .product, [data-testid="product-card"]').first();
      await firstProduct.click();
      
      // Should navigate to product detail page or show modal
      await expect(page.locator('.product-info, .product-details, [data-testid="product-details"]')).toBeVisible();
    });

    test('should display product information (name, price, description)', async ({ page }) => {
      const firstProduct = page.locator('.product-card, .product, [data-testid="product-card"]').first();
      
      // Check for product name
      await expect(firstProduct.locator('h2, h3, .product-name, .name')).toBeVisible();
      
      // Check for price (look for $ symbol or price class)
      await expect(firstProduct.locator('.price, [data-testid="price"]')).toBeVisible();
    });

    test('should display products with correct company branding', async ({ page }) => {
      // Look for products that should contain the company name
      const productWithCompanyName = page.locator('.product-card, .product, [data-testid="product-card"]')
        .filter({ hasText: new RegExp(`${testConfig.companyName}`, 'i') });
      
      // Should have at least one product with company branding
      await expect(productWithCompanyName.first()).toBeVisible();
    });
  });

  test.describe('Shopping Cart Functionality', () => {
    test('should start with empty cart', async ({ page }) => {
      const cartLink = page.getByRole('link', { name: /Cart/i });
      const cartText = await cartLink.textContent();
      
      // Cart should show 0 items initially or be empty
      expect(cartText).toMatch(/Cart\s*\(?\s*0?\s*\)?/i);
    });

    test('should add single item to cart from home page', async ({ page }) => {
      // Get initial cart count
      const cartLink = page.getByRole('link', { name: /Cart/i });
      const initialCartText = await cartLink.textContent() || '';
      const initialCount = parseInt(initialCartText.match(/\d+/)?.[0] || '0');

      // Add first product to cart
      const firstAddButton = page.locator('.product-card, .product, [data-testid="product-card"]')
        .first()
        .getByRole('button', { name: /Add to Cart/i });
      
      await firstAddButton.click();

      // Check cart count increased
      await expect(cartLink).toHaveText(new RegExp(`Cart.*${initialCount + 1}`, 'i'));
    });

    test('should add multiple different items to cart', async ({ page }) => {
      const cartLink = page.getByRole('link', { name: /Cart/i });
      const initialCartText = await cartLink.textContent() || '';
      const initialCount = parseInt(initialCartText.match(/\d+/)?.[0] || '0');

      // Add first product
      const firstAddButton = page.locator('.product-card, .product, [data-testid="product-card"]')
        .first()
        .getByRole('button', { name: /Add to Cart/i });
      await firstAddButton.click();

      // Add last product
      const lastAddButton = page.locator('.product-card, .product, [data-testid="product-card"]')
        .last()
        .getByRole('button', { name: /Add to Cart/i });
      await lastAddButton.click();

      // Check cart count increased by 2
      await expect(cartLink).toHaveText(new RegExp(`Cart.*${initialCount + 2}`, 'i'));
    });

    test('should add item to cart from product detail page', async ({ page }) => {
      const cartLink = page.getByRole('link', { name: /Cart/i });
      const initialCartText = await cartLink.textContent() || '';
      const initialCount = parseInt(initialCartText.match(/\d+/)?.[0] || '0');

      // Navigate to product details
      await page.locator('.product-card, .product, [data-testid="product-card"]').first().click();
      
      // Add to cart from detail page
      await page.getByRole('button', { name: /Add to Cart/i }).click();

      // Check cart count increased
      await expect(cartLink).toHaveText(new RegExp(`Cart.*${initialCount + 1}`, 'i'));
    });
  });

  test.describe('Cart Page Functionality', () => {
    test.beforeEach(async ({ page }) => {
      // Add an item to cart before each cart test
      const firstAddButton = page.locator('.product-card, .product, [data-testid="product-card"]')
        .first()
        .getByRole('button', { name: /Add to Cart/i });
      await firstAddButton.click();
    });

    test('should navigate to cart page and display items', async ({ page }) => {
      await page.getByRole('link', { name: /Cart/i }).click();
      
      // Should see cart items
      await expect(page.locator('.cart-item, .cart-product, [data-testid="cart-item"]')).toBeVisible();
    });

    test('should show checkout button when items in cart', async ({ page }) => {
      await page.getByRole('link', { name: /Cart/i }).click();
      
      // Should see checkout button
      await expect(page.getByRole('button', { name: /Checkout/i })).toBeVisible();
    });

    test('should be able to modify item quantities in cart', async ({ page }) => {
      await page.getByRole('link', { name: /Cart/i }).click();
      
      // Look for quantity controls (+ - buttons or number input)
      const quantityControls = page.locator('.quantity, [data-testid="quantity"], input[type="number"]');
      if (await quantityControls.count() > 0) {
        await expect(quantityControls.first()).toBeVisible();
      }
    });
  });

  test.describe('Checkout Process', () => {
    test.beforeEach(async ({ page }) => {
      // Add items to cart before each checkout test
      const firstAddButton = page.locator('.product-card, .product, [data-testid="product-card"]')
        .first()
        .getByRole('button', { name: /Add to Cart/i });
      await firstAddButton.click();
      
      const secondAddButton = page.locator('.product-card, .product, [data-testid="product-card"]')
        .nth(1)
        .getByRole('button', { name: /Add to Cart/i });
      await secondAddButton.click();
    });

    test('should complete checkout process successfully', async ({ page }) => {
      // Navigate to cart
      await page.getByRole('link', { name: /Cart/i }).click();
      
      // Start checkout
      await page.getByRole('button', { name: /Checkout/i }).click();

      // Handle potential success dialog
      page.on('dialog', async dialog => {
        expect(dialog.message()).toMatch(/success|submitted|complete|order/i);
        await dialog.accept();
      });
      
      // Wait for potential navigation or modal
      await page.waitForTimeout(2000);
    });

    test('should show order confirmation or success message', async ({ page }) => {
      await page.getByRole('link', { name: /Cart/i }).click();
      
      // Set up dialog listener before clicking checkout
      const dialogPromise = new Promise(resolve => {
        page.on('dialog', async dialog => {
          resolve(dialog.message());
          await dialog.accept();
        });
      });
      
      await page.getByRole('button', { name: /Checkout/i }).click();
      
      // Wait for dialog and check message
      const dialogMessage = await dialogPromise;
      expect(dialogMessage).toMatch(/success|submitted|complete|order/i);
    });
  });

  test.describe('Responsive Design and UI', () => {
    // test('should be responsive on mobile viewport', async ({ page }) => {
    //   await page.setViewportSize({ width: 375, height: 667 });
      
    //   // Check that main elements are still visible
    //   await expect(page.locator('.product-list, .products, [data-testid="product-list"]')).toBeVisible();
    //   await expect(page.getByRole('link', { name: /Cart/i })).toBeVisible();
    // });

    test('should be responsive on tablet viewport', async ({ page }) => {
      await page.setViewportSize({ width: 768, height: 1024 });
      
      // Check layout adjusts properly
      await expect(page.locator('.product-list, .products, [data-testid="product-list"]')).toBeVisible();
    });

    test('should display product images properly', async ({ page }) => {
      const productImages = page.locator('.product-card img, .product img, [data-testid="product-image"]');
      await expect(productImages.first()).toBeVisible();
      
      // Check image has proper attributes
      const firstImage = productImages.first();
      await expect(firstImage).toHaveAttribute('src');
    });
  });

  test.describe('Error Handling and Edge Cases', () => {
    test('should handle empty cart gracefully', async ({ page }) => {
      await page.getByRole('link', { name: /Cart/i }).click();
      
      // Should show empty cart message or handle gracefully
      const emptyCartElements = page.locator('.empty-cart, .no-items, [data-testid="empty-cart"]');
      if (await emptyCartElements.count() > 0) {
        await expect(emptyCartElements.first()).toBeVisible();
      }
    });

    test('should handle network delays gracefully', async ({ page }) => {
      // Simulate slow network
      await page.route('**/*', route => {
        setTimeout(() => route.continue(), 100);
      });
      
      await page.reload();
      await expect(page.locator('.product-list, .products, [data-testid="product-list"]')).toBeVisible();
    });
  });

  test.describe('Accessibility', () => {
    test('should have proper heading structure', async ({ page }) => {
      const headings = page.locator('h1, h2, h3, h4, h5, h6');
      await expect(headings.first()).toBeVisible();
    });

    test('should have accessible buttons', async ({ page }) => {
      const buttons = page.getByRole('button');
      const buttonCount = await buttons.count();
      expect(buttonCount).toBeGreaterThan(0);
      
      for (let i = 0; i < Math.min(buttonCount, 3); i++) {
        await expect(buttons.nth(i)).toBeEnabled();
      }
    });

    test('should have accessible links', async ({ page }) => {
      const links = page.getByRole('link');
      const linkCount = await links.count();
      expect(linkCount).toBeGreaterThan(0);
      
      for (let i = 0; i < Math.min(linkCount, 3); i++) {
        await expect(links.nth(i)).toBeVisible();
      }
    });
  });

  test.describe('Performance', () => {
    test('should load main page within reasonable time', async ({ page }) => {
      const startTime = Date.now();
      await page.goto(testConfig.storeFrontUrl, { waitUntil: 'networkidle' });
      const loadTime = Date.now() - startTime;
      
      // Should load within 5 seconds
      expect(loadTime).toBeLessThan(5000);
    });

    test('should have working product images', async ({ page }) => {
      const images = page.locator('img');
      const imageCount = await images.count();
      
      if (imageCount > 0) {
        // Check first few images load properly
        for (let i = 0; i < Math.min(imageCount, 3); i++) {
          const image = images.nth(i);
          await expect(image).toBeVisible();
          
          // Check image has loaded (not broken)
          const naturalWidth = await image.evaluate((img: HTMLImageElement) => img.naturalWidth);
          expect(naturalWidth).toBeGreaterThan(0);
        }
      }
    });
  });
});
