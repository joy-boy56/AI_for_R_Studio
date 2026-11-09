/**
 * NVIDIA Nemotron Provider
 * 
 * Uses NVIDIA's OpenAI-compatible API endpoint for Nemotron models.
 * Requires NVIDIA_API_KEY in Cloudflare secrets.
 * 
 * Official API: https://docs.api.nvidia.com/
 * Model catalog: https://build.nvidia.com/
 */

export interface NVIDIAConfig {
  apiKey: string
  baseUrl: string
  defaultModel: string
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

export class NVIDIAProvider {
  private config: NVIDIAConfig
  private modelsCache: ModelInfo[] | null = null
  private modelsCacheTime: number = 0
  private readonly CACHE_TTL = 300000 // 5 minutes

  constructor(env: any) {
    this.config = {
      apiKey: env.NVIDIA_API_KEY || '',
      baseUrl: 'https://integrate.api.nvidia.com/v1',
      defaultModel: 'nvidia/nemotron-3-ultra'
    }
  }

  isConfigured(): boolean {
    return !!this.config.apiKey && this.config.apiKey.length > 0
  }

  getDefaultModel(): string {
    return this.config.defaultModel
  }

  private async fetchWithAuth(url: string, options: RequestInit = {}): Promise<Response> {
    const headers = {
      'Authorization': `Bearer ${this.config.apiKey}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...options.headers
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
          throw new Error('Invalid NVIDIA API key')
        }
        throw new Error(`NVIDIA models request failed: ${response.status}`)
      }

      const data = await response.json()
      
      // Filter for chat/completion models
      const chatModels = (data.data || [])
        .filter((m: any) => 
          m.id.includes('nemotron') || 
          m.id.includes('llama') || 
          m.id.includes('mistral') ||
          m.id.includes('mixtral')
        )
        .map((m: any) => ({
          id: m.id,
          name: m.id,
          provider: 'nvidia',
          owned_by: m.owned_by || 'nvidia'
        }))

      this.modelsCache = chatModels
      this.modelsCacheTime = now
      
      return chatModels
    } catch (error) {
      console.error('Failed to fetch NVIDIA models:', error)
      // Return default model as fallback
      return [{
        id: this.config.defaultModel,
        name: this.config.defaultModel,
        provider: 'nvidia',
        owned_by: 'nvidia'
      }]
    }
  }

  async chat(request: ChatRequest): Promise<ChatResponse> {
    if (!this.isConfigured()) {
      throw new Error('NVIDIA provider not configured')
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
      top_p: 0.9
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

      throw new Error(`NVIDIA API error: ${response.status} - ${errorText}`)
    }

    if (request.stream) {
      // For streaming, return a streaming response
      // This would need special handling in the router
      throw new Error('Streaming not yet implemented in gateway')
    }

    return await response.json()
  }
}