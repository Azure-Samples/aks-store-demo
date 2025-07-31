# Traffic Simulation Test Suite

This directory contains comprehensive Playwright tests that simulate various customer interaction patterns on the store-front application. These tests are designed to generate realistic traffic patterns and test the application's behavior under different user scenarios.

## Test Categories

### 1. Single Item Buyer (`single-item-buyer.spec.ts`)

Simulates focused customers who know what they want and make quick, targeted purchases.

**Test Cases:**
- **Focused Buyer - Direct Product Purchase**: Quick navigation to product and immediate purchase
- **Impulse Buyer - Quick Add from Homepage**: Rapid selection and cart addition from main page
- **Price-Conscious Buyer - Product Comparison**: Browse multiple products before deciding
- **Malicious Buyer - Non-Existent Product Purchase**: Attempts to purchase products that don't exist

### 2. Casual Browser (`casual-browser.spec.ts`)

Simulates casual shoppers who browse extensively, view multiple products, and may or may not make purchases.

**Test Cases:**
- **Window Shopper - Extensive Browsing, No Purchase**: Browse products without buying
- **Indecisive Shopper - Multiple Cart Additions and Removals**: Add/remove items multiple times
- **Curious Browser - Detailed Product Exploration**: Thorough product investigation
- **Social Browser - Sharing and External Navigation**: Social interaction simulation

### 3. Malicious Buyer (`malicious-buyer.spec.ts`)

Simulates various security testing scenarios and edge cases that could potentially exploit vulnerabilities.

**Test Cases:**
- **Non-Existent Product URL Manipulation**: Direct URL manipulation attempts
- **Cart Manipulation with Non-Existent Products**: JavaScript injection attempts
- **SQL Injection Attempts**: Database injection testing
- **XSS Attempts in Product Parameters**: Cross-site scripting prevention testing
- **Rapid Request Flooding Simulation**: Load testing with rapid requests
- **Price Manipulation Attempt**: Client-side price tampering testing

## Security Testing Features

The malicious buyer tests specifically validate:

### 🔒 **URL Manipulation Protection**
- Tests various malicious URL patterns
- Validates graceful handling of non-existent products
- Ensures no sensitive information exposure

### 🛡️ **Injection Attack Prevention**
- SQL injection payload testing
- XSS (Cross-Site Scripting) prevention validation
- JavaScript injection attempt simulation

### ⚡ **Application Resilience**
- Rapid request flooding resistance
- Server-side validation of client modifications
- Error handling without information leakage

### 💰 **Price Manipulation Protection**
- Client-side price modification attempts
- Server-side validation enforcement
- Cart integrity verification

## Test Patterns

### Realistic Behavior Simulation
- Variable timing delays to simulate human interaction
- Multiple browsing patterns (quick vs. thorough)
- Decision-making simulation (comparison shopping)

### Edge Case Coverage
- Non-existent product handling
- Malformed URL processing
- Invalid data input handling

### Security Validation
- Input sanitization verification
- Authentication bypass attempts
- Data integrity checks

## Usage

### Run All Traffic Tests
```bash
cd tests
npx playwright test traffic/ --reporter=line
```

### Run Specific Test Categories
```bash
# Single item buyer patterns
npx playwright test traffic/single-item-buyer.spec.ts

# Casual browsing patterns  
npx playwright test traffic/casual-browser.spec.ts

# Security/malicious testing
npx playwright test traffic/malicious-buyer.spec.ts
```

### Run with Visual Output
```bash
npx playwright test traffic/ --headed
```

## Expected Test Results

### Legitimate Traffic Tests
- Should complete successfully under normal conditions
- May have some failures due to application state or timing issues
- Simulate realistic customer interaction patterns

### Security Tests (Malicious Buyer)
- Should demonstrate that the application handles malicious inputs gracefully
- Validates that security measures are in place
- Tests should pass, indicating proper security posture

## Configuration

The tests use the shared `test-config.js` configuration which provides:
- Centralized environment variable management
- Consistent URL and branding configuration
- Helper methods for common test patterns

## Monitoring and Analytics

These traffic simulation tests can be used for:
- **Load Testing**: Understanding application behavior under different traffic patterns
- **Security Validation**: Ensuring proper handling of malicious inputs
- **User Experience Testing**: Validating different customer journey scenarios
- **Performance Monitoring**: Identifying bottlenecks in user flows

## Notes

- Some test failures may occur due to application state or UI changes
- Security tests should generally pass, indicating proper input validation
- Tests include realistic delays to simulate human interaction patterns
- Malicious buyer tests help identify potential security vulnerabilities
