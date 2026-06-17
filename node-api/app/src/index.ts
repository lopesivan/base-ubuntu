import express from "express";
import itemsRouter from "./routes/items";

const app = express();
const PORT = parseInt(process.env.PORT ?? "3000", 10);

app.use(express.json());

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok", ts: new Date().toISOString() });
});

app.use("/items", itemsRouter);

app.listen(PORT, "0.0.0.0", () => {
  console.log(`[api] rodando em http://0.0.0.0:${PORT}`);
});
