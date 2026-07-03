// API Service Layer for Niranjan AI

import { Agent } from "@/types/agent";
import { Task } from "@/types/task";
import { DocumentItem } from "@/types/document";
import { PluginItem } from "@/types/plugin";
import { ModelItem } from "@/types/model";

export type { Agent, Task, DocumentItem, PluginItem, ModelItem };

// Mock Database Initial Data
export const MOCK_AGENTS: Agent[] = [
  {
    id: "hermes",
    name: "Hermes Core Agent",
    description: "Primary orchestrator for multi-agent reasoning and fast action mapping.",
    status: "online",
    capabilities: ["Task Routing", "Intent Parsing", "Workflow Design"],
    lastActivity: "2 mins ago",
    health: 98,
    modelUsed: "Claude 3.5 Sonnet"
  },
  {
    id: "research",
    name: "Deep Research Agent",
    description: "Gathers, synthesizes, and critiques web and database search results.",
    status: "online",
    capabilities: ["Vector Search", "Source Verification", "Synthesized Reports"],
    lastActivity: "15 mins ago",
    health: 99,
    modelUsed: "Gemini 1.5 Pro"
  },
  {
    id: "flight",
    name: "Flight Booking Agent",
    description: "Queries flight options, compares itineraries, and tracks price changes.",
    status: "online",
    capabilities: ["ITA Matrix API", "Fare Comparison", "Route Optimization"],
    lastActivity: "1 hour ago",
    health: 95,
    modelUsed: "GPT-4o"
  },
  {
    id: "ifza",
    name: "IFZA Assistant",
    description: "Expert agent on IFZA (International Free Zone Authority) business setup rules and documents.",
    status: "online",
    capabilities: ["Corporate Setup Guidelines", "Fee Calculators", "Visa Regulation Mapping"],
    lastActivity: "Just now",
    health: 100,
    modelUsed: "Claude 3.5 Sonnet"
  },
  {
    id: "farm",
    name: "AgriTech Farm Monitor",
    description: "Monitors real-time camera feeds, soil moisture level reports, and smart irrigation states.",
    status: "warning",
    capabilities: ["Camera Feed Analytics", "Irrigation Control", "Anomaly Alerting"],
    lastActivity: "5 mins ago",
    health: 84,
    modelUsed: "Llama 3 8B"
  },
  {
    id: "browser",
    name: "Browser Automation Bot",
    description: "Runs Puppeteer / Playwright scraping tasks, downloads files, and executes form submissions.",
    status: "online",
    capabilities: ["Dynamic Scraping", "Auto-Clicking", "Session Persistence"],
    lastActivity: "3 mins ago",
    health: 96,
    modelUsed: "Qwen 2.5 Coder"
  }
];

export const MOCK_PLUGINS: PluginItem[] = [
  {
    id: "hermes",
    name: "Hermes Core Connect",
    description: "Main plugin connecting local AI instances to the cloud gateway.",
    version: "2.4.1",
    author: "Niranjan AI Team",
    enabled: true,
    health: "healthy",
    installedVersion: "2.4.1",
    capabilities: ["Agent Gateway", "Message Routing"]
  },
  {
    id: "ifza",
    name: "IFZA Business Portal",
    description: "Automated business license queries and structural fee checks for Free Zones.",
    version: "1.0.5",
    author: "Niranjan AI Dubai",
    enabled: true,
    health: "healthy",
    installedVersion: "1.0.5",
    capabilities: ["License Estimator", "Visa Processing"]
  },
  {
    id: "flights",
    name: "Global Flight Booking",
    description: "Integrates with Skyscanner, Sabre, and ITA Matrix for flight queries.",
    version: "3.2.0",
    author: "TravelBot Corp",
    enabled: true,
    health: "healthy",
    installedVersion: "3.2.0",
    capabilities: ["Fare Alerts", "Multi-segment Querying"]
  },
  {
    id: "research",
    name: "Arxiv & Web Scraper",
    description: "Automated academic searches, summarization, and bibliography generation.",
    version: "1.8.2",
    author: "Research Labs",
    enabled: false,
    health: "healthy",
    installedVersion: "1.8.2",
    capabilities: ["ArXiv API", "Semantic Scholar integration"]
  },
  {
    id: "farm",
    name: "Farm IoT Connector",
    description: "Pulls soil sensor metrics and video feeds from local IoT hubs.",
    version: "0.9.1",
    author: "GreenTech IoT",
    enabled: true,
    health: "warning",
    installedVersion: "0.9.1",
    capabilities: ["Soil Moisture API", "Camera Frame Receiver"]
  },
  {
    id: "camera",
    name: "CCTV Motion Guard",
    description: "Feeds security and motion detection alerts into the main activity console.",
    version: "1.1.0",
    author: "SafeWatch",
    enabled: false,
    health: "healthy",
    installedVersion: "1.1.0",
    capabilities: ["HLS Streaming", "YOLO Object Detection"]
  }
];

