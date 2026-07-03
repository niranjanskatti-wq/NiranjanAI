import { Task } from "./task";

export interface APIGatewayResponse<T = any> {
  data: T;
  status: "success" | "error";
  error?: {
    code: string;
    message: string;
  };
}

export interface PromptExecutionRequest {
  prompt: string;
  model: string;
  stream: boolean;
}

export interface PromptExecutionResponse {
  taskId: string;
  status: Task["status"];
  logs: string[];
}
