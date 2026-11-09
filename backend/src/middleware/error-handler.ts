/**
 * Error Handler Middleware
 * 
 * Centralized error handling for the gateway.
 * Provides consistent error responses and logging.
 */

export function errorHandler(err: Error, c: any) {
  // Log the error
  console.error('Gateway error:', {
    message: err.message,
    stack: err.stack,
    path: c.req.path,
    method: c.req.method,
    timestamp: new Date().toISOString()
  })
  
  // Determine error type and response
  const errorName = (err as any).name || 'Error'
  
  switch (errorName) {
    case 'RateLimitError':
      return c.json({
        error: 'Rate limit exceeded',
        message: err.message,
        retry_after: 60
      }, 429)
    
    case 'AuthenticationError':
      return c.json({
        error: 'Authentication failed',
        message: 'Invalid or missing API credentials'
      }, 401)
    
    case 'ModelNotFoundError':
      return c.json({
        error: 'Model not found',
        message: err.message
      }, 404)
    
    case 'ValidationError':
      return c.json({
        error: 'Validation error',
        message: err.message
      }, 400)
    
    case 'ProviderUnavailableError':
      return c.json({
        error: 'Provider unavailable',
        message: err.message
      }, 503)
    
    case 'TimeoutError':
      return c.json({
        error: 'Request timeout',
        message: 'The request took too long to complete'
      }, 504)
    
    default:
      // Don't expose internal error details in production
      const isDev = c.env.ENVIRONMENT === 'development'
      
      return c.json({
        error: 'Internal server error',
        message: isDev ? err.message : 'An unexpected error occurred',
        ...(isDev && { stack: err.stack })
      }, 500)
  }
}

// Custom error classes for consistent error handling
export class RateLimitError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'RateLimitError'
  }
}

export class AuthenticationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'AuthenticationError'
  }
}

export class ModelNotFoundError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ModelNotFoundError'
  }
}

export class ValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

export class ProviderUnavailableError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ProviderUnavailableError'
  }
}

export class TimeoutError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'TimeoutError'
  }
}