export const MOCK_MODELS: ModelItem[] = [
  { id: "gpt-4o", name: "GPT-4o", provider: "OpenRouter", latency: "245ms", contextWindow: "128k", status: "online" },
  { id: "claude-3-5-sonnet", name: "Claude 3.5 Sonnet", provider: "OpenRouter", latency: "180ms", contextWindow: "200k", status: "online" },
  { id: "gemini-1-5-pro", name: "Gemini 1.5 Pro", provider: "OpenRouter", latency: "310ms", contextWindow: "2m", status: "online" },
  { id: "deepseek-coder", name: "DeepSeek Coder v2", provider: "OpenRouter", latency: "140ms", contextWindow: "128k", status: "online" },
  { id: "llama-3-3", name: "Llama 3.3 70B", provider: "Ollama", latency: "42ms", contextWindow: "32k", status: "online" },
  { id: "qwen-2-5-coder", name: "Qwen 2.5 Coder 14B", provider: "Ollama", latency: "35ms", contextWindow: "32k", status: "online" },
  { id: "phi-4", name: "Phi-4", provider: "Ollama", latency: "28ms", contextWindow: "16k", status: "online" }
];

export const MOCK_TASKS: Task[] = [
  {
    id: "task-1",
    title: "IFZA Business Setup Rules Parsing",
    status: "completed",
    priority: "high",
    agentUsed: "IFZA Assistant",
    executionTime: "4.8s",
    progress: 100,
    timestamp: "10 mins ago",
    logs: [
      "[10:20:00] Initializing IFZA Agent...",
      "[10:20:01] Fetching regulatory document: IFZA_Executive_Regs_2026.pdf",
      "[10:20:02] Extracting commercial license eligibility clauses...",
      "[10:20:04] Synthesizing summary tables for Niranjan.",
      "[10:20:04.8] Task completed successfully."
    ]
  },
  {
    id: "task-2",
    title: "Flight Query: DXB to LHR",
    status: "completed",
    priority: "medium",
    agentUsed: "Flight Booking Agent",
    executionTime: "3.2s",
    progress: 100,
    timestamp: "45 mins ago",
    logs: [
      "[09:45:00] Launching Flight Agent...",
      "[09:45:01] Querying airline schedules DXB -> LHR (dates: July 12 - July 20)",
      "[09:45:02] Found 14 direct flights, lowest fare: Emirates $850 (Economy)",
      "[09:45:03.2] Flight matrix compiled and stored."
    ]
  },
  {
    id: "task-3",
    title: "Browser Automation: Scrape competitor Pricing",
    status: "failed",
    priority: "critical",
    agentUsed: "Browser Automation Bot",
    executionTime: "8.5s",
    progress: 60,
    timestamp: "2 hours ago",
    logs: [
      "[08:15:00] Launching Headless Chromium session...",
      "[08:15:02] Navigating to target portal...",
      "[08:15:04] Wait for selector '.pricing-table' timed out.",
      "[08:15:06.5] Retry #1 failed. Cloudflare bot protection detected.",
      "[08:15:08.5] Task halted. Error code: E_CLOUDFLARE_BLOCKED"
    ]
  }
];

