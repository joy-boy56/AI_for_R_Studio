import { Hono } from 'hono'
import { z } from 'zod'
import { NVIDIAProvider } from './providers/nvidia'
import { OpenAICompatibleProvider } from './providers/openai-compatible'

export const router = new Hono()

// Request schemas
const ChatRequestSchema = z.object({
  messages: z.array(z.object({
    role: z.enum(['system', 'user', 'assistant']),
    content: z.string().min(1).max(50000)
  })).min(1).max(50),
  model: z.string().optional(),
  max_tokens: z.number().int().positive().max(4096).optional().default(700),
  temperature: z.number().min(0).max(2).optional().default(0.7),
  stream: z.boolean().optional().default(false)
})

const ModelsQuerySchema = z.object({
  provider: z.enum(['nvidia', 'openai-compatible', 'all']).optional().default('all')
})

// Provider instances (lazy initialization)
let nvidiaProvider: NVIDIAProvider | null = null
let openaiProvider: OpenAICompatibleProvider | null = null

function getNVIDIAProvider(env: any): NVIDIAProvider {
  if (!nvidiaProvider) {
    nvidiaProvider = new NVIDIAProvider(env)
  }
  return nvidiaProvider
}

function getOpenAIProvider(env: any): OpenAICompatibleProvider {
  if (!openaiProvider) {
    openaiProvider = new OpenAICompatibleProvider(env)
  }
  return openaiProvider
}

// POST /chat - Chat completion endpoint
router.post('/chat', async (c) => {
  const env = c.env
  const body = await c.req.json()
  
  // Validate request
  const result = ChatRequestSchema.safeParse(body)
  if (!result.success) {
    return c.json({
      error: 'Invalid request',
      details: result.error.flatten()
    }, 400)
  }
  
  const { messages, model, max_tokens, temperature, stream } = result.data
  
  try {
    // Try NVIDIA first if model suggests it or if no model specified
    let provider: any = null
    let selectedModel = model
    
    if (!selectedModel || selectedModel.includes('nemotron') || selectedModel.includes('nvidia')) {
      const nvidia = getNVIDIAProvider(env)
      if (nvidia.isConfigured()) {
        provider = nvidia
        if (!selectedModel) {
          selectedModel = nvidia.getDefaultModel()
        }
      }
    }
    
    // Fall back to OpenAI-compatible
    if (!provider) {
      const openai = getOpenAIProvider(env)
      if (openai.isConfigured()) {
        provider = openai
        if (!selectedModel) {
          selectedModel = openai.getDefaultModel()
        }
      }
    }
    
    if (!provider) {
      return c.json({
        error: 'No providers configured',
        message: 'Configure NVIDIA_API_KEY or OPENAI_API_KEY in Cloudflare secrets'
      }, 503)
    }
    
    const response = await provider.chat({
      messages,
      model: selectedModel,
      max_tokens,
      temperature,
      stream
    })
    
    return c.json(response)
  } catch (error: any) {
    console.error('Chat error:', error)
    
    if (error.name === 'RateLimitError') {
      return c.json({
        error: 'Rate limit exceeded',
        message: error.message
      }, 429)
    }
    
    if (error.name === 'AuthenticationError') {
      return c.json({
        error: 'Authentication failed',
        message: 'Invalid API credentials'
      }, 401)
    }
    
    if (error.name === 'ModelNotFoundError') {
      return c.json({
        error: 'Model not found',
        message: error.message
      }, 404)
    }
    
    return c.json({
      error: 'Internal server error',
      message: error.message || 'Unknown error'
    }, 500)
  }
})

// GET /models - List available models
router.get('/models', async (c) => {
  const env = c.env
  const query = c.req.query()
  
  const result = ModelsQuerySchema.safeParse(query)
  if (!result.success) {
    return c.json({
      error: 'Invalid query',
      details: result.error.flatten()
    }, 400)
  }
  
  const { provider: providerFilter } = result.data
  const allModels: any[] = []
  
  // Get NVIDIA models
  if (providerFilter === 'all' || providerFilter === 'nvidia') {
    const nvidia = getNVIDIAProvider(env)
    if (nvidia.isConfigured()) {
      try {
        const models = await nvidia.getModels()
        allModels.push(...models.map(m => ({ ...m, provider: 'nvidia' })))
      } catch (error) {
        console.warn('Failed to fetch NVIDIA models:', error)
      }
    }
  }
  
  // Get OpenAI-compatible models
  if (providerFilter === 'all' || providerFilter === 'openai-compatible') {
    const openai = getOpenAIProvider(env)
    if (openai.isConfigured()) {
      try {
        const models = await openai.getModels()
        allModels.push(...models.map(m => ({ ...m, provider: 'openai-compatible' })))
      } catch (error) {
        console.warn('Failed to fetch OpenAI models:', error)
      }
    }
  }
  
  return c.json({
    models: allModels,
    count: allModels.length
  })
})

// GET /providers - List configured providers
router.get('/providers', (c) => {
  const env = c.env
  const nvidia = getNVIDIAProvider(env)
  const openai = getOpenAIProvider(env)
  
  return c.json({
    providers: [
      {
        name: 'nvidia',
        configured: nvidia.isConfigured(),
        default_model: nvidia.getDefaultModel()
      },
      {
        name: 'openai-compatible',
        configured: openai.isConfigured(),
        base_url: env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
        default_model: openai.getDefaultModel()
      }
    ]
  })
})