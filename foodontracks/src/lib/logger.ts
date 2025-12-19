/**
 * Structured Logger Utility
 * Provides consistent, environment-aware logging across the application
 * Supports JSON output for production monitoring and detailed logs for development
 */

type LogLevel = 'info' | 'error' | 'warn' | 'debug';

interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: string;
  environment: string;
  requestId?: string;
  userId?: string | number;
  context?: string;
  meta?: Record<string, any>;
  stack?: string;
}

class Logger {
  private isDevelopment = process.env.NODE_ENV === 'development';

  /**
   * Format log entry as JSON
   */
  private formatLog(
    level: LogLevel,
    message: string,
    meta?: Record<string, any>,
    stack?: string
  ): LogEntry {
    return {
      level,
      message,
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      meta,
      ...(stack && { stack }),
    };
  }

  /**
   * Output log to console (development) or external service (production)
   */
  private output(entry: LogEntry): void {
    if (this.isDevelopment) {
      // Development: Pretty print with colors
      const colors = {
        info: '\x1b[36m',     // Cyan
        error: '\x1b[31m',    // Red
        warn: '\x1b[33m',     // Yellow
        debug: '\x1b[35m',    // Magenta
      };
      const reset = '\x1b[0m';

      console.log(
        `${colors[entry.level]}[${entry.level.toUpperCase()}]${reset} ${entry.message}`,
        entry.meta || ''
      );

      if (entry.stack) {
        console.error(`${colors.error}${entry.stack}${reset}`);
      }
    } else {
      // Production: JSON output (can be sent to external service like Sentry, CloudWatch, etc.)
      console.log(JSON.stringify(entry));

      // TODO: Integrate with external monitoring services
      // - Sentry.captureException() for errors
      // - CloudWatch for metrics
      // - DataDog for distributed tracing
    }
  }

  /**
   * Log info level messages
   */
  info(message: string, meta?: Record<string, any>): void {
    const entry = this.formatLog('info', message, meta);
    this.output(entry);
  }

  /**
   * Log error level messages
   */
  error(message: string, meta?: Record<string, any>, stack?: string): void {
    const entry = this.formatLog('error', message, meta, stack);
    this.output(entry);
  }

  /**
   * Log warning level messages
   */
  warn(message: string, meta?: Record<string, any>): void {
    const entry = this.formatLog('warn', message, meta);
    this.output(entry);
  }

  /**
   * Log debug level messages
   */
  debug(message: string, meta?: Record<string, any>): void {
    if (this.isDevelopment) {
      const entry = this.formatLog('debug', message, meta);
      this.output(entry);
    }
  }
}

// Export singleton instance
export const logger = new Logger();
