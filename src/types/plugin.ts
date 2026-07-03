export interface PluginItem {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  enabled: boolean;
  health: "healthy" | "warning" | "critical";
  installedVersion: string;
  capabilities: string[];
}

export interface PluginMetadata {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  health: "healthy" | "warning" | "critical";
}

export interface PluginContext {
  activeModel: string;
  workspaceName: string;
  log: (message: string) => void;
  callApi: (service: string, endpoint: string, params: any) => Promise<any>;
}

export interface NiranjanPlugin {
  metadata: PluginMetadata;
  settings: Record<string, any>;
  
  enable(context: PluginContext): Promise<void>;
  disable(context: PluginContext): Promise<void>;
  execute(params: Record<string, any>, context: PluginContext): Promise<Record<string, any>>;
}
