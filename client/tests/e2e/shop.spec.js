import { test, expect } from '@playwright/test';

test.describe('Shop Flow', () => {
    test.beforeEach(async ({ page }) => {
        // Mock the API response
        await page.route('*/**/api/snacks', async route => {
            const json = [
                { id: 1, name: 'Cyber Chips', price: 10, emoji: '💾', description: 'Crunchy bytes' },
                { id: 2, name: 'Power Pellets', price: 20, emoji: '💊', description: 'Boost energy' },
            ];
            await route.fulfill({ json });
        });

        await page.goto('/');
    });

    test('should display snacks and allow checkout', async ({ page }) => {
        // 1. Check title
        await expect(page).toHaveTitle(/SnackyNerds/i);

        // 2. Check snacks are displayed
        await expect(page.getByText('Cyber Chips')).toBeVisible();

        // 3. Add to cart
        // Find the button inside the card for Cyber Chips
        const chipsCard = page.locator('.snack-card').filter({ hasText: 'Cyber Chips' });
        await chipsCard.getByRole('button', { name: 'ADD TO PACK +' }).click();

        // 4. Verify cart count in header
        await expect(page.getByRole('button', { name: /CART \(1\)/ })).toBeVisible();

        // 5. Go to Cart
        await page.getByRole('button', { name: /CART \(1\)/ }).click();
        await expect(page).toHaveURL(/.*\/cart/);
        await expect(page.getByText('YOUR LOOT')).toBeVisible();
        await expect(page.getByText('Cyber Chips').first()).toBeVisible();

        // 6. Proceed to Checkout
        await page.getByRole('link', { name: 'PROCEED TO CHECKOUT ➡️' }).click();
        await expect(page).toHaveURL(/.*\/checkout/);

        // 7. Pay (assuming we have enough coins - default is 50, item is 10)
        await expect(page.getByText(/WALLET BALANCE:/)).toBeVisible();
        const payBtn = page.getByRole('button', { name: 'INITIALIZE PAYMENT 🪙' });
        await expect(payBtn).toBeEnabled();
        await payBtn.click();

        // 8. Success
        await expect(page).toHaveURL(/.*\/success/);
        await expect(page.getByText('PAYMENT SUCCESSFUL!')).toBeVisible();
    });
});
