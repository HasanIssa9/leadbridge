import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { query } from '../../config/database';
import axios from 'axios';

const router = Router();
router.use(authenticate);

// Companies
router.get('/companies', async (req: AuthRequest, res: Response) => {
  const r = await query('SELECT * FROM delivery_companies WHERE org_id=$1 ORDER BY name', [req.user!.org_id]);
  res.json({ success: true, data: r.rows });
});

router.post('/companies', async (req: AuthRequest, res: Response) => {
  const { name, api_type, base_url, credentials, supported_provinces } = req.body;
  const r = await query(
    `INSERT INTO delivery_companies (org_id,name,api_type,base_url,credentials,supported_provinces) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [req.user!.org_id, name, api_type||'manual', base_url||null, JSON.stringify(credentials||{}), JSON.stringify(supported_provinces||[])]
  );
  res.status(201).json({ success: true, data: r.rows[0] });
});

router.put('/companies/:id', async (req: AuthRequest, res: Response) => {
  const { name, credentials, supported_provinces, is_active } = req.body;
  const r = await query(
    `UPDATE delivery_companies SET name=$1,credentials=$2,supported_provinces=$3,is_active=$4 WHERE id=$5 AND org_id=$6 RETURNING *`,
    [name, JSON.stringify(credentials||{}), JSON.stringify(supported_provinces||[]), is_active??true, req.params.id, req.user!.org_id]
  );
  res.json({ success: true, data: r.rows[0] });
});

// Rules
router.get('/rules', async (req: AuthRequest, res: Response) => {
  const r = await query(
    `SELECT r.*, dc.name as company_name FROM routing_rules r JOIN delivery_companies dc ON dc.id=r.delivery_company_id WHERE r.org_id=$1 ORDER BY r.priority DESC`,
    [req.user!.org_id]
  );
  res.json({ success: true, data: r.rows });
});

router.post('/rules', async (req: AuthRequest, res: Response) => {
  const { name, conditions, delivery_company_id, priority } = req.body;
  const r = await query(
    `INSERT INTO routing_rules (org_id,name,conditions,delivery_company_id,priority) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
    [req.user!.org_id, name, JSON.stringify(conditions), delivery_company_id, priority||0]
  );
  res.status(201).json({ success: true, data: r.rows[0] });
});

// Dispatch
router.post('/dispatch/:leadId', async (req: AuthRequest, res: Response) => {
  try {
    const leadR = await query('SELECT * FROM leads WHERE id=$1 AND org_id=$2', [req.params.leadId, req.user!.org_id]);
    const lead = leadR.rows[0];
    if (!lead) return res.status(404).json({ error: 'Lead not found' });

    let companyId = req.body.company_id;
    if (!companyId) {
      const rules = await query(`SELECT r.*, dc.name FROM routing_rules r JOIN delivery_companies dc ON dc.id=r.delivery_company_id WHERE r.org_id=$1 AND r.is_active=true ORDER BY r.priority DESC`, [req.user!.org_id]);
      for (const rule of rules.rows) {
        const matches = rule.conditions.every((c: any) => {
          const val = lead[c.field]?.toLowerCase();
          const cv  = c.value?.toLowerCase();
          if (c.operator === 'eq') return val === cv;
          if (c.operator === 'contains') return val?.includes(cv);
          return false;
        });
        if (matches) { companyId = rule.delivery_company_id; break; }
      }
    }
    if (!companyId) return res.status(400).json({ error: 'No delivery company matched' });

    const order = (await query(
      `INSERT INTO orders (org_id,lead_id,delivery_company_id,status,dispatched_at) VALUES ($1,$2,$3,'pending',NOW()) RETURNING *`,
      [req.user!.org_id, lead.id, companyId]
    )).rows[0];
    await query(`UPDATE leads SET status='in_delivery', updated_at=NOW() WHERE id=$1`, [lead.id]);
    res.json({ success: true, data: order });
  } catch (e: any) { res.status(400).json({ error: e.message }); }
});

// Orders
router.get('/orders', async (req: AuthRequest, res: Response) => {
  const { status, page = 1, limit = 20 } = req.query as any;
  const conds = ['o.org_id=$1']; const params: any[] = [req.user!.org_id]; let idx = 2;
  if (status) { conds.push(`o.status=$${idx++}`); params.push(status); }
  const r = await query(
    `SELECT o.*, l.full_name, l.phone, l.province, l.product, dc.name as company_name FROM orders o JOIN leads l ON l.id=o.lead_id JOIN delivery_companies dc ON dc.id=o.delivery_company_id WHERE ${conds.join(' AND ')} ORDER BY o.created_at DESC LIMIT $${idx} OFFSET $${idx+1}`,
    [...params, limit, (page-1)*limit]
  );
  res.json({ success: true, data: r.rows });
});

router.put('/orders/:id/status', async (req: AuthRequest, res: Response) => {
  const { status } = req.body;
  const r = await query(
    `UPDATE orders SET status=$1, delivered_at=CASE WHEN $1='delivered' THEN NOW() ELSE delivered_at END, updated_at=NOW() WHERE id=$2 AND org_id=$3 RETURNING *`,
    [status, req.params.id, req.user!.org_id]
  );
  if (r.rows[0]?.lead_id && status === 'delivered') {
    await query(`UPDATE leads SET status='delivered', updated_at=NOW() WHERE id=$1`, [r.rows[0].lead_id]);
  }
  res.json({ success: true, data: r.rows[0] });
});

export default router;
