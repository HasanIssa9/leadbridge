import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { query } from '../config/database';

export interface AuthRequest extends Request {
  user?: { id: string; org_id: string; email: string; role: string; };
}

export const authenticate = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'No token provided' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
    const result = await query('SELECT id, org_id, email, role, is_active FROM users WHERE id = $1', [decoded.userId]);
    if (!result.rows[0]?.is_active) return res.status(401).json({ error: 'Unauthorized' });
    req.user = result.rows[0];
    next();
  } catch { res.status(401).json({ error: 'Invalid token' }); }
};

export const authorize = (...roles: string[]) => (req: AuthRequest, res: Response, next: NextFunction) => {
  if (!req.user || !roles.includes(req.user.role))
    return res.status(403).json({ error: 'Insufficient permissions' });
  next();
};
