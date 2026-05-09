import { expect, test } from '@playwright/test';

test.describe('Verify Registration page', () => {
    test('Clicking register button navigates to register page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Create Account' }).click();
        await page.waitForURL('**/register');

        await expect(page.locator('h1')).toHaveText('Create Account');
    });

    test('Clicking navigation bar register button navigates to register page', async ({ page }) => {
        await page.goto('/');
        await page.getByRole('link', { name: 'Register' }).click();
        await page.waitForURL('**/register');

        await expect(page.locator('h1')).toHaveText('Create Account');
    });
});
