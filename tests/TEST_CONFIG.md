# Test Configuration

This document describes the shared test configuration system used across all Playwright tests in this project.

## Overview

The `test-config.js` file provides a centralized way to manage environment variables and common test settings used across all test suites. This eliminates duplication and makes it easier to maintain consistent configuration.

## Configuration File

### Location
- **Main config:** `/tests/test-config.js`
- **Type definitions:** `/tests/e2e/test-config.d.ts`

### Available Properties

```javascript
const testConfig = {
  // Store URLs
  storeAdminUrl: string,     // SERVICE_STORE_ADMIN_ENDPOINT_URL or 'http://'
  storeFrontUrl: string,     // SERVICE_STORE_FRONT_ENDPOINT_URL or 'http://'
  
  // Company branding
  companyName: string,       // COMPANY_NAME or 'Contoso'
  
  // Helper methods
  isStoreAdminConfigured(): boolean,
  isStoreFrontConfigured(): boolean,
  getExpectedAdminTitle(): RegExp,
  getExpectedStoreFrontTitle(): RegExp
}
```

## Usage in Tests

### Import the Configuration

```typescript
import { test, expect } from '@playwright/test';

// For e2e tests (in subdirectories)
// @ts-ignore
const testConfig = require('../../test-config');

// For traffic tests (in direct subdirectory)
// @ts-ignore
const testConfig = require('../test-config');
```

### Using Configuration Values

```typescript
// Navigate to store admin
await page.goto(testConfig.storeAdminUrl);

// Check title with helper method
await expect(page).toHaveTitle(testConfig.getExpectedAdminTitle());

// Skip tests if environment not configured
test.skip(!testConfig.isStoreAdminConfigured(), 'Store admin URL not set');
```

### Before (Old Pattern)
```typescript
const STORE_ADMIN_URL = process.env.SERVICE_STORE_ADMIN_ENDPOINT_URL || 'http://';
const STORE_COMPANY_NAME = process.env.COMPANY_NAME || 'Contoso';

test.skip(STORE_ADMIN_URL === 'http://', 'STORE_ADMIN_URL is not set');
await page.goto(STORE_ADMIN_URL);
await expect(page).toHaveTitle(new RegExp(`${STORE_COMPANY_NAME} Pet Store Admin Portal`));
```

### After (New Pattern)
```typescript
// @ts-ignore
const testConfig = require('../../test-config');

test.skip(!testConfig.isStoreAdminConfigured(), 'Store admin URL not set');
await page.goto(testConfig.storeAdminUrl);
await expect(page).toHaveTitle(testConfig.getExpectedAdminTitle());
```

## Environment Variable Sources

The configuration automatically loads environment variables from multiple sources in this priority order:

1. **Azure Developer CLI (azd)** - Highest priority
2. **Local .env file** - Lower priority
3. **Default values** - Fallback

This is handled by the existing `load-env.js` module which the test configuration uses internally.

## Helper Methods

### Configuration Checks
- `isStoreAdminConfigured()` - Returns `true` if store admin URL is properly set
- `isStoreFrontConfigured()` - Returns `true` if store front URL is properly set

### Title Expectations
- `getExpectedAdminTitle()` - Returns RegExp for store admin page title
- `getExpectedStoreFrontTitle()` - Returns RegExp for store front page title

## Benefits

1. **Centralized Configuration** - All environment variables in one place
2. **Consistent Defaults** - Same fallback values across all tests
3. **Type Safety** - TypeScript definitions for better IntelliSense
4. **Helper Methods** - Reusable patterns for common checks
5. **Maintainability** - Easy to update configuration for all tests
6. **Environment Integration** - Seamless integration with existing azd and .env patterns

## Migration

All test files use the centralized configuration system:

### E2E Tests
- `/tests/e2e/store-admin/basic.spec.ts`
- `/tests/e2e/store-admin/comprehensive.spec.ts`
- `/tests/e2e/store-front/basic.spec.ts`
- `/tests/e2e/store-front/comprehensive.spec.ts`

### Traffic Simulation Tests
- `/tests/traffic/single-item-buyer.spec.ts`
- `/tests/traffic/casual-browser.spec.ts`
- `/tests/traffic/malicious-buyer.spec.ts`

All tests consistently use:
```typescript
// @ts-ignore
const testConfig = require('../test-config');
```
