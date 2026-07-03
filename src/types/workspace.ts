export type ViewType =
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

export interface ChatMessage {
  id: string;
  sender: "user" | "assistant";
  text: string;
  timestamp: string;
  codeBlock?: string;
  codeLanguage?: string;
}

export interface WorkspacePreferences {
  theme: "dark" | "light" | "midnight";
  sidebarCollapsed: boolean;
  activeWorkspace: string;
  activeModel: string;
}
