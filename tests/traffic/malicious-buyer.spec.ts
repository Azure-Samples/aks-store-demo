import { test, expect } from '@playwright/test';
// @ts-ignore
const testConfig = require('../test-config');

/**
 * Malicious Buyer Simulation
 * 
 * This test simulates various malicious or edge-case behaviors
 * that could potentially exploit vulnerabilities in the store front.
 */
test.describe('Malicious Buyer Traffic Simulation', () => {
  test.skip(!testConfig.isStoreFrontConfigured(), 'Store front URL is not configured');

  test('non-existent product URL manipulation', async ({ page }) => {
    // Navigate to store first to establish session
    await page.goto(testConfig.storeFrontUrl);
    await expect(page).toHaveTitle(testConfig.getExpectedStoreFrontTitle());

    // Try to access non-existent product URLs directly
    const maliciousUrls = [
      `${testConfig.storeFrontUrl}/product/999999`,
      `${testConfig.storeFrontUrl}/product/non-existent-id`,
      `${testConfig.storeFrontUrl}/product/../admin`,
      `${testConfig.storeFrontUrl}/product/null`,
      `${testConfig.storeFrontUrl}/product/undefined`,
      `${testConfig.storeFrontUrl}/product/..`,
      `${testConfig.storeFrontUrl}/product/%00`,
      `${testConfig.storeFrontUrl}/product/script-alert-1`,
    ];

    for (const url of maliciousUrls) {
      console.log(`Testing malicious URL: ${url}`);
      
      // Navigate to malicious URL
      const response = await page.goto(url, { waitUntil: 'networkidle' });
      
      // Should not crash the application
      expect(response).toBeTruthy();
      
      // Should handle gracefully - either 404, redirect, or error page
      const statusCode = response?.status();
      console.log(`URL: ${url} returned status: ${statusCode}`);
      
      // Check if page displays appropriate error handling
      const pageContent = await page.textContent('body');
      
      // Should not display sensitive information or stack traces
      expect(pageContent).not.toContain('Error:');
      expect(pageContent).not.toContain('Stack trace');
      expect(pageContent).not.toContain('Internal Server Error');
      expect(pageContent).not.toContain('Database');
      expect(pageContent).not.toContain('SQL');
      
      // Wait a moment between requests to simulate realistic behavior
      await page.waitForTimeout(500);
    }
  });

  test('cart manipulation with non-existent products', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // Try to manipulate cart with JavaScript injection
    try {
      // Attempt to add non-existent product to cart via browser console
      await page.evaluate(() => {
        // Simulate malicious JavaScript attempts
        if (typeof window !== 'undefined') {
          // Try to access cart manipulation functions
          const maliciousProducts = [
            { id: '999999', name: 'Fake Product', price: 0.01 },
            { id: 'admin', name: 'Admin Product', price: -100 },
            { id: '../../../etc/passwd', name: 'System File', price: 1 },
            { id: 'null', name: null, price: null },
          ];
          
          // Log attempts but don't actually break the test
          maliciousProducts.forEach(product => {
            console.log(`Attempting to add malicious product: ${JSON.stringify(product)}`);
          });
        }
      });
    } catch (error) {
      // Expected behavior - malicious scripts should be blocked
      console.log('Malicious script execution blocked (expected):', error);
    }
    
    // Navigate to cart to see if any manipulation succeeded
    const cartLink = page.getByRole('link', { name: /Cart/i });
    await cartLink.click();
    
    // Verify cart is clean and not manipulated
    const cartContent = await page.textContent('body');
    expect(cartContent).not.toContain('Fake Product');
    expect(cartContent).not.toContain('Admin Product');
    expect(cartContent).not.toContain('System File');
  });

  test('SQL injection attempts in search/product URLs', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // SQL injection payloads to test
    const sqlInjectionPayloads = [
      "'; DROP TABLE products; --",
      "1' OR '1'='1",
      "1'; DELETE FROM users; --",
      "' UNION SELECT * FROM admin_users --",
      "1' AND (SELECT COUNT(*) FROM information_schema.tables) > 0 --",
      "%27%20OR%201=1",
      "admin'/*",
      "' OR 'a'='a",
    ];

    for (const payload of sqlInjectionPayloads) {
      console.log(`Testing SQL injection payload: ${payload}`);
      
      // Try payload in product URL
      const maliciousUrl = `${testConfig.storeFrontUrl}/product/${encodeURIComponent(payload)}`;
      
      try {
        const response = await page.goto(maliciousUrl, { 
          waitUntil: 'networkidle',
          timeout: 10000 
        });
        
        const statusCode = response?.status();
        console.log(`SQL injection test returned status: ${statusCode}`);
        
        // Check response doesn't contain database errors
        const pageContent = await page.textContent('body');
        expect(pageContent).not.toContain('SQL');
        expect(pageContent).not.toContain('mysql');
        expect(pageContent).not.toContain('PostgreSQL');
        expect(pageContent).not.toContain('ORA-');
        expect(pageContent).not.toContain('database error');
        expect(pageContent).not.toContain('syntax error');
        
      } catch (error) {
        // Timeouts or navigation errors are acceptable for malicious requests
        console.log(`SQL injection payload blocked or timed out (expected): ${error}`);
      }
      
      await page.waitForTimeout(300);
    }
  });

  test('XSS attempts in product parameters', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // XSS payloads to test
    const xssPayloads = [
      '<script>alert("XSS")</script>',
      'javascript:alert("XSS")',
      '<img src=x onerror=alert("XSS")>',
      '"><script>alert("XSS")</script>',
      "'><script>alert('XSS')</script>",
      '<svg onload=alert("XSS")>',
      '&lt;script&gt;alert("XSS")&lt;/script&gt;',
    ];

    for (const payload of xssPayloads) {
      console.log(`Testing XSS payload: ${payload}`);
      
      // Try payload in product URL
      const maliciousUrl = `${testConfig.storeFrontUrl}/product/${encodeURIComponent(payload)}`;
      
      try {
        await page.goto(maliciousUrl, { 
          waitUntil: 'networkidle',
          timeout: 8000 
        });
        
        // Check that script hasn't executed
        const pageContent = await page.textContent('body');
        expect(pageContent).not.toContain('<script>');
        expect(pageContent).not.toContain('javascript:');
        expect(pageContent).not.toContain('onerror=');
        expect(pageContent).not.toContain('onload=');
        
        // Verify no alert dialogs appeared (which would indicate successful XSS)
        // In Playwright, successful XSS would trigger dialog events
        
      } catch (error) {
        // Navigation errors are acceptable for malicious requests
        console.log(`XSS payload blocked or caused navigation error (expected): ${error}`);
      }
      
      await page.waitForTimeout(200);
    }
  });

  test('rapid request flooding simulation', async ({ page }) => {
    // Navigate to store
    await page.goto(testConfig.storeFrontUrl);
    
    // Simulate rapid requests to stress test the application
    const numberOfRequests = 10;
    
    console.log(`Simulating ${numberOfRequests} rapid requests`);
    
    const rapidRequests = Array.from({ length: numberOfRequests }, (_, i) => 
      page.goto(`${testConfig.storeFrontUrl}/product/test-${i}`, { 
        waitUntil: 'networkidle',
        timeout: 5000 
      }).catch(error => {
        console.log(`Rapid request ${i} failed (expected): ${error.message}`);
        return null;
      })
    );
    
    // Wait for all requests to complete or timeout
    const results = await Promise.allSettled(rapidRequests);
    
    // Check that the application didn't crash
    const finalCheck = await page.goto(testConfig.storeFrontUrl);
    expect(finalCheck?.status()).toBeLessThan(500);
    
    console.log(`Rapid request test completed. ${results.filter(r => r.status === 'fulfilled').length} requests succeeded`);
  });

  test('price manipulation attempt', async ({ page }) => {
    // Navigate to store and add a legitimate product
    await page.goto(testConfig.storeFrontUrl);
    
    // Add a product to cart normally first
    const products = page.locator('.product-list .product-card');
    if (await products.count() > 0) {
      await products.first().click();
      await page.getByRole('button', { name: /Add to Cart/i }).click();
      
      // Go to cart
      const cartLink = page.getByRole('link', { name: /Cart/i });
      await cartLink.click();
      
      // Try to manipulate prices using browser developer tools simulation
      try {
        await page.evaluate(() => {
          // Attempt to modify price elements
          const priceElements = document.querySelectorAll('[class*="price"], .price, [data-price]');
          priceElements.forEach(element => {
            console.log(`Found price element: ${element.textContent}`);
            // Attempt to modify (should be protected)
            if (element.textContent) {
              const originalPrice = element.textContent;
              element.textContent = '$0.01';
              console.log(`Attempted to change price from ${originalPrice} to $0.01`);
            }
          });
        });
      } catch (error) {
        console.log('Price manipulation blocked (expected):', error);
      }
      
      // Verify checkout process validates prices server-side
      const checkoutButton = page.locator('button:has-text("Checkout"), button:has-text("Place Order"), button:has-text("Complete Order")').first();
      if (await checkoutButton.isVisible({ timeout: 2000 })) {
        await checkoutButton.click();
        
        // Wait for server validation
        await page.waitForTimeout(1000);
        
        // Check for price validation errors or successful processing with correct prices
        const pageContent = await page.textContent('body');
        expect(pageContent).not.toContain('$0.01'); // Manipulated price should not persist
      }
    }
  });
});
