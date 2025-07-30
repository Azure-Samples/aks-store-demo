/**
 * Common test configuration for all Playwright tests
 * This module provides standardized access to environment variables
 * used across all test suites in the project.
 */

import { mergeEnvironments } from './load-env.js';

// Load environment variables from all sources
const env = mergeEnvironments();

/**
 * Test configuration object containing all common settings
 */
export const testConfig = {
  // Store URLs
  storeAdminUrl: env.SERVICE_STORE_ADMIN_ENDPOINT_URL || 'http://',
  storeFrontUrl: env.SERVICE_STORE_FRONT_ENDPOINT_URL || 'http://',
  
  // Company branding
  companyName: env.COMPANY_NAME || 'Contoso',
  
  // Helper methods for common checks
  isStoreAdminConfigured() {
    return this.storeAdminUrl !== 'http://';
  },
  
  isStoreFrontConfigured() {
    return this.storeFrontUrl !== 'http://';
  },
  
  // Helper methods for common title expectations
  getExpectedAdminTitle() {
    return new RegExp(`${this.companyName} Pet Store Admin Portal`);
  },
  
  getExpectedStoreFrontTitle() {
    return new RegExp(`${this.companyName} Pet Store`);
  }
};

export default testConfig;
