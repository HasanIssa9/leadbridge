import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { query } from '../../config/database';

const router = Router();

async function getSource(key: string) {
  const r = await query(`SELECT ls.*, o.id as org_id FROM lead_sources ls JOIN organizations o ON o.id=ls.org_id WHERE ls.webhook_secret=$1 AND ls.is_active=true`, [key]);
  return r.rows[0];
}

async function createLeadFromWebhook(orgId: string, sourceId: string, data: any) {
  return query(
    `INSERT INTO leads (org_id,source_id,full_name,phone,province,product,metadata) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
    [orgId, sourceId, data.full_name||'Unknown', data.phone||'', data.province||null, data.product||null, JSON.stringify(data.metadata||{})]
  );
}

// Facebook
router.get('/facebook/:key', async (req: Request, res: Response) => {
  const src = await getSource(req.params.key);
  if (!src) return res.status(404).send('Not found');
  if (req.query['hub.mode'] === 'subscribe' && req.query['hub.verify_token'] === src.webhook_secret)
    return res.send(req.query['hub.challenge']);
  res.status(403).send('Forbidden');
});

router.post('/facebook/:key', async (req: Request, res: Response) => {
  try {
    const src = await getSource(req.params.key);
    if (!src) return res.status(404).send('Not found');
    for (const entry of req.body.entry || []) {
      for (const change of entry.changes || []) {
        if (change.field !== 'leadgen') continue;
        const fields: any = {};
        for (const f of change.value.field_data || []) fields[f.name] = Array.isArray(f.values) ? f.values[0] : f.values;
        await createLeadFromWebhook(src.org_id, src.id, {
          full_name: fields.full_name || fields.name || 'Unknown',
          phone: fields.phone_number || fields.phone || '',
          province: fields.city || null,
          metadata: { platform: 'facebook', ...fields },
        });
      }
    }
    res.json({ success: true });
  } catch (e: any) { res.status(500).json({ error: e.message }); }
});

// TikTok
router.post('/tiktok/:key', async (req: Request, res: Response) => {
  try {
    const src = await getSource(req.params.key);
    if (!src) return res.status(404).send('Not found');
    const items = Array.isArray(req.body) ? req.body : [req.body];
    for (const item of items) {
      const fields: any = {};
      for (const f of item.fields || []) fields[f.name] = f.value;
      await createLeadFromWebhook(src.org_id, src.id, {
        full_name: fields.full_name || fields.name || 'Unknown',
        phone: fields.phone_number || fields.phone || '',
        metadata: { platform: 'tiktok', ...fields },
      });
    }
    res.json({ success: true });
  } catch (e: any) { res.status(500).json({ error: e.message }); }
});

// Google
router.post('/google/:key', async (req: Request, res: Response) => {
  try {
    const src = await getSource(req.params.key);
    if (!src) return res.status(404).send('Not found');
    const answers: any = {};
    for (const a of req.body.user_column_data || []) answers[a.column_name.toLowerCase()] = a.string_value;
    await createLeadFromWebhook(src.org_id, src.id, {
      full_name: answers.full_name || answers.name || 'Unknown',
      phone: answers.phone_number || answers.phone || '',
      metadata: { platform: 'google', ...answers },
    });
    res.json({ success: true });
  } catch (e: any) { res.status(500).json({ error: e.message }); }
});

export default router;
