export interface Task {
  id: string;
  title: string;
  status: "running" | "queued" | "completed" | "failed";
  priority: "low" | "medium" | "high" | "critical";
  agentUsed: string;
  executionTime: string; // e.g. "1.2s"
  progress: number; // 0 - 100
  timestamp: string;
  logs: string[];
}
