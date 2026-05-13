const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.get("/ready", (req, res) => {
  res.json({ status: "ready" });
});

app.get("/metrics", (req, res) => {
  res.json({ uptime: process.uptime(), memory: process.memoryUsage() });
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

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
