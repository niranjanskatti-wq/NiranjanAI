export const DEFAULT_API_URLS = {
  FASTAPI: "http://127.0.0.1:8000",
  OLLAMA: "http://localhost:11434",
  OPENROUTER: "https://openrouter.ai/api/v1"
};

export const THEMES = {
  OBSIDIAN: "dark",
  MIDNIGHT: "midnight",
  LIGHT: "light"
} as const;

export const KEYBOARD_SHORTCUTS = [
  { key: "⌘ K", description: "Global Search" },
  { key: "⌘ Enter", description: "Run Prompt" },
  { key: "⌘ B", description: "Toggle Sidebar" },
  { key: "⌘ /", description: "Help" },
  { key: "ESC", description: "Close Modals" }
];
