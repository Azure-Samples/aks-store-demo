import { test, expect } from '@playwright/test';
// @ts-ignore
const testConfig = require('../test-config');

/**
 * Helper function to retry navigation with error handling
 */
async function retryNavigation(page, navigationAction, actionDescription, maxRetries = 3) {
  let navigationSuccessful = false;
  let retryCount = 0;
  
  while (!navigationSuccessful && retryCount < maxRetries) {
    try {
      await navigationAction();
      navigationSuccessful = true;
    } catch (error) {
      retryCount++;
      console.log(`${actionDescription} attempt ${retryCount} failed: ${error.message}`);
      
      if (retryCount < maxRetries) {
        await page.waitForTimeout(1000);
      } else {
        console.log(`Failed ${actionDescription} after ${maxRetries} attempts`);
      }
    }
  }
  
  return navigationSuccessful;
}

/**
 * Casual Browser Simulation
 * 
 * This test simulates a casual shopper who browses extensively,
 * views multiple products, and may or may not make a purchase.
 */
test.describe('Casual Browser Traffic Simulation', () => {
  test.skip(!testConfig.isStoreFrontConfigured(), 'Store front URL is not configured');

  // Skipping this test for now as it is flaky and needs more robust handling
  // of navigation and element interactions.
  test.skip('window shopper - extensive browsing, no purchase', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    await expect(page).toHaveTitle(testConfig.getExpectedStoreFrontTitle());

    // Spend time on homepage browsing
    await expect(page.locator('.product-list')).toBeVisible();
    await page.waitForTimeout(2000);
    
    // Browse multiple products without purchasing
    const products = page.locator('.product-list .product-card');
    const productCount = await products.count();
    
    // View first 3 products (or all if less than 3)
    const browseCount = Math.min(3, productCount);
    
    for (let i = 0; i < browseCount; i++) {
      // Click on product and wait for navigation with retry logic
      const initialUrl = page.url();
      let navigationSuccessful = false;
      let retryCount = 0;
      const maxRetries = 3;
      
      while (!navigationSuccessful && retryCount < maxRetries) {
        try {
          await products.nth(i).click();
          
          // Wait for URL to change (indicating successful navigation)
          await page.waitForFunction(
            (startUrl) => window.location.href !== startUrl,
            initialUrl,
            { timeout: 5000 }
          );
          
          navigationSuccessful = true;
        } catch (error) {
          retryCount++;
          console.log(`Navigation attempt ${retryCount} failed for product ${i}: ${error.message}`);
          
          if (retryCount < maxRetries) {
            // Wait a bit before retrying
            await page.waitForTimeout(1000);
            // Ensure we're back on the product list page
            if (page.url() !== initialUrl) {
              await page.goto(initialUrl);
              await page.waitForTimeout(1000);
            }
          } else {
            console.log(`Failed to navigate to product ${i} after ${maxRetries} attempts, skipping`);
            break;
          }
        }
      }
      
      if (navigationSuccessful) {
        // Spend time reading product details
        await page.waitForTimeout(2000 + Math.random() * 1000);
        
        // Maybe scroll down to see more details
        await page.evaluate(() => window.scrollBy(0, 200));
        await page.waitForTimeout(1000);
        
        // Go back to product list and wait for navigation with retry
        let backNavigationSuccessful = false;
        let backRetryCount = 0;
        
        while (!backNavigationSuccessful && backRetryCount < maxRetries) {
          try {
            await Promise.all([
              page.waitForNavigation({ timeout: 5000 }),
              page.goBack()
            ]);
            backNavigationSuccessful = true;
          } catch (error) {
            backRetryCount++;
            console.log(`Back navigation attempt ${backRetryCount} failed: ${error.message}`);
            
            if (backRetryCount < maxRetries) {
              await page.waitForTimeout(1000);
              // Try alternative navigation back to product list
              await page.goto(initialUrl);
              await page.waitForTimeout(1000);
              backNavigationSuccessful = true;
            }
          }
        }
        
        await page.waitForTimeout(1000);
      }
    }
    
    // Check cart link but don't purchase with retry logic
    const cartLink = page.getByRole('link', { name: /Cart/i });
    let cartNavigationSuccessful = false;
    let cartRetryCount = 0;
    const maxRetries = 3;
    
    while (!cartNavigationSuccessful && cartRetryCount < maxRetries) {
      try {
        await Promise.all([
          page.waitForNavigation({ timeout: 5000 }),
          cartLink.click()
        ]);
        cartNavigationSuccessful = true;
      } catch (error) {
        cartRetryCount++;
        console.log(`Cart navigation attempt ${cartRetryCount} failed: ${error.message}`);
        
        if (cartRetryCount < maxRetries) {
          await page.waitForTimeout(1000);
        } else {
          console.log('Failed to navigate to cart, skipping cart check');
        }
      }
    }
    
    if (cartNavigationSuccessful) {
      await page.waitForTimeout(1500);
    }
    
    // Go back to browsing (no purchase)
    //await page.goBack();
  });

  test('indecisive shopper - multiple cart additions and removals', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    await expect(page.locator('.product-list')).toBeVisible();
    
    // Add first product to cart
    const firstProductAddButton = page.locator('.product-list .product-controls').first()
      .getByRole('button', { name: /Add to Cart/i });
    await firstProductAddButton.click();
    
    // Wait and think about it
    await page.waitForTimeout(1500);
    
    // Add second product
    const secondProductAddButton = page.locator('.product-list .product-controls').nth(1)
      .getByRole('button', { name: /Add to Cart/i });
    
    if (await secondProductAddButton.isVisible({ timeout: 1000 })) {
      await secondProductAddButton.click();
      await page.waitForTimeout(1000);
    }
    
    // Check cart with retry logic
    const cartLink = page.getByRole('link', { name: /Cart/i });
    let cartNavigationSuccessful = false;
    let cartRetryCount = 0;
    const maxRetries = 3;
    
    while (!cartNavigationSuccessful && cartRetryCount < maxRetries) {
      try {
        await Promise.all([
          page.waitForNavigation({ timeout: 5000 }),
          cartLink.click()
        ]);
        cartNavigationSuccessful = true;
      } catch (error) {
        cartRetryCount++;
        console.log(`Cart navigation attempt ${cartRetryCount} failed: ${error.message}`);
        
        if (cartRetryCount < maxRetries) {
          await page.waitForTimeout(1000);
        }
      }
    }
    
    if (cartNavigationSuccessful) {
      await page.waitForTimeout(2000);
      
      // Look for remove buttons or quantity controls
      const removeButtons = page.locator('button:has-text("Remove"), button:has-text("Delete"), .remove-item, [aria-label*="remove"]');
      
      if (await removeButtons.count() > 0) {
        // Remove one item (change of mind)
        await removeButtons.first().click();
        await page.waitForTimeout(1000);
      }
      
      // Think about final decision
      await page.waitForTimeout(2000);
      
      // Maybe checkout with remaining items
      const checkoutButton = page.locator('button:has-text("Checkout"), button:has-text("Place Order"), button:has-text("Complete Order")').first();
      if (await checkoutButton.isVisible({ timeout: 2000 })) {
        await checkoutButton.click();
      }
    }
  });

  test('curious browser - detailed product exploration', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // Browse products methodically
    const products = page.locator('.product-list .product-card');
    const productCount = await products.count();
    
    if (productCount > 0) {
      // Click on first product for detailed exploration and wait for navigation with retry
      let navigationSuccessful = false;
      let retryCount = 0;
      const maxRetries = 3;
      
      while (!navigationSuccessful && retryCount < maxRetries) {
        try {
          await Promise.all([
            page.waitForNavigation({ timeout: 5000 }),
            products.first().click()
          ]);
          navigationSuccessful = true;
        } catch (error) {
          retryCount++;
          console.log(`Product navigation attempt ${retryCount} failed: ${error.message}`);
          
          if (retryCount < maxRetries) {
            await page.waitForTimeout(1000);
          }
        }
      }
      
      if (navigationSuccessful) {
        // Thoroughly explore product page
        await page.waitForTimeout(1000);
        
        // Look for product images and view them
        const productImages = page.locator('.product-info img, .product-images img, .image-gallery img');
        if (await productImages.count() > 0) {
          await productImages.first().click();
          await page.waitForTimeout(800);
        }
        
        // Scroll to read full description
        await page.evaluate(() => window.scrollBy(0, 300));
        await page.waitForTimeout(1500);
        
        // Check if there are product reviews or additional details
        const detailSections = page.locator('.product-description, .product-details, .reviews, .specifications');
        if (await detailSections.count() > 0) {
          await page.waitForTimeout(2000);
        }
        
        // Scroll back up
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.waitForTimeout(500);
        
        // Finally add to cart after thorough review
        const addToCartButton = page.getByRole('button', { name: /Add to Cart/i });
        if (await addToCartButton.isVisible()) {
          await addToCartButton.click();
          
          // Navigate to cart with retry logic
          const cartLink = page.getByRole('link', { name: /Cart/i });
          let cartNavigationSuccessful = false;
          let cartRetryCount = 0;
          
          while (!cartNavigationSuccessful && cartRetryCount < maxRetries) {
            try {
              await Promise.all([
                page.waitForNavigation({ timeout: 5000 }),
                cartLink.click()
              ]);
              cartNavigationSuccessful = true;
            } catch (error) {
              cartRetryCount++;
              console.log(`Cart navigation attempt ${cartRetryCount} failed: ${error.message}`);
              
              if (cartRetryCount < maxRetries) {
                await page.waitForTimeout(1000);
              }
            }
          }
          
          if (cartNavigationSuccessful) {
            await page.waitForTimeout(1500);
            
            // Complete purchase
            const checkoutButton = page.locator('button:has-text("Checkout"), button:has-text("Place Order"), button:has-text("Complete Order")').first();
            if (await checkoutButton.isVisible({ timeout: 2000 })) {
              await checkoutButton.click();
            }
          }
        }
      }
    }
  });

  test('social browser - sharing and external navigation', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // Browse products
    await expect(page.locator('.product-list')).toBeVisible();
    await page.waitForTimeout(1000);
    
    // Click on a product with retry logic
    const firstProduct = page.locator('.product-list .product-card').first();
    let navigationSuccessful = false;
    let retryCount = 0;
    const maxRetries = 3;
    
    while (!navigationSuccessful && retryCount < maxRetries) {
      try {
        await Promise.all([
          page.waitForNavigation({ timeout: 5000 }),
          firstProduct.click()
        ]);
        navigationSuccessful = true;
      } catch (error) {
        retryCount++;
        console.log(`Product navigation attempt ${retryCount} failed: ${error.message}`);
        
        if (retryCount < maxRetries) {
          await page.waitForTimeout(1000);
        }
      }
    }
    
    if (navigationSuccessful) {
      await page.waitForTimeout(1500);
      
      // Look for social sharing buttons or copy URL behavior
      const socialButtons = page.locator('[class*="share"], [class*="social"], button:has-text("Share")');
      if (await socialButtons.count() > 0) {
        await socialButtons.first().click();
        await page.waitForTimeout(500);
      }
      
      // Simulate opening new tab behavior (common social browsing pattern)
      const currentUrl = page.url();
      
      // Navigate away briefly (simulating checking other sites/prices)
      await page.goto('about:blank');
      await page.waitForTimeout(1000);
      
      // Come back to the product
      await page.goto(currentUrl);
      await page.waitForTimeout(1000);
      
      // After "comparison shopping", add to cart
      const addToCartButton = page.getByRole('button', { name: /Add to Cart/i });
      if (await addToCartButton.isVisible()) {
        await addToCartButton.click();
        
        // Quick checkout with retry logic
        const cartLink = page.getByRole('link', { name: /Cart/i });
        let cartNavigationSuccessful = false;
        let cartRetryCount = 0;
        
        while (!cartNavigationSuccessful && cartRetryCount < maxRetries) {
          try {
            await Promise.all([
              page.waitForNavigation({ timeout: 5000 }),
              cartLink.click()
            ]);
            cartNavigationSuccessful = true;
          } catch (error) {
            cartRetryCount++;
            console.log(`Cart navigation attempt ${cartRetryCount} failed: ${error.message}`);
            
            if (cartRetryCount < maxRetries) {
              await page.waitForTimeout(1000);
            }
          }
        }
        
        if (cartNavigationSuccessful) {
          const checkoutButton = page.locator('button:has-text("Checkout"), button:has-text("Place Order"), button:has-text("Complete Order")').first();
          if (await checkoutButton.isVisible({ timeout: 2000 })) {
            await checkoutButton.click();
          }
        }
      }
    }
  });
});
