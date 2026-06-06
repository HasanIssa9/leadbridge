// Firebase Functions entry point
// This wraps the Express app for Firebase Cloud Functions

import * as functions from 'firebase-functions';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
dotenv.config();

import authRoutes          from './modules/auth/auth.routes';
import leadsRoutes         from './modules/leads/leads.routes';
import webhookRoutes       from './modules/webhooks/webhook.routes';
import deliveryRoutes      from './modules/delivery/delivery.routes';
import notificationRoutes  from './modules/notifications/notifications.routes';
import settingsRoutes      from './modules/settings/settings.routes';

const app = express();

app.use(helmet());
app.use(cors({
  origin: [
    'https://hasanissa9.github.io',
    'https://leadbridge-iraq.web.app',
    'https://leadbridge-iraq.firebaseapp.com',
    'http://localhost:3001',
    'http://localhost:8080',
  ],
  credentials: true,
}));

app.use(express.json({ limit: '10mb' }));

// Routes
app.use('/auth',          authRoutes);
app.use('/leads',         leadsRoutes);
app.use('/webhooks',      webhookRoutes);
app.use('/delivery',      deliveryRoutes);
app.use('/notifications', notificationRoutes);
app.use('/settings',      settingsRoutes);

app.get('/health', (_, res) => res.json({
  status: 'ok',
  timestamp: new Date(),
  version: '1.0.0',
  platform: 'Firebase Functions',
}));

// Export as Firebase Function
export const api = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB',
  })
  .https.onRequest(app);
