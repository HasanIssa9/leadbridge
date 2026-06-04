import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { query } from '../../config/database';

const router = Router();
router.use(authenticate);

router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const { status, province, search, page = 1, limit = 20 } = req.query as any;
    const conds = ['l.org_id = $1']; const params: any[] = [req.user!.org_id]; let idx = 2;
    if (status)   { conds.push(`l.status = $${idx++}`);   params.push(status); }
    if (province) { conds.push(`l.province = $${idx++}`); params.push(province); }
    if (search)   { conds.push(`(l.full_name ILIKE $${idx} OR l.phone ILIKE $${idx})`); params.push(`%${search}%`); idx++; }
    const where = conds.join(' AND ');
    const [data, count] = await Promise.all([
      query(`SELECT l.*, ls.name as source_name, ls.type as source_type FROM leads l LEFT JOIN lead_sources ls ON ls.id=l.source_id WHERE ${where} ORDER BY l.created_at DESC LIMIT $${idx} OFFSET $${idx+1}`, [...params, limit, (page-1)*limit]),
      query(`SELECT COUNT(*) FROM leads l WHERE ${where}`, params),
    ]);
    res.json({ success: true, data: data.rows, total: parseInt(count.rows[0].count), page: +page, totalPages: Math.ceil(+count.rows[0].count/+limit) });
  } catch (e: any) { res.status(500).json({ error: e.message }); }
});

router.get('/stats', async (req: AuthRequest, res: Response) => {
  const r = await query(
    `SELECT COUNT(*) as total, COUNT(*) FILTER(WHERE status='new') as new_count, COUNT(*) FILTER(WHERE status='in_delivery') as in_delivery_count, COUNT(*) FILTER(WHERE status='delivered') as delivered_count, COUNT(*) FILTER(WHERE status='cancelled') as cancelled_count, COUNT(*) FILTER(WHERE created_at>=NOW()-INTERVAL '24 hours') as today_count, COUNT(*) FILTER(WHERE created_at>=NOW()-INTERVAL '7 days') as week_count FROM leads WHERE org_id=$1`,
    [req.user!.org_id]
  );
  res.json({ success: true, data: r.rows[0] });
});

router.get('/:id', async (req: AuthRequest, res: Response) => {
  const r = await query('SELECT l.*, ls.name as source_name FROM leads l LEFT JOIN lead_sources ls ON ls.id=l.source_id WHERE l.id=$1 AND l.org_id=$2', [req.params.id, req.user!.org_id]);
  if (!r.rows[0]) return res.status(404).json({ error: 'Not found' });
  res.json({ success: true, data: r.rows[0] });
});

router.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const { full_name, phone, phone2, province, city, address, product, notes, source_id, metadata } = req.body;
    const r = await query(
      `INSERT INTO leads (org_id,source_id,full_name,phone,phone2,province,city,address,product,notes,metadata) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [req.user!.org_id, source_id||null, full_name, phone, phone2||null, province||null, city||null, address||null, product||null, notes||null, JSON.stringify(metadata||{})]
    );
    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e: any) { res.status(400).json({ error: e.message }); }
});

router.put('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const fields: string[] = []; const params: any[] = []; let idx = 1;
    for (const key of ['full_name','phone','phone2','province','city','address','product','notes','status','assigned_to']) {
      if (req.body[key] !== undefined) { fields.push(`${key}=$${idx++}`); params.push(req.body[key]); }
    }
    if (!fields.length) return res.status(400).json({ error: 'No fields to update' });
    fields.push('updated_at=NOW()');
    params.push(req.params.id, req.user!.org_id);
    const r = await query(`UPDATE leads SET ${fields.join(',')} WHERE id=$${idx} AND org_id=$${idx+1} RETURNING *`, params);
    res.json({ success: true, data: r.rows[0] });
  } catch (e: any) { res.status(400).json({ error: e.message }); }
});

router.delete('/:id', async (req: AuthRequest, res: Response) => {
  await query('DELETE FROM leads WHERE id=$1 AND org_id=$2', [req.params.id, req.user!.org_id]);
  res.json({ success: true });
});

export default router;
