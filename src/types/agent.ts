export interface Agent {
  id: string;
  name: string;
  description: string;
  status: "online" | "warning" | "offline" | "disabled";
  capabilities: string[];
  currentTask?: string;
  lastActivity: string;
  health: number; // 0 - 100
  modelUsed: string;
}
