// tests/e2e/login.spec.js
// Example Playwright E2E test — replace with your actual flows

const { test, expect } = require("@playwright/test");

const BASE_URL = process.env.BASE_URL || "http://localhost:3000";

test.describe("Authentication flow", () => {
  test("login page loads", async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await expect(page).toHaveTitle(/Login/);
    await expect(page.locator("input[type=email]")).toBeVisible();
    await expect(page.locator("input[type=password]")).toBeVisible();
  });

  test("invalid credentials show error", async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await page.fill("input[type=email]", "wrong@example.com");
    await page.fill("input[type=password]", "wrongpass");
    await page.click("button[type=submit]");
    await expect(page.locator(".error-message")).toBeVisible();
  });
});
