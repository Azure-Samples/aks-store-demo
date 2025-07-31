/**
 * Type declarations for test-config.js
 */

interface TestConfig {
  storeAdminUrl: string;
  storeFrontUrl: string;
  companyName: string;
  isStoreAdminConfigured(): boolean;
  isStoreFrontConfigured(): boolean;
  getExpectedAdminTitle(): RegExp;
  getExpectedStoreFrontTitle(): RegExp;
}

declare const testConfig: TestConfig;
export = testConfig;
