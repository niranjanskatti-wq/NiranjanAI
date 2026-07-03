export interface ModelItem {
  id: string;
  name: string;
  provider: "OpenRouter" | "Ollama";
  latency: string;
  contextWindow: string;
  status: "online" | "offline";
}
