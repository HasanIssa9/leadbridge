import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { query } from '../../config/database';

const router = Router();
router.use(authenticate);

router.get('/', async (req: AuthRequest, res: Response) => {
  const page = Number(req.query.page) || 1;
  const [data, count, unread] = await Promise.all([
    query('SELECT * FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 20 OFFSET $2', [req.user!.id, (page-1)*20]),
    query('SELECT COUNT(*) FROM notifications WHERE user_id=$1', [req.user!.id]),
    query('SELECT COUNT(*) FROM notifications WHERE user_id=$1 AND is_read=false', [req.user!.id]),
  ]);
  res.json({ success: true, data: data.rows, total: parseInt(count.rows[0].count), unread: parseInt(unread.rows[0].count) });
});

router.post('/read-all', async (req: AuthRequest, res: Response) => {
  await query('UPDATE notifications SET is_read=true WHERE user_id=$1', [req.user!.id]);
  res.json({ success: true });
});

router.post('/register-device', async (req: AuthRequest, res: Response) => {
  const { fcm_token, platform } = req.body;
  if (fcm_token) {
    await query(`INSERT INTO user_devices (user_id,fcm_token,platform) VALUES ($1,$2,$3) ON CONFLICT (fcm_token) DO UPDATE SET user_id=$1, is_active=true, updated_at=NOW()`, [req.user!.id, fcm_token, platform||'android']);
  }
  res.json({ success: true });
});

export default router;