export const MOCK_DOCUMENTS: DocumentItem[] = [
  {
    id: "doc-1",
    name: "IFZA Corporate Structure Guidelines.pdf",
    type: "pdf",
    size: "2.4 MB",
    folder: "IFZA Setup",
    tags: ["Legal", "Dubai", "IFZA"],
    pinned: true,
    recent: true,
    content: "International Free Zone Authority (IFZA) permits setup with 100% foreign ownership. Capital requirements vary. Zero corporate taxes up to qualifying income. Visual flowchart guides shareholders mapping.",
    updatedAt: "Today, 10:20 AM"
  },
  {
    id: "doc-2",
    name: "DXB-LHR July Price Analytics.xlsx",
    type: "xlsx",
    size: "820 KB",
    folder: "Travel",
    tags: ["Flights", "Analytics"],
    pinned: false,
    recent: true,
    content: "DXB to LHR price comparison tracking June/July fares. Historical lows, peak weekends analysis. Recommends booking BA or Emirates direct flights.",
    updatedAt: "Today, 09:45 AM"
  },
  {
    id: "doc-3",
    name: "Smart Farm Irrigation Logic.js",
    type: "javascript",
    size: "45 KB",
    folder: "AgriTech",
    tags: ["IoT", "Sensor", "Farm"],
    pinned: true,
    recent: false,
    content: "function calculateIrrigation(moisture, temperature) {\n  if (moisture < 35 && temperature > 32) return 'Irrigate (High Flows)';\n  if (moisture < 50) return 'Irrigate (Low Flows)';\n  return 'Stave Irrigation';\n}",
    updatedAt: "Yesterday"
  }
];

// Service classes mimicking real API operations with simulated latencies
export class APIService {
  static async getAgents(): Promise<Agent[]> {
    return new Promise((resolve) => setTimeout(() => resolve(MOCK_AGENTS), 300));
  }

  static async getTasks(): Promise<Task[]> {
    return new Promise((resolve) => setTimeout(() => resolve(MOCK_TASKS), 400));
  }

  static async getDocuments(): Promise<DocumentItem[]> {
    return new Promise((resolve) => setTimeout(() => resolve(MOCK_DOCUMENTS), 350));
  }

  static async getPlugins(): Promise<PluginItem[]> {
    return new Promise((resolve) => setTimeout(() => resolve(MOCK_PLUGINS), 300));
  }

  static async getModels(): Promise<ModelItem[]> {
    return new Promise((resolve) => setTimeout(() => resolve(MOCK_MODELS), 250));
  }

  // Simulated API call with retry and loading handler
  static async executePrompt(
    prompt: string,
    model: string,
    onLogUpdate: (log: string) => void
  ): Promise<Task> {
    return new Promise((resolve, reject) => {
      let progress = 0;
      const taskId = `task-${Math.floor(Math.random() * 1000)}`;
      const logs: string[] = [];

      const addLog = (msg: string) => {
        const time = new Date().toLocaleTimeString();
        const formattedLog = `[${time}] ${msg}`;
        logs.push(formattedLog);
        onLogUpdate(formattedLog);
      };

      addLog(`Connecting to AI Gateway running model: ${model}...`);

      const interval = setInterval(() => {
        progress += 20;
        if (progress === 20) {
          addLog("Parsing prompt parameters and context embeddings...");
        } else if (progress === 40) {
          addLog("Identifying required agents: Router activated.");
          if (prompt.toLowerCase().includes("flight") || prompt.toLowerCase().includes("dxb")) {
            addLog("Spawning Flight Booking Agent...");
          } else if (prompt.toLowerCase().includes("ifza") || prompt.toLowerCase().includes("license")) {
            addLog("Spawning IFZA Assistant Agent...");
          } else if (prompt.toLowerCase().includes("farm") || prompt.toLowerCase().includes("soil")) {
            addLog("Spawning AgriTech Farm Monitor Agent...");
          } else {
            addLog("Spawning Hermes Core Agent...");
          }
        } else if (progress === 60) {
          addLog("Fetching background data and running queries...");
        } else if (progress === 80) {
          addLog("Formatting response object and verifying citations...");
        } else if (progress === 100) {
          clearInterval(interval);
          addLog("Execution complete. Saving results.");
          resolve({
            id: taskId,
            title: prompt.length > 40 ? prompt.substring(0, 37) + "..." : prompt,
            status: "completed",
            priority: "medium",
            agentUsed: prompt.toLowerCase().includes("flight")
              ? "Flight Booking Agent"
              : prompt.toLowerCase().includes("ifza")
              ? "IFZA Assistant"
              : "Hermes Core Agent",
            executionTime: `${(1 + Math.random() * 2).toFixed(1)}s`,
            progress: 100,
            timestamp: "Just now",
            logs
          });
        }
      }, 800);
    });
  }
}
