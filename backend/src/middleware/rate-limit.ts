/**
 * Rate Limiting Middleware
 * 
 * Implements per-IP and global rate limiting for the gateway.
 * Uses in-memory storage (suitable for single-instance Workers).
 * For production multi-instance, use KV or Durable Objects.
 */

interface RateLimitConfig {
  perMinute: number
  perHour: number
}

interface RateLimitEntry {
  count: number
  resetTime: number
}

interface HourlyRateLimitEntry {
  count: number
  resetTime: number
}

// In-memory stores (per Worker instance)
const minuteStore = new Map<string, RateLimitEntry>()
const hourStore = new Map<string, HourlyRateLimitEntry>()

// Global counters
let globalMinuteCount = 0
let globalMinuteReset = Date.now() + 60000
let globalHourCount = 0
let globalHourReset = Date.now() + 3600000

export function rateLimitMiddleware(c: any, next: any) {
  const env = c.env
  
  // Parse configuration
  const perMinute = parseInt(env.RATE_LIMIT_PER_MINUTE || '60', 10)
  const perHour = parseInt(env.RATE_LIMIT_PER_HOUR || '1000', 10)
  
  // Get client IP
  const ip = c.req.header('cf-connecting-ip') || 
             c.req.header('x-forwarded-for')?.split(',')[0]?.trim() || 
             'unknown'
  
  const now = Date.now()
  
  // Check global limits
  if (now > globalMinuteReset) {
    globalMinuteCount = 0
    globalMinuteReset = now + 60000
  }
  if (now > globalHourReset) {
    globalHourCount = 0
    globalHourReset = now + 3600000
  }
  
  globalMinuteCount++
  globalHourCount++
  
  if (globalMinuteCount > perMinute * 10) { // 10x buffer for global
    return c.json({
      error: 'Global rate limit exceeded',
      retry_after: Math.ceil((globalMinuteReset - now) / 1000)
    }, 429)
  }
  
  if (globalHourCount > perHour * 10) {
    return c.json({
      error: 'Global hourly rate limit exceeded',
      retry_after: Math.ceil((globalHourReset - now) / 1000)
    }, 429)
  }
  
  // Per-IP minute limit
  let minuteEntry = minuteStore.get(ip)
  if (!minuteEntry || now > minuteEntry.resetTime) {
    minuteEntry = { count: 0, resetTime: now + 60000 }
    minuteStore.set(ip, minuteEntry)
  }
  minuteEntry.count++
  
  if (minuteEntry.count > perMinute) {
    return c.json({
      error: 'Rate limit exceeded',
      limit: perMinute,
      window: 'minute',
      retry_after: Math.ceil((minuteEntry.resetTime - now) / 1000)
    }, 429)
  }
  
  // Per-IP hourly limit
  let hourEntry = hourStore.get(ip)
  if (!hourEntry || now > hourEntry.resetTime) {
    hourEntry = { count: 0, resetTime: now + 3600000 }
    hourStore.set(ip, hourEntry)
  }
  hourEntry.count++
  
  if (hourEntry.count > perHour) {
    return c.json({
      error: 'Hourly rate limit exceeded',
      limit: perHour,
      window: 'hour',
      retry_after: Math.ceil((hourEntry.resetTime - now) / 1000)
    }, 429)
  }
  
  // Add rate limit headers
  c.header('X-RateLimit-Limit-Minute', perMinute.toString())
  c.header('X-RateLimit-Remaining-Minute', Math.max(0, perMinute - minuteEntry.count).toString())
  c.header('X-RateLimit-Reset-Minute', Math.ceil(minuteEntry.resetTime / 1000).toString())
  c.header('X-RateLimit-Limit-Hour', perHour.toString())
  c.header('X-RateLimit-Remaining-Hour', Math.max(0, perHour - hourEntry.count).toString())
  c.header('X-RateLimit-Reset-Hour', Math.ceil(hourEntry.resetTime / 1000).toString())
  
  return next()
}

// Cleanup old entries periodically
setInterval(() => {
  const now = Date.now()
  
  for (const [ip, entry] of minuteStore.entries()) {
    if (now > entry.resetTime) {
      minuteStore.delete(ip)
    }
  }
  
  for (const [ip, entry] of hourStore.entries()) {
    if (now > entry.resetTime) {
      hourStore.delete(ip)
    }
  }
}, 300000) // Every 5 minutes