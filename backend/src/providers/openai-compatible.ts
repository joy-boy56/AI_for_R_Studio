/**
 * OpenAI-Compatible Provider
 * 
 * Generic adapter for any OpenAI-compatible API endpoint.
 * Supports custom base URLs for local models, Azure OpenAI, etc.
 * Requires OPENAI_API_KEY in Cloudflare secrets.
 * 
 * Compatible with:
 * - OpenAI API (https://api.openai.com/v1)
 * - Azure OpenAI (https://{resource}.openai.azure.com/)
 * - Local models (Ollama, vLLM, TGI, etc.)
 * - Other OpenAI-compatible endpoints
 */

export interface OpenAIConfig {
  apiKey: string
  baseUrl: string
  defaultModel: string
  organization?: string
}

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant'
  content: string
}

export interface ChatRequest {
  messages: ChatMessage[]
  model: string
  max_tokens: number
  temperature: number
  stream: boolean
}

export interface ChatResponse {
  choices: Array<{
    message: {
      role: string
      content: string
    }
    finish_reason: string
    index: number
  }>
  usage?: {
    prompt_tokens: number
    completion_tokens: number
    total_tokens: number
  }
  model: string
}

export interface ModelInfo {
  id: string
  name: string
  provider: string
  owned_by: string
}

export class OpenAICompatibleProvider {
  private config: OpenAIConfig
  private modelsCache: ModelInfo[] | null = null
  private modelsCacheTime: number = 0
  private readonly CACHE_TTL = 300000 // 5 minutes

  constructor(env: any) {
    this.config = {
      apiKey: env.OPENAI_API_KEY || '',
      baseUrl: env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
      defaultModel: 'gpt-3.5-turbo',
      organization: env.OPENAI_ORGANIZATION
    }
  }

  isConfigured(): boolean {
    return !!this.config.apiKey && this.config.apiKey.length > 0
  }

  getDefaultModel(): string {
    return this.config.defaultModel
  }

  getBaseUrl(): string {
    return this.config.baseUrl
  }

  private async fetchWithAuth(url: string, options: RequestInit = {}): Promise<Response> {
    const headers: Record<string, string> = {
      'Authorization': `Bearer ${this.config.apiKey}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...(options.headers as Record<string, string> || {})
    }

    if (this.config.organization) {
      headers['OpenAI-Organization'] = this.config.organization
    }

    return fetch(url, {
      ...options,
      headers
    })
  }

  async getModels(): Promise<ModelInfo[]> {
    // Return cached models if fresh
    const now = Date.now()
    if (this.modelsCache && (now - this.modelsCacheTime) < this.CACHE_TTL) {
      return this.modelsCache
    }

    try {
      const response = await this.fetchWithAuth(`${this.config.baseUrl}/models`)
      
      if (!response.ok) {
        if (response.status === 401) {
          throw new Error('Invalid API key')
        }
        throw new Error(`Models request failed: ${response.status}`)
      }

      const data = await response.json()
      
      // Filter for chat/completion models
      const chatModels = (data.data || [])
        .filter((m: any) => 
          m.id.startsWith('gpt-') || 
          m.id.includes('chat') ||
          m.id.includes('instruct') ||
          m.id.includes('text-') ||
          m.id.includes('claude') ||
          m.id.includes('gemini') ||
          m.id.includes('llama') ||
          m.id.includes('mistral') ||
          m.id.includes('mixtral')
        )
        .map((m: any) => ({
          id: m.id,
          name: m.id,
          provider: 'openai-compatible',
          owned_by: m.owned_by || 'unknown'
        }))

      this.modelsCache = chatModels.length > 0 ? chatModels : [{
        id: this.config.defaultModel,
        name: this.config.defaultModel,
        provider: 'openai-compatible',
        owned_by: 'unknown'
      }]
      this.modelsCacheTime = now
      
      return this.modelsCache
    } catch (error) {
      console.error('Failed to fetch OpenAI-compatible models:', error)
      // Return default model as fallback
      return [{
        id: this.config.defaultModel,
        name: this.config.defaultModel,
        provider: 'openai-compatible',
        owned_by: 'unknown'
      }]
    }
  }

  async chat(request: ChatRequest): Promise<ChatResponse> {
    if (!this.isConfigured()) {
      throw new Error('OpenAI-compatible provider not configured')
    }

    // Validate model
    const models = await this.getModels()
    const modelExists = models.some(m => m.id === request.model)
    if (!modelExists && request.model !== this.config.defaultModel) {
      throw new Error(`Model not available: ${request.model}`)
    }

    const payload = {
      model: request.model,
      messages: request.messages,
      max_tokens: request.max_tokens,
      temperature: request.temperature,
      stream: request.stream,
      top_p: 0.9,
      frequency_penalty: 0,
      presence_penalty: 0
    }

    const response = await this.fetchWithAuth(`${this.config.baseUrl}/chat/completions`, {
      method: 'POST',
      body: JSON.stringify(payload)
    })

    if (!response.ok) {
      const errorText = await response.text()
      
      if (response.status === 429) {
        const error = new Error('Rate limit exceeded') as any
        error.name = 'RateLimitError'
        throw error
      }
      
      if (response.status === 401) {
        const error = new Error('Authentication failed') as any
        error.name = 'AuthenticationError'
        throw error
      }
      
      if (response.status === 404) {
        const error = new Error(`Model not found: ${request.model}`) as any
        error.name = 'ModelNotFoundError'
        throw error
      }

      throw new Error(`API error: ${response.status} - ${errorText}`)
    }

    if (request.stream) {
      throw new Error('Streaming not yet implemented in gateway')
    }

    return await response.json()
  }
}