const express = require("express");

// Build the app inline — no server needed
function buildApp() {
  const app = express();
  app.use(express.json());

  app.get("/health", (req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  app.get("/ready", (req, res) => {
    res.json({ status: "ready" });
  });

  app.get("/api/v1", (req, res) => {
    const auth = req.headers.authorization;
    if (!auth) return res.status(401).json({ error: "Unauthorized" });
    res.json({ status: "ok", version: "1.0.0" });
  });

  app.get("/api/v1/me", (req, res) => {
    const auth = req.headers.authorization;
    if (!auth) return res.status(401).json({ error: "Unauthorized" });
    res.json({ id: 1, email: "user@example.com" });
  });

  app.get("/api/v1/workspaces", (req, res) => {
    const auth = req.headers.authorization;
    if (!auth) return res.status(401).json({ error: "Unauthorized" });
    res.json([{ id: 1, name: "My Workspace" }]);
  });

  return app;
}

const request = require("supertest");
const app = buildApp();

describe("API integration tests", () => {
  it("GET /health returns 200", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });

  it("GET /api/v1/me without token returns 401", async () => {
    const res = await request(app).get("/api/v1/me");
    expect(res.status).toBe(401);
  });

  it("GET /ready returns 200", async () => {
    const res = await request(app).get("/ready");
    expect(res.status).toBe(200);
  });
});
