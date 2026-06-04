import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { query } from '../../config/database';

export class AuthService {
  async register(data: { orgName: string; email: string; password: string; fullName: string; }) {
    const existing = await query('SELECT id FROM users WHERE email = $1', [data.email]);
    if (existing.rows[0]) throw new Error('البريد الإلكتروني مسجل مسبقاً');
    const slug = data.orgName.toLowerCase().replace(/\s+/g, '-') + '-' + Date.now();
    const org = (await query('INSERT INTO organizations (name, slug) VALUES ($1, $2) RETURNING *', [data.orgName, slug])).rows[0];
    const hash = await bcrypt.hash(data.password, 12);
    const user = (await query(
      `INSERT INTO users (org_id, email, password_hash, full_name, role) VALUES ($1,$2,$3,$4,'admin') RETURNING id, org_id, email, full_name, role`,
      [org.id, data.email, hash, data.fullName]
    )).rows[0];
    const tokens = this.generateTokens(user);
    await this.saveRefreshToken(user.id, tokens.refreshToken);
    await query('INSERT INTO subscriptions (org_id, plan_id, current_period_start, current_period_end) VALUES ($1,\'free\',NOW(),NOW() + INTERVAL \'100 years\')', [org.id]);
    return { user, org, ...tokens };
  }

  async login(email: string, password: string) {
    const result = await query(
      `SELECT u.id, u.org_id, u.email, u.full_name, u.role, u.password_hash, u.is_active, o.name as org_name, o.plan
       FROM users u JOIN organizations o ON o.id = u.org_id WHERE u.email = $1`, [email]
    );
    const user = result.rows[0];
    if (!user?.is_active || !(await bcrypt.compare(password, user.password_hash)))
      throw new Error('بيانات الدخول غير صحيحة');
    await query('UPDATE users SET last_login = NOW() WHERE id = $1', [user.id]);
    const tokens = this.generateTokens(user);
    await this.saveRefreshToken(user.id, tokens.refreshToken);
    const { password_hash, ...u } = user;
    return { user: u, ...tokens };
  }

  async refreshAccessToken(refreshToken: string) {
    const r = await query(
      `SELECT rt.user_id, u.org_id, u.email, u.role FROM refresh_tokens rt JOIN users u ON u.id=rt.user_id WHERE rt.token=$1 AND rt.expires_at>NOW()`,
      [refreshToken]
    );
    if (!r.rows[0]) throw new Error('Invalid refresh token');
    const user = r.rows[0];
    const tokens = this.generateTokens({ id: user.user_id, ...user });
    await query('DELETE FROM refresh_tokens WHERE token=$1', [refreshToken]);
    await this.saveRefreshToken(user.user_id, tokens.refreshToken);
    return tokens;
  }

  async logout(userId: string) {
    await query('DELETE FROM refresh_tokens WHERE user_id=$1', [userId]);
  }

  private generateTokens(user: any) {
    return {
      accessToken:  jwt.sign({ userId: user.id, orgId: user.org_id, role: user.role }, process.env.JWT_SECRET!, { expiresIn: '15m' }),
      refreshToken: jwt.sign({ userId: user.id }, process.env.JWT_REFRESH_SECRET!, { expiresIn: '30d' }),
    };
  }
  private async saveRefreshToken(userId: string, token: string) {
    const exp = new Date(); exp.setDate(exp.getDate() + 30);
    await query('INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1,$2,$3)', [userId, token, exp]);
  }
}
export const authService = new AuthService();
