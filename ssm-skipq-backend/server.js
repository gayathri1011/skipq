import dotenv from 'dotenv';
import http from 'http';
import express from 'express';
import mongoose from 'mongoose';
import { Server } from 'socket.io';
import connectDB from './config/db.js';
import authRoutes from './routes/authRoutes.js';
import menuRoutes from './routes/menuRoutes.js';
import orderRoutes from './routes/orderRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import settingsRoutes from './routes/settingsRoutes.js';
import superAdminRoutes from './routes/superAdminRoutes.js';
import {
  getAllowedOrigins,
  getSocketCorsOptions,
  isOriginAllowed,
} from './utils/corsOrigins.js';
import { socketAuthMiddleware } from './middleware/socketAuth.js';

dotenv.config();

const allowedOrigins = getAllowedOrigins();

const app = express();
const server = http.createServer(app);

app.set('trust proxy', 1);

const io = new Server(server, {
  cors: getSocketCorsOptions(),
});

/**
 * Explicit CORS middleware — handles preflight OPTIONS before any route.
 * Runs first so every allowed cross-origin request gets the right headers.
 */
app.use((req, res, next) => {
  const origin = req.headers.origin;

  if (origin && isOriginAllowed(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader(
      'Access-Control-Allow-Methods',
      'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    );
    res.setHeader(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization, X-Super-Admin-Id, X-Super-Admin-Password',
    );
    res.setHeader('Vary', 'Origin');
  }

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  next();
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (_req, res) => {
  res.json({
    success: true,
    message: 'SSM SkipQ API',
    health: '/api/health',
  });
});

app.get('/api/health', (_req, res) => {
  res.json({
    success: true,
    message: 'SSM SkipQ API is running',
    timestamp: new Date().toISOString(),
    db: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/super-admin', superAdminRoutes);

app.set('io', io);

io.use(socketAuthMiddleware);

io.on('connection', (socket) => {
  const { user } = socket.data;
  console.log(`Socket connected: ${socket.id} (${user.role})`);

  socket.on('join:manager', () => {
    if (user.role !== 'manager') {
      return;
    }
    socket.join('manager');
  });

  socket.on('join:student', () => {
    if (user.role !== 'student') {
      return;
    }
    socket.join(`student:${user.id}`);
  });

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

const PORT = Number(process.env.PORT) || 5000;
const HOST = '0.0.0.0';

const startServer = async () => {
  await new Promise((resolve, reject) => {
    server.listen(PORT, HOST, (error) => {
      if (error) {
        reject(error);
        return;
      }

      console.log(`Server running on http://${HOST}:${PORT}`);
      console.log(`CORS allowed origins: ${allowedOrigins.join(', ')}`);
      resolve();
    });
  });

  try {
    await connectDB();
  } catch (error) {
    console.error('MongoDB connection error:', error.message);
  }
};

startServer().catch((error) => {
  console.error('Failed to start server:', error.message);
  process.exit(1);
});
