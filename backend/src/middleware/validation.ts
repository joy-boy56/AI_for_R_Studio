/**
 * Request Validation Middleware
 * 
 * Validates incoming requests for the chat endpoint.
 * Ensures message structure, content length, and security constraints.
 */

import { z } from 'zod'

// Validation schemas
const MessageSchema = z.object({
  role: z.enum(['system', 'user', 'assistant']),
  content: z.string().min(1).max(50000)
})

const ChatRequestSchema = z.object({
  messages: z.array(MessageSchema).min(1).max(50),
  model: z.string().max(100).optional(),
  max_tokens: z.number().int().positive().max(4096).optional(),
  temperature: z.number().min(0).max(2).optional(),
  stream: z.boolean().optional()
})

// Security patterns to detect
const SUSPICIOUS_PATTERNS = [
  /ignore\s+previous\s+instructions/i,
  /disregard\s+.*instructions/i,
  /system\s+prompt/i,
  /reveal\s+your\s+prompt/i,
  /what\s+is\s+your\s+prompt/i,
  /show\s+me\s+your\s+instructions/i,
  /output\s+your\s+system\s+prompt/i,
  /print\s+your\s+system\s+prompt/i,
  /<\|system\|>/i,
  /<\|user\|>/i,
  /<\|assistant\|>/i,
  /\[INST\]/i,
  /\[SYS\]/i,
  /###\s*Instruction/i,
  /###\s*Response/i
]

// PII patterns
const PII_PATTERNS = [
  /\b\d{3}-\d{2}-\d{4}\b/, // SSN
  /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/, // Credit card
  /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/, // Email
  /\b(?:\d{1,3}\.){3}\d{1,3}\b/, // IP address
  /sk-[a-zA-Z0-9]{32,}/, // OpenAI API key pattern
  /xoxb-[a-zA-Z0-9-]+/, // Slack bot token
  /gh[pousr]_[a-zA-Z0-9]{36,}/ // GitHub token
]

export function validationMiddleware(c: any, next: any) {
  // Only validate POST /chat
  if (c.req.method !== 'POST' || !c.req.path.includes('/chat')) {
    return next()
  }
  
  return validateChatRequest(c, next)
}

async function validateChatRequest(c: any, next: any) {
  try {
    const body = await c.req.json()
    
    // Validate structure
    const result = ChatRequestSchema.safeParse(body)
    if (!result.success) {
      return c.json({
        error: 'Invalid request format',
        details: result.error.flatten()
      }, 400)
    }
    
    const { messages } = result.data
    
    // Validate each message
    for (const msg of messages) {
      // Check for suspicious patterns (prompt injection attempts)
      for (const pattern of SUSPICIOUS_PATTERNS) {
        if (pattern.test(msg.content)) {
          console.warn('Suspicious pattern detected in message:', pattern)
          // Log but don't block - could be legitimate discussion about prompts
        }
      }
      
      // Check for PII
      for (const pattern of PII_PATTERNS) {
        if (pattern.test(msg.content)) {
          console.warn('Potential PII detected in message')
          // Log but don't block
        }
      }
      
      // Check message length
      if (msg.content.length > 50000) {
        return c.json({
          error: 'Message too long',
          max_length: 50000,
          actual_length: msg.content.length
        }, 400)
      }
    }
    
    // Check total conversation length
    const totalChars = messages.reduce((sum: number, m: any) => sum + m.content.length, 0)
    if (totalChars > 100000) {
      return c.json({
        error: 'Conversation too long',
        max_total_chars: 100000,
        actual_total_chars: totalChars
      }, 400)
    }
    
    // Validate model parameter if provided
    if (result.data.model) {
      const model = result.data.model
      if (model.length > 100) {
        return c.json({
          error: 'Model name too long',
          max_length: 100
        }, 400)
      }
      // Basic model name validation
      if (!/^[a-zA-Z0-9/._-]+$/.test(model)) {
        return c.json({
          error: 'Invalid model name format'
        }, 400)
      }
    }
    
    // Validate max_tokens
    if (result.data.max_tokens !== undefined) {
      if (result.data.max_tokens < 1 || result.data.max_tokens > 4096) {
        return c.json({
          error: 'max_tokens must be between 1 and 4096'
        }, 400)
      }
    }
    
    // Validate temperature
    if (result.data.temperature !== undefined) {
      if (result.data.temperature < 0 || result.data.temperature > 2) {
        return c.json({
          error: 'temperature must be between 0 and 2'
        }, 400)
      }
    }
    
    // All validations passed
    return next()
  } catch (error) {
    if (error instanceof SyntaxError) {
      return c.json({
        error: 'Invalid JSON'
      }, 400)
    }
    throw error
  }
}

// Export schemas for reuse
export { ChatRequestSchema, MessageSchema }