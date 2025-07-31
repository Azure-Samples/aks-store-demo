# AKS Store Demo E2E Tests

This directory contains comprehensive Playwright end-to-end tests for the AKS Store Demo applications, including both the store front and store admin portals.

## Test Structure

The test suite is organized into three main categories: functional tests, comprehensive end-to-end scenarios, and traffic simulation tests:

```
tests/
├── e2e/                        # Functional End-to-End Tests
│   ├── store-front/
│   │   ├── basic.spec.ts           # Quick validation tests
│   │   └── comprehensive.spec.ts   # Full e2e scenarios
│   └── store-admin/
│       ├── basic.spec.ts           # Quick validation tests
│       └── comprehensive.spec.ts   # Full e2e scenarios
├── traffic/                    # Traffic Simulation Tests
│   ├── single-item-buyer.spec.ts  # Focused purchase patterns
│   ├── casual-browser.spec.ts     # Browsing behavior simulation
│   └── malicious-buyer.spec.ts    # Security testing scenarios
└── test-config.js             # Shared configuration
```

### Test Categories

#### 🚀 **Basic Tests** - Quick Validation
- **Purpose**: Fast, essential functionality checks for CI/CD pipelines
- **Execution Time**: ~30 seconds per application
- **Coverage**: Page loading, navigation, branding, core functionality

#### 🔬 **Comprehensive Tests** - Complete Workflows
- **Purpose**: Full end-to-end scenarios and edge cases
- **Execution Time**: 2-5 minutes per application
- **Coverage**: Complex workflows, AI integration, error handling, responsive design

#### 🚦 **Traffic Simulation Tests** - User Behavior Patterns
- **Purpose**: Realistic user interaction simulation and security testing
- **Execution Time**: 1-3 minutes per scenario
- **Coverage**: Customer journey patterns, load testing, security validation

## Available npm Scripts

### Store Front Tests
```bash
npm run test:store-front                   # Run all store front tests
npm run test:store-front:basic            # Run basic store front tests
npm run test:store-front:comprehensive    # Run comprehensive store front tests
npm run test:store-front:headed           # Run store front tests with visible browser
```

### Store Admin Tests
```bash
npm run test:store-admin                    # Run all store admin tests
npm run test:store-admin:basic             # Run basic store admin tests
npm run test:store-admin:comprehensive     # Run comprehensive store admin tests
npm run test:store-admin:headed            # Run store admin tests with visible browser
```

### General Test Commands
```bash
npm run test                              # Run all tests (e2e + traffic)
npm run test:headed                       # Run all tests with visible browser
npm run test:debug                        # Debug mode with step-by-step execution
npm run test:ui                          # Interactive UI for test development
npm run report                           # Show detailed test report
```

### E2E Test Commands
```bash
npm run test:e2e                         # Run all e2e tests only
```

### Traffic Simulation Commands
```bash
npm run test:traffic                      # Run all traffic simulation tests
npm run test:traffic:single-buyer        # Single item buyer patterns
npm run test:traffic:casual-browser      # Casual browsing patterns
npm run test:traffic:malicious           # Security testing scenarios
npm run test:traffic:headed              # Traffic tests with visible browser
```

## Test Coverage

### 🛒 **Store Front Tests**

#### Basic Tests
- Page loading and title verification with dynamic company name
- Navigation between Products and Cart pages
- Basic product display functionality
- Cart functionality (add items, view cart)
- Company branding validation

#### Comprehensive Tests
- Complete shopping workflow (browse → select → add to cart → checkout)
- Product detail page navigation and functionality
- Cart management (add, remove, update quantities)
- Checkout process with order confirmation
- Responsive design testing (mobile, tablet, desktop)
- Error handling and edge cases
- Performance validation
- Accessibility compliance

### 🚦 **Traffic Simulation Tests**

#### Single Item Buyer Tests
- Focused customers who make quick, targeted purchases
- Impulse buyers with rapid decision-making
- Price-conscious comparison shopping
- Direct product navigation and checkout

#### Casual Browser Tests
- Extensive browsing without immediate purchase intent
- Window shoppers exploring multiple products
- Indecisive shoppers with cart modifications
- Detailed product exploration patterns
- Social browsing with sharing behaviors

#### Malicious Buyer Tests (Security Testing)
- URL manipulation and non-existent product access
- SQL injection prevention validation
- XSS (Cross-Site Scripting) attack prevention
- Price manipulation attempt detection
- Rapid request flooding simulation
- Input sanitization verification

### 🛠️ **Store Admin Tests**

#### Basic Tests
- Admin portal page loading and title verification
- Navigation to Products management page
- Basic page rendering verification
- Company branding consistency
- Main navigation elements
- Orders page navigation (if available)

#### Comprehensive Tests
- Complete product creation workflow
- AI Assistant integration for product descriptions
- Form validation testing
- Product list management and viewing
- Product detail views and editing
- Order management workflows
- Responsive design testing across viewports
- Error handling scenarios
- Extended timeout operations for AI services

## Shared Configuration System

The test suite uses a centralized configuration system through `test-config.js` that eliminates duplication and provides consistent settings across all test suites.

### Configuration Benefits
- **Centralized Environment Variables**: Single source for all environment settings
- **Consistent Defaults**: Same fallback values across all tests
- **Helper Methods**: Reusable patterns for common checks and expectations
- **Type Safety**: TypeScript definitions for better development experience

### Usage in Tests
```typescript
// @ts-ignore
const testConfig = require('../test-config');

// Skip tests if environment not configured
test.skip(!testConfig.isStoreFrontConfigured(), 'Store front URL not configured');

// Use standardized URLs and settings
await page.goto(testConfig.storeFrontUrl);
await expect(page).toHaveTitle(testConfig.getExpectedStoreFrontTitle());
```

See `TEST_CONFIG.md` for complete configuration documentation.

## Environment Variables

The tests support dynamic configuration through environment variables:

### Required Variables
- **`SERVICE_STORE_FRONT_ENDPOINT_URL`**: Store front application URL
- **`SERVICE_STORE_ADMIN_ENDPOINT_URL`**: Store admin application URL

### Optional Variables
- **`COMPANY_NAME`**: Company name for branding tests (default: "Contoso")

### Example Configuration
```bash
# Set environment variables
export SERVICE_STORE_FRONT_ENDPOINT_URL=http://localhost:3000
export SERVICE_STORE_ADMIN_ENDPOINT_URL=http://localhost:3001
export COMPANY_NAME=Zava

# Run tests with custom configuration
npm run test
```

### Azure Developer CLI (azd) Integration
The tests automatically load environment variables from azd:
```bash
# Load azd environment and run tests
azd env get-values > .env
npm run test
```

## Quick Start

### Prerequisites
```bash
# Install dependencies
npm install

# Install Playwright browsers
npx playwright install
```

### Development Workflow
```bash
# Quick validation during development
npm run test:store-front:basic
npm run test:store-admin:basic

# Full functional testing before deployment
npm run test:store-front:comprehensive
npm run test:store-admin:comprehensive

# Traffic simulation and security testing
npm run test:traffic
```

### CI/CD Pipeline Example
```bash
# Stage 1: Quick validation
npm run test:store-front:basic && npm run test:store-admin:basic

# Stage 2: Full coverage (can run in parallel)
npm run test:store-front:comprehensive &
npm run test:store-admin:comprehensive &
npm run test:traffic &
wait
```

### Zava Branding Test Script
For complete validation with Zava branding:
```bash
# Run comprehensive test suite with Zava branding
./test-zava-branding.sh
```

## Test Features

### ✅ **Dynamic Company Name Support**
All tests support configurable company names for brand-agnostic testing:
```typescript
// Centralized through test-config.js
const testConfig = require('../test-config');
console.log(testConfig.companyName); // From COMPANY_NAME env var or 'Contoso'
```

### ✅ **Automatic Environment Detection**
Tests automatically skip if required URLs are not configured:
```typescript
// Centralized helper methods
test.skip(!testConfig.isStoreFrontConfigured(), 'Store front URL not configured');
test.skip(!testConfig.isStoreAdminConfigured(), 'Store admin URL not configured');
```

### ✅ **Traffic Simulation and Security Testing**
Comprehensive traffic tests simulate real user behavior patterns:
- Realistic timing delays and interaction patterns
- Security vulnerability testing with malicious inputs
- Load testing through various user journey scenarios
- Resilience testing with edge cases and error conditions

### ✅ **AI Service Integration Testing**
Comprehensive tests include AI Assistant functionality with graceful fallback:
- Tests AI-powered product description generation
- Handles AI service unavailability
- Extended timeouts for AI operations (up to 120 seconds)

### ✅ **Responsive Design Validation**
Tests verify applications work across different screen sizes:
- Mobile viewport (375×667)
- Tablet viewport (768×1024)
- Desktop viewport (1920×1080)

### ✅ **Error Handling and Edge Cases**
- Network error scenarios
- Form validation testing
- Non-existent resource handling
- Service unavailability graceful degradation

## Debug and Development

### Interactive Testing
```bash
# Run tests with visible browser
npm run test:headed

# Debug specific test with breakpoints
npm run test:debug

# Interactive test development UI
npm run test:ui
```

### Debugging Specific Tests
```bash
# Debug store front basic tests
npx playwright test store-front/basic.spec.ts --debug

# Debug store admin comprehensive tests  
npx playwright test store-admin/comprehensive.spec.ts --headed

# Debug traffic simulation tests
npx playwright test traffic/casual-browser.spec.ts --debug

# Run single test with verbose output
npx playwright test store-front/basic.spec.ts --reporter=list
```

### View Test Results
```bash
# Show detailed HTML report
npm run report

# View test artifacts (screenshots, videos, traces)
npx playwright show-report
```

## Test Timeouts

### Basic Tests
- **Default**: 30 seconds per test
- **Purpose**: Fast feedback for development and CI/CD

