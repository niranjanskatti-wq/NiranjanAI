"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import {
  Agent,
  Task,
  DocumentItem,
  PluginItem,
  ModelItem,
  MOCK_AGENTS,
  MOCK_DOCUMENTS,
  MOCK_MODELS,
  MOCK_PLUGINS,
  MOCK_TASKS,
  APIService
} from "@/lib/api";

type ViewType =
  | "dashboard"
  | "chat"
  | "research"
  | "browser"
  | "automation"
  | "tasks"
  | "documents"
  | "plugins"
  | "models"
  | "flights"
  | "ifza"
  | "farm"
  | "settings";

interface ChatMessage {
  id: string;
  sender: "user" | "assistant";
  text: string;
  timestamp: string;
  codeBlock?: string;
  codeLanguage?: string;
}

interface WorkspaceContextProps {
  activeView: ViewType;
  setActiveView: (view: ViewType) => void;
  sidebarCollapsed: boolean;
  setSidebarCollapsed: (collapsed: boolean) => void;
  activeWorkspace: string;
  setActiveWorkspace: (workspace: string) => void;
  activeModel: string;
  setActiveModel: (model: string) => void;
  theme: string;
  setTheme: (theme: string) => void;
  prompt: string;
  setPrompt: (prompt: string) => void;
  
  agents: Agent[];
  tasks: Task[];
  documents: DocumentItem[];
  plugins: PluginItem[];
  models: ModelItem[];
  terminalLogs: string[];
  isExecuting: boolean;
  chatMessages: ChatMessage[];
  
  // Settings API Keys
  apiKeys: { openRouter: string; ollama: string; hermes: string };
  setApiKeys: React.Dispatch<React.SetStateAction<{ openRouter: string; ollama: string; hermes: string }>>;
  fastApiUrl: string;
  setFastApiUrl: (url: string) => void;
  
  runPrompt: (customPrompt?: string) => Promise<void>;
  sendChatMessage: (message: string) => Promise<void>;
  togglePlugin: (id: string) => void;
  addDocument: (name: string, type: string, size: string, folder: string, tags: string[], content: string) => void;
  clearLogs: () => void;
}

const WorkspaceContext = createContext<WorkspaceContextProps | undefined>(undefined);

