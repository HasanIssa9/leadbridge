import { Router, Request, Response } from 'express';
import { authService } from './auth.service';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { query } from '../../config/database';

const router = Router();

router.post('/register', async (req: Request, res: Response) => {
  try {
    const result = await authService.register(req.body);
    res.status(201).json({ success: true, data: result });
  } catch (e: any) { res.status(400).json({ success: false, error: e.message }); }
});

router.post('/login', async (req: Request, res: Response) => {
  try {
    const result = await authService.login(req.body.email, req.body.password);
    res.json({ success: true, data: result });
  } catch (e: any) { res.status(401).json({ success: false, error: e.message }); }
});

router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const tokens = await authService.refreshAccessToken(req.body.refreshToken);
    res.json({ success: true, data: tokens });
  } catch (e: any) { res.status(401).json({ success: false, error: e.message }); }
});

router.post('/logout', authenticate, async (req: AuthRequest, res: Response) => {
  await authService.logout(req.user!.id);
  res.json({ success: true });
});

router.get('/me', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const r = await query(
      `SELECT u.id, u.org_id, u.email, u.full_name, u.role, o.name as org_name
       FROM users u JOIN organizations o ON o.id = u.org_id WHERE u.id = $1`,
      [req.user!.id]
    );
    res.json({ success: true, data: r.rows[0] });
  } catch (e: any) { res.status(500).json({ error: e.message }); }
});

export default router;
