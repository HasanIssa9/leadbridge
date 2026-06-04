import { Router, Response } from 'express';
import { authenticate, authorize, AuthRequest } from '../../middleware/auth';
import { query } from '../../config/database';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';

const router = Router();
router.use(authenticate);

router.get('/team', async (req: AuthRequest, res: Response) => {
  const r = await query('SELECT id, email, full_name, role, is_active, last_login, created_at FROM users WHERE org_id=$1 ORDER BY created_at', [req.user!.org_id]);
  res.json({ success: true, data: r.rows });
});

router.post('/team', authorize('admin'), async (req: AuthRequest, res: Response) => {
  const { email, full_name, role, password } = req.body;
  const hash = await bcrypt.hash(password || 'Temp@123456', 12);
  const r = await query(`INSERT INTO users (org_id,email,full_name,role,password_hash) VALUES ($1,$2,$3,$4,$5) RETURNING id,email,full_name,role`, [req.user!.org_id, email, full_name, role||'agent', hash]);
  res.status(201).json({ success: true, data: r.rows[0] });
});

router.put('/team/:id', authorize('admin'), async (req: AuthRequest, res: Response) => {
  const { role, is_active } = req.body;
  const r = await query(`UPDATE users SET role=$1, is_active=$2, updated_at=NOW() WHERE id=$3 AND org_id=$4 RETURNING id,email,full_name,role,is_active`, [role, is_active, req.params.id, req.user!.org_id]);
  res.json({ success: true, data: r.rows[0] });
});

router.get('/lead-sources', async (req: AuthRequest, res: Response) => {
  const r = await query('SELECT * FROM lead_sources WHERE org_id=$1 ORDER BY created_at', [req.user!.org_id]);
  res.json({ success: true, data: r.rows });
});

router.post('/lead-sources', async (req: AuthRequest, res: Response) => {
  const { name, type } = req.body;
  const secret = crypto.randomBytes(32).toString('hex');
  const r = await query(`INSERT INTO lead_sources (org_id,name,type,webhook_secret) VALUES ($1,$2,$3,$4) RETURNING *`, [req.user!.org_id, name, type, secret]);
  res.status(201).json({ success: true, data: r.rows[0] });
});

router.delete('/lead-sources/:id', async (req: AuthRequest, res: Response) => {
  await query('DELETE FROM lead_sources WHERE id=$1 AND org_id=$2', [req.params.id, req.user!.org_id]);
  res.json({ success: true });
});

router.get('/org', async (req: AuthRequest, res: Response) => {
  const r = await query('SELECT id,name,slug,plan,settings FROM organizations WHERE id=$1', [req.user!.org_id]);
  res.json({ success: true, data: r.rows[0] });
});

router.get('/subscription', async (req: AuthRequest, res: Response) => {
  const r = await query(
    `SELECT s.*, p.name as plan_name, p.max_leads, p.max_users, p.max_sources, p.features, p.price_monthly FROM subscriptions s JOIN subscription_plans p ON p.id=s.plan_id WHERE s.org_id=$1`,
    [req.user!.org_id]
  );
  res.json({ success: true, data: r.rows[0] });
});

router.get('/plans', async (_, res: Response) => {
  const r = await query('SELECT * FROM subscription_plans WHERE is_active=true ORDER BY price_monthly');
  res.json({ success: true, data: r.rows });
});

export default router;
