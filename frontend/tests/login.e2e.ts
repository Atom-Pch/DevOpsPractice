import { expect, test } from '@playwright/test';

test.describe('Verify login page', () => {
    test('Clicking login button navigates to login page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Log In to Continue' }).click();
        await page.waitForURL('**/login');

        await expect(page.locator('h1')).toHaveText('Welcome Back');
    });

    test('Clicking navigation bar login button navigates to login page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Login' }).click();
        await page.waitForURL('**/login');

        await expect(page.locator('h1')).toHaveText('Welcome Back');
    });
});
