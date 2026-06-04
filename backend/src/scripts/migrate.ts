import { pool } from '../config/database';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
dotenv.config();

async function migrate() {
  console.log('🔄 Running migrations...');
  const sql = fs.readFileSync(path.join(__dirname, '../models/schema.sql'), 'utf8');
  await pool.query(sql);
  console.log('✅ Migration completed successfully');
  await pool.end();
  process.exit(0);
}

migrate().catch(e => { console.error('❌ Migration failed:', e); process.exit(1); });