export function WorkspaceProvider({ children }: { children: React.ReactNode }) {
  const [activeView, setActiveView] = useState<ViewType>("dashboard");
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [activeWorkspace, setActiveWorkspace] = useState("Main OS");
  const [activeModel, setActiveModel] = useState("claude-3-5-sonnet");
  const [theme, setTheme] = useState("dark");
  const [prompt, setPrompt] = useState("");
  
  const [agents, setAgents] = useState<Agent[]>(MOCK_AGENTS);
  const [tasks, setTasks] = useState<Task[]>(MOCK_TASKS);
  const [documents, setDocuments] = useState<DocumentItem[]>(MOCK_DOCUMENTS);
  const [plugins, setPlugins] = useState<PluginItem[]>(MOCK_PLUGINS);
  const [models, setModels] = useState<ModelItem[]>(MOCK_MODELS);
  
  const [terminalLogs, setTerminalLogs] = useState<string[]>([
    `[${new Date().toLocaleTimeString()}] System loaded: Niranjan AI v1.0.0.`,
    `[${new Date().toLocaleTimeString()}] Connected to OpenRouter and Local Ollama servers.`,
    `[${new Date().toLocaleTimeString()}] Agents initialized: Hermes Core, Research, Flights, IFZA, Farm, Browser.`
  ]);
  const [isExecuting, setIsExecuting] = useState(false);
  
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
    {
      id: "msg-1",
      sender: "assistant",
      text: "Hello Niranjan. I am your commercial AI operating system. How can I help you coordinate your agents or automate tasks today?",
      timestamp: "Today, 10:00 AM"
    }
  ]);
  
  const [apiKeys, setApiKeys] = useState({
    openRouter: "••••••••••••••••••••••••••••••••",
    ollama: "http://localhost:11434",
    hermes: "••••••••••••••••••••"
  });
  const [fastApiUrl, setFastApiUrl] = useState("http://127.0.0.1:8000");

  useEffect(() => {
    // Sync DOM attribute for theme switching support
    document.documentElement.setAttribute("data-theme", theme);
    if (theme === "light") {
      document.documentElement.classList.add("light");
    } else {
      document.documentElement.classList.remove("light");
    }
  }, [theme]);

  // Keyboard Shortcuts Support
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Toggle Sidebar: Cmd+B (or Ctrl+B)
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "b") {
        e.preventDefault();
        setSidebarCollapsed((prev) => !prev);
      }
      
      // Global Help shortcut: Cmd+/ (or Ctrl+/)
      if ((e.metaKey || e.ctrlKey) && e.key === "/") {
        e.preventDefault();
        alert("Niranjan AI keyboard shortcuts:\n⌘ K : Global Search\n⌘ Enter : Run Prompt\n⌘ B : Toggle Sidebar\n⌘ / : View Help\nESC : Close views");
      }
    };
    
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const clearLogs = () => {
    setTerminalLogs([`[${new Date().toLocaleTimeString()}] Logs cleared.`]);
  };

  const runPrompt = async (customPrompt?: string) => {
    const promptToRun = customPrompt || prompt;
    if (!promptToRun.trim() || isExecuting) return;
    
    setIsExecuting(true);
    setPrompt("");
    
    const initialLogCount = terminalLogs.length;
    const appendLog = (newLog: string) => {
      setTerminalLogs((prev) => [...prev, newLog]);
    };
    
    // Spawn task in Running state
    const newTaskPlaceholder: Task = {
      id: `task-${Date.now()}`,
      title: promptToRun,
      status: "running",
      priority: promptToRun.toLowerCase().includes("critical") ? "critical" : "medium",
      agentUsed: promptToRun.toLowerCase().includes("flight")
        ? "Flight Booking Agent"
        : promptToRun.toLowerCase().includes("ifza")
        ? "IFZA Assistant"
        : "Hermes Core Agent",
      executionTime: "Calculating...",
      progress: 20,
      timestamp: "Just now",
      logs: []
    };
    
    setTasks((prev) => [newTaskPlaceholder, ...prev]);

    try {
      const completedTask = await APIService.executePrompt(
        promptToRun,
        activeModel,
        appendLog
      );
      
      // Update tasks state
      setTasks((prev) =>
        prev.map((t) => (t.id === newTaskPlaceholder.id ? completedTask : t))
      );
      
      // Check if task involves documents or setup
      if (promptToRun.toLowerCase().includes("ifza")) {
        // Automatically create a mock file
        addDocument(
          "IFZA Setup Draft " + Math.floor(Math.random() * 100) + ".pdf",
          "pdf",
          "1.1 MB",
          "IFZA Setup",
          ["IFZA", "Draft", "Corporate"],
          `Generated setup summary based on prompt: "${promptToRun}". Ready for submission.`
        );
      }
    } catch (error) {
      setTasks((prev) =>
        prev.map((t) =>
          t.id === newTaskPlaceholder.id
            ? { ...t, status: "failed", executionTime: "Error", progress: 0 }
            : t
        )
      );
      appendLog(`[ERROR] Task execution failed: ${error}`);
    } finally {
      setIsExecuting(false);
    }
  };

  const sendChatMessage = async (text: string) => {
    if (!text.trim()) return;
    
    const userMsg: ChatMessage = {
      id: `msg-${Date.now()}-u`,
      sender: "user",
      text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
    
    setChatMessages((prev) => [...prev, userMsg]);
    
    // Simulate streaming thinking
    const botMsgId = `msg-${Date.now()}-b`;
    const botMsgPlaceholder: ChatMessage = {
      id: botMsgId,
      sender: "assistant",
      text: "Thinking...",
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
    
    setChatMessages((prev) => [...prev, botMsgPlaceholder]);
    
    setTimeout(() => {
      let reply = "Here is what I gathered regarding your inquiry.";
      let codeBlock = undefined;
      let codeLanguage = undefined;
      
      const query = text.toLowerCase();
      if (query.includes("flight")) {
        reply = "I checked the OpenRouter Flight Agent registry. The DXB to LHR flights on Emirates show daily departures at 08:30, 14:15, and 19:45. Booking window is highly optimal currently.";
      } else if (query.includes("ifza")) {
        reply = "To establish a corporate entity in IFZA, we require: \n\n1. Shareholder passport copies\n2. Proof of residency\n3. Proposed business activities.\n\nI have generated a standard checklist document in your Knowledge Base.";
      } else if (query.includes("farm") || query.includes("soil")) {
        reply = "Connecting to AgriTech sensor hubs. Soil moisture index is at 42%. Water valves are currently closed. I've written a check query to verify irrigation triggers:";
        codeLanguage = "javascript";
        codeBlock = `// Irrigation monitor query
const sensors = await Database.getSensors();
if (sensors.moisture < 35) {
  await Irrigation.openValve({ durationMinutes: 15 });
  console.log("Valves opened successfully");
} else {
  console.log("Moisture level stable at " + sensors.moisture + "%");
}`;
      } else if (query.includes("code") || query.includes("program")) {
        reply = "Here is a clean repository service adapter pattern for your FastAPI connection layer:";
        codeLanguage = "typescript";
        codeBlock = `import axios from 'axios';

export class FastAPIConnector {
  private baseURL = '${fastApiUrl}';

  async getHealth() {
    try {
      const response = await axios.get(\`\${this.baseURL}/health\`);
      return response.data;
    } catch (error) {
      console.error("FastAPI unreachable:", error);
      throw error;
    }
  }
}`;
      } else {
        reply = `Processing prompt: "${text}". I have successfully routed this request to the ${activeModel} engine. The agent network is ready to automate browser tasks or write scripts.`;
      }
      
      setChatMessages((prev) =>
        prev.map((msg) =>
          msg.id === botMsgId
            ? { ...msg, text: reply, codeBlock, codeLanguage }
            : msg
        )
      );
    }, 1200);
  };

  const togglePlugin = (id: string) => {
    setPlugins((prev) =>
      prev.map((p) =>
        p.id === id ? { ...p, enabled: !p.enabled } : p
      )
    );
    const plugin = plugins.find((p) => p.id === id);
    if (plugin) {
      const nextState = !plugin.enabled ? "enabled" : "disabled";
      setTerminalLogs((prev) => [
        ...prev,
        `[${new Date().toLocaleTimeString()}] Plugin ${plugin.name} was ${nextState}.`
      ]);
    }
  };

  const addDocument = (
    name: string,
    type: string,
    size: string,
    folder: string,
    tags: string[],
    content: string
  ) => {
    const newDoc: DocumentItem = {
      id: `doc-${Date.now()}`,
      name,
      type,
      size,
      folder,
      tags,
      pinned: false,
      recent: true,
      content,
      updatedAt: "Just now"
    };
    setDocuments((prev) => [newDoc, ...prev]);
    setTerminalLogs((prev) => [
      ...prev,
      `[${new Date().toLocaleTimeString()}] Created document: ${name} inside folder /${folder}.`
    ]);
  };

  return (
    <WorkspaceContext.Provider
      value={{
        activeView,
        setActiveView,
        sidebarCollapsed,
        setSidebarCollapsed,
        activeWorkspace,
        setActiveWorkspace,
        activeModel,
        setActiveModel,
        theme,
        setTheme,
        prompt,
        setPrompt,
        
        agents,
        tasks,
        documents,
        plugins,
        models,
        terminalLogs,
        isExecuting,
        chatMessages,
        
        apiKeys,
        setApiKeys,
        fastApiUrl,
        setFastApiUrl,
        
        runPrompt,
        sendChatMessage,
        togglePlugin,
        addDocument,
        clearLogs
      }}
    >
      {children}
    </WorkspaceContext.Provider>
  );
}

export function useWorkspace() {
  const context = useContext(WorkspaceContext);
  if (!context) {
    throw new Error("useWorkspace must be used within a WorkspaceProvider");
  }
  return context;
}
