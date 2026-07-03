// Database Interface Layer - Repository Pattern for Niranjan AI
// Ready to switch from local memory to SQLite/PostgreSQL/MongoDB

import { Task, DocumentItem, PluginItem, ModelItem, Agent } from "@/lib/api";

export interface DatabaseRepository {
  // Tasks
  getTasks(): Promise<Task[]>;
  saveTask(task: Task): Promise<void>;
  deleteTask(id: string): Promise<void>;

  // Documents
  getDocuments(): Promise<DocumentItem[]>;
  saveDocument(doc: DocumentItem): Promise<void>;
  deleteDocument(id: string): Promise<void>;

  // Settings
  getTheme(): Promise<string>;
  saveTheme(theme: string): Promise<void>;
}

// Memory Database Implementation (Client/Frontend Sandbox)
export class MockDatabaseRepository implements DatabaseRepository {
  private tasks: Map<string, Task> = new Map();
  private documents: Map<string, DocumentItem> = new Map();
  private activeTheme: string = "dark";

  constructor() {
    // Populate with mock data from API layer
    // For local memory operations
  }

  async getTasks(): Promise<Task[]> {
    return Array.from(this.tasks.values());
  }

  async saveTask(task: Task): Promise<void> {
    this.tasks.set(task.id, task);
  }

  async deleteTask(id: string): Promise<void> {
    this.tasks.delete(id);
  }

  async getDocuments(): Promise<DocumentItem[]> {
    return Array.from(this.documents.values());
  }

  async saveDocument(doc: DocumentItem): Promise<void> {
    this.documents.set(doc.id, doc);
  }

  async deleteDocument(id: string): Promise<void> {
    this.documents.delete(id);
  }

  async getTheme(): Promise<string> {
    return this.activeTheme;
  }

  async saveTheme(theme: string): Promise<void> {
    this.activeTheme = theme;
  }
}
