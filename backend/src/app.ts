import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
dotenv.config();

import { connectRedis } from './config/redis';
import authRoutes          from './modules/auth/auth.routes';
import leadsRoutes         from './modules/leads/leads.routes';
import webhookRoutes       from './modules/webhooks/webhook.routes';
import deliveryRoutes      from './modules/delivery/delivery.routes';
import notificationRoutes  from './modules/notifications/notifications.routes';
import settingsRoutes      from './modules/settings/settings.routes';

const app = express();

// Security
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
}));

// Rate limiting
app.use('/api/auth', rateLimit({ windowMs: 15*60*1000, max: 20, message: { error: 'Too many requests' } }));
app.use('/api',      rateLimit({ windowMs: 60*1000, max: 200 }));

// Logging & parsing
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));

// Routes
app.use('/api/auth',          authRoutes);
app.use('/api/leads',         leadsRoutes);
app.use('/api/webhooks',      webhookRoutes);
app.use('/api/delivery',      deliveryRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/settings',      settingsRoutes);

// Health checks
app.get('/health', (_, res) => res.json({ status: 'ok', timestamp: new Date(), version: '1.0.0' }));

// 404
app.use((_, res) => res.status(404).json({ error: 'Route not found' }));

// Error handler
app.use((err: any, req: any, res: any, next: any) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;

const start = async () => {
  await connectRedis();
  app.listen(PORT, () => {
    console.log(`🚀 LeadBridge API running on port ${PORT}`);
    console.log(`📍 Health: http://localhost:${PORT}/health`);
    console.log(`🌍 ENV: ${process.env.NODE_ENV || 'development'}`);
  });
};

start();
