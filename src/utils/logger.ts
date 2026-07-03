type LogLevel = "info" | "warn" | "error" | "debug";

export class Logger {
  static info(message: string, context?: any) {
    this.log("info", message, context);
  }

  static warn(message: string, context?: any) {
    this.log("warn", message, context);
  }

  static error(message: string, context?: any) {
    this.log("error", message, context);
  }

  static debug(message: string, context?: any) {
    this.log("debug", message, context);
  }

  private static log(level: LogLevel, message: string, context?: any) {
    const time = new Date().toLocaleTimeString();
    const formattedMessage = `[${time}] [${level.toUpperCase()}] ${message}`;
    
    if (level === "error") {
      console.error(formattedMessage, context || "");
    } else if (level === "warn") {
      console.warn(formattedMessage, context || "");
    } else if (level === "info") {
      console.info(formattedMessage, context || "");
    } else {
      console.log(formattedMessage, context || "");
    }
  }
}
