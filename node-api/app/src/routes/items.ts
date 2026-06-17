import { Router, Request, Response } from "express";
import db from "../db";

const router = Router();

router.get("/", (_req: Request, res: Response) => {
  const rows = db.prepare("SELECT * FROM items ORDER BY created_at DESC").all();
  res.json(rows);
});

router.get("/:id", (req: Request, res: Response) => {
  const row = db.prepare("SELECT * FROM items WHERE id = ?").get(req.params.id);
  if (!row) {
    res.status(404).json({ error: "Not found" });
    return;
  }
  res.json(row);
});

router.post("/", (req: Request, res: Response) => {
  const { name, value } = req.body as { name?: string; value?: string };
  if (!name) {
    res.status(400).json({ error: "name é obrigatório" });
    return;
  }
  const result = db
    .prepare("INSERT INTO items (name, value) VALUES (?, ?)")
    .run(name, value ?? null);
  res.status(201).json({ id: result.lastInsertRowid });
});

router.put("/:id", (req: Request, res: Response) => {
  const { name, value } = req.body as { name?: string; value?: string };
  const result = db
    .prepare("UPDATE items SET name = ?, value = ? WHERE id = ?")
    .run(name, value ?? null, req.params.id);
  if (result.changes === 0) {
    res.status(404).json({ error: "Not found" });
    return;
  }
  res.json({ updated: true });
});

router.delete("/:id", (req: Request, res: Response) => {
  const result = db
    .prepare("DELETE FROM items WHERE id = ?")
    .run(req.params.id);
  if (result.changes === 0) {
    res.status(404).json({ error: "Not found" });
    return;
  }
  res.json({ deleted: true });
});

export default router;
