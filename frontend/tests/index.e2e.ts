import { expect, test } from '@playwright/test';

test.describe('Landing page', () => {
    test('Homepage heading', async ({ page }) => {
        await page.goto('/');

        await expect(page.locator('h1')).toContainText('Welcome to the To-Do App!');
    });

    test('Clicking login link navigates to login page', async ({ page }) => {
        await page.goto('/');

        await page.getByRole('link', { name: 'Log In to Continue' }).click();

        await page.waitForURL('**/login');

        await expect(page.locator('h1')).toHaveText('Welcome Back');
    });

    test('Clicking register link navigates to register page', async ({ page }) => {
        await page.goto('/');

        await page.getByRole('link', { name: 'Create Account' }).click();

        await page.waitForURL('**/register');

        await expect(page.locator('h1')).toHaveText('Create Account');
    });

    test('Clicking nav login link navigates to login page', async ({ page }) => {
        await page.goto('/');

        await page.getByRole('link', { name: 'Login' }).click();

        await page.waitForURL('**/login');

        await expect(page.locator('h1')).toHaveText('Welcome Back');
    });

    test('Clicking nav register link navigates to register page', async ({ page }) => {
        await page.goto('/');

        await page.getByRole('link', { name: 'Register' }).click();

        await page.waitForURL('**/register');

        await expect(page.locator('h1')).toHaveText('Create Account');
    });
});
