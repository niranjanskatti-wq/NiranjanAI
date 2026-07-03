// Hermes API Client Service Layer for Niranjan AI

export interface HermesHealthResponse {
  status: "healthy" | "unhealthy";
  version: string;
  uptime: number;
}

export interface HermesExecuteResponse {
  taskId: string;
  response: string;
  logs: string[];
  executionTime: string;
}

export class HermesService {
  private static getBaseURL(): string {
    return process.env.NEXT_PUBLIC_HERMES_URL || "http://localhost:8000";
  }

  /**
   * Ping backend to check health.
   */
  static async health(): Promise<HermesHealthResponse> {
    const url = `${this.getBaseURL()}/health`;
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Accept": "application/json"
      },
      signal: AbortSignal.timeout(3000) // 3s timeout
    });
    
    if (!response.ok) {
      throw new Error(`Hermes health check failed: ${response.statusText}`);
    }
    
    return response.json();
  }

  /**
   * Establish initial connection handshakes.
   */
  static async connect(): Promise<boolean> {
    try {
      const status = await this.health();
      return status.status === "healthy";
    } catch {
      return false;
    }
  }

  /**
   * Execute task prompt against Hermes agent network.
   */
  static async executeTask(prompt: string): Promise<HermesExecuteResponse> {
    const url = `${this.getBaseURL()}/execute`;
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({ prompt }),
      signal: AbortSignal.timeout(15000) // 15s timeout
    });

    if (!response.ok) {
      throw new Error(`Hermes task execution failed: ${response.statusText}`);
    }

    return response.json();
  }
}
