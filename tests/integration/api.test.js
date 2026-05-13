// tests/integration/api.test.js
// Example integration test — replace with your actual API tests

const BASE_URL = process.env.BASE_URL || "http://localhost:3000";

describe("API integration tests", () => {
  it("GET /health returns 200", async () => {
    const res = await fetch(`${BASE_URL}/health`);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe("ok");
  });

  it("GET /api/v1 without token returns 401", async () => {
    const res = await fetch(`${BASE_URL}/api/v1/me`);
    expect(res.status).toBe(401);
  });
});