### Comprehensive Tests
- **Product Creation**: 90 seconds (includes AI processing)
- **AI Integration**: 120 seconds (extended for AI service calls)
- **Standard Operations**: 30 seconds
- **Purpose**: Thorough testing of complex workflows

## Configuration Files

### `test-config.js`
Centralized configuration providing:
- Environment variable management with intelligent defaults
- Helper methods for common test patterns and validations
- Consistent URL and branding configuration across all test suites
- Integration with existing azd and .env file patterns

### `playwright.config.ts`
Main Playwright configuration with:
- Browser settings (Chromium, Firefox, WebKit)
- Test timeouts and retries
- Report generation settings
- Environment variable loading via test-config.js

### `playwright.service.config.ts`
Microsoft Playwright Testing service integration for cloud testing.

### `TEST_CONFIG.md`
Complete documentation of the shared configuration system with usage examples and migration patterns.

## Best Practices

### 1. **Selector Strategy**
Tests use multiple selector strategies for resilience:
```typescript
// Multiple fallback selectors
page.locator('.product-list, .products, [data-testid="product-list"]')
```

### 2. **Environment Flexibility**
Tests adapt to different deployment configurations:
```typescript
// Centralized configuration with helper methods
const testConfig = require('../test-config');
test.skip(!testConfig.isStoreFrontConfigured(), 'Store front not configured');
await page.goto(testConfig.storeFrontUrl);
```

### 3. **Graceful Degradation**
Tests handle missing features gracefully:
```typescript
// Optional feature testing
const aiButton = page.locator('button:has-text("Ask AI Assistant")');
if (await aiButton.isVisible()) {
  // Test AI functionality
} else {
  // Fallback to manual input
}
```

### 4. **Clear Test Organization**
Tests are grouped logically with descriptive names:
```typescript
test.describe('Product Management', () => {
  test('can create new product with AI assistance', async ({ page }) => {
    // Test implementation
  });
});

test.describe('Traffic Simulation - Casual Browser', () => {
  test('window shopper - extensive browsing, no purchase', async ({ page }) => {
    // Realistic browsing behavior simulation
  });
});
```

### 5. **Security Testing Integration**
Malicious buyer tests validate application security:
```typescript
test.describe('Security Validation', () => {
  test('handles SQL injection attempts gracefully', async ({ page }) => {
    // Security vulnerability testing
  });
});
```

## Troubleshooting

### Common Issues

#### Tests Skipping Due to Missing URLs
```bash
# Verify environment variables are set
echo $SERVICE_STORE_FRONT_ENDPOINT_URL
echo $SERVICE_STORE_ADMIN_ENDPOINT_URL

# Check configuration through test-config
node -e "console.log(require('./test-config.js'))"

# Load from azd if using Azure deployment
azd env get-values
```

#### Traffic Test Specific Issues
1. **Security tests failing**: This may indicate actual security vulnerabilities
2. **Timing issues in traffic simulation**: Adjust timeout values for slower environments
3. **Cart state conflicts**: Traffic tests may leave cart items from previous runs

#### Selector Not Found Errors
1. Check if the application structure has changed
2. Update selectors in test files to match current HTML
3. Use flexible selectors with multiple fallbacks

#### Timeout Issues
1. Increase timeout for specific operations:
   ```typescript
   test.setTimeout(90000); // 90 seconds
   ```
2. Check network connectivity to target applications
3. Verify services are running and responsive

#### AI Service Integration Failures
1. Verify AI service is deployed and accessible
2. Check API endpoints and authentication
3. Tests include fallback handling for AI unavailability

### Getting Help

1. **View test report**: `npm run report`
2. **Run with debug mode**: `npm run test:debug`
3. **Check application logs**: Verify target applications are running
4. **Validate environment**: Ensure all required URLs and variables are set

## Contributing

When adding new tests:

1. **Choose the right test suite**:
   - Basic tests: Essential functionality only
   - Comprehensive tests: Complex workflows and edge cases
   - Traffic tests: User behavior simulation and security testing

2. **Use the centralized configuration**:
   - Import `test-config.js` instead of accessing env vars directly
   - Use helper methods like `isStoreFrontConfigured()`
   - Leverage consistent title and branding expectations

3. **Follow naming conventions**:
   - Descriptive test names that indicate user behavior or scenario
   - Logical grouping with `test.describe()`
   - Clear distinction between functional and simulation tests

3. **Use flexible selectors**:
   - Multiple fallback options
   - Semantic selectors when possible

4. **Handle edge cases**:
   - Service unavailability
   - Missing optional features
   - Different deployment configurations

5. **Add meaningful assertions**:
   - Clear error messages
   - Specific validation points
   - Performance checks when relevant
   - Security validation for traffic tests

6. **Consider realistic timing**:
   - Traffic simulation tests should include human-like delays
   - Use variable timing to simulate real user behavior
   - Balance test speed with realistic interaction patterns

This test suite provides comprehensive coverage of both AKS Store Demo applications with flexible, brand-agnostic testing that works across different deployment scenarios. The addition of traffic simulation tests enables realistic load testing, user behavior analysis, and security validation.
