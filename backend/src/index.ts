import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { secureHeaders } from 'hono/secure-headers'

import { router } from './router'
import { rateLimitMiddleware } from './middleware/rate-limit'
import { validationMiddleware } from './middleware/validation'
import { errorHandler } from './middleware/error-handler'

type Env = {
  NVIDIA_API_KEY?: string
  OPENAI_API_KEY?: string
  OPENAI_BASE_URL?: string
  RATE_LIMIT_PER_MINUTE?: string
  RATE_LIMIT_PER_HOUR?: string
  ALLOWED_ORIGINS?: string
  LOG_LEVEL?: string
}

const app = new Hono<{ Bindings: Env }>()

// Global middleware
app.use('*', logger())
app.use('*', secureHeaders())
app.use('*', cors({
  origin: (origin, c) => {
    const allowed = c.env.ALLOWED_ORIGINS?.split(',').map(o => o.trim()) || ['*']
    if (allowed.includes('*') || allowed.includes(origin)) {
      return origin
    }
    return null
  },
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400
}))

// Rate limiting
app.use('/chat', rateLimitMiddleware)
app.use('/models', rateLimitMiddleware)

// Request validation
app.use('/chat', validationMiddleware)

// Routes
app.route('/', router)

// Error handling
app.onError(errorHandler)

// Health check
app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    service: 'rconsoleai-gateway',
    version: '0.1.0',
    timestamp: new Date().toISOString()
  })
})

// Root endpoint
app.get('/', (c) => {
  return c.json({
    name: 'RConsoleAI Gateway',
    version: '0.1.0',
    description: 'Secure AI provider gateway for RConsoleAI',
    endpoints: {
      chat: 'POST /chat',
      models: 'GET /models',
      health: 'GET /health'
    }
  })
})

export default app