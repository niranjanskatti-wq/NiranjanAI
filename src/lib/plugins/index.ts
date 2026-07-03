// Plugin SDK for Niranjan AI Workspace
// Exposes reusable interfaces that future plugins can implement

export interface PluginMetadata {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  health: 'healthy' | 'warning' | 'critical';
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

// Sample implementation mapping of a future plugin
export class ExampleIFZAPlugin implements NiranjanPlugin {
  metadata = {
    id: "ifza-agent",
    name: "IFZA Business License Agent",
    description: "Queries IFZA freezone setup fee structures and documentation steps.",
    version: "1.0.0",
    author: "Niranjan AI Dev",
    health: "healthy" as const
  };

  settings = {
    apiUrl: "https://api.ifza.ae/v1",
    retryAttempts: 3
  };

  async enable(context: PluginContext): Promise<void> {
    context.log("IFZA License Agent Plugin Enabled.");
  }

  async disable(context: PluginContext): Promise<void> {
    context.log("IFZA License Agent Plugin Disabled.");
  }

  async execute(params: Record<string, any>, context: PluginContext): Promise<Record<string, any>> {
    context.log("Running licensing eligibility queries...");
    const licenseType = params.licenseType || "Commercial";
    
    // Simulating API calculations
    return {
      status: "success",
      licenseType,
      feeAED: 11500,
      processingTime: "3 working days",
      requirements: ["Shareholder Passport Copy", "Business Plan Draft"]
    };
  }
}
