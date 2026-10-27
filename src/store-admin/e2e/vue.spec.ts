import { test, expect } from '@playwright/test'

const order = {
  orderId: 'order-1',
  customerId: 'customer-1',
  status: 0,
  items: [{ productId: 1, quantity: 2, price: 12.5 }],
}

test.beforeEach(async ({ page }) => {
  await page.route('**/api/products', async (route) => {
    await route.fulfill({
      json: [{ id: 1, name: 'Pet bowl', description: 'Blue ceramic bowl', price: 12.5 }],
    })
  })
  await page.route('**/api/makeline/order/fetch', async (route) => {
    await route.fulfill({ json: [order] })
  })
})

test('renders orders and navigates to products', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('nav')).toContainText('Admin Portal')
  await expect(page.locator('.order-table')).toContainText('customer-1')
  await expect(page.locator('.order-table')).toContainText('25.00')

  await page.getByRole('link', { name: 'Products', exact: true }).click()
  await expect(page).toHaveURL(/\/products$/)
  await expect(page.locator('.product-table')).toContainText('Pet bowl')

  await page.getByRole('link', { name: 'Orders', exact: true }).click()
  await expect(page).toHaveURL(/\/orders$/)
  await expect(page.locator('.order-table')).toContainText('order-1')
})

test('completes an order and reactively removes it from the list', async ({ page }) => {
  await page.route('**/api/makeline/order', async (route) => {
    await route.fulfill({ status: 200, body: '' })
  })
  await page.goto('/')
  await page.locator('.order-table .table-row').click()
  await expect(page).toHaveURL(/\/order\/order-1$/)
  await expect(page.getByRole('heading', { name: 'Order Details' })).toBeVisible()
  await expect(page.locator('.order-items')).toContainText('Pet bowl')

  page.once('dialog', (dialog) => dialog.accept())
  const update = page.waitForRequest(
    (request) => request.url().endsWith('/api/makeline/order') && request.method() === 'PUT',
  )
  await page.getByRole('button', { name: 'Complete Order' }).click()
  expect((await update).postDataJSON()).toEqual({ ...order, status: 1 })
  await expect(page.getByRole('heading', { name: 'No orders available' })).toBeVisible()
  await expect(page.locator('.order-table')).toHaveCount(0)
})
