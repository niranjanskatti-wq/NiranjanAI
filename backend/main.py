from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import time
import uuid

app = FastAPI(title="Niranjan AI Hermes Gateway", version="0.1")

# CORS configurations
origins = [
    "http://localhost:3000",
    "http://localhost:3001",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:3001",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class PromptRequest(BaseModel):
  prompt: str

class ExecuteResponse(BaseModel):
  status: str
  message: str
  response: str
  taskId: str
  logs: list[str]
  executionTime: str

class HealthResponse(BaseModel):
  status: str
  version: str
  agent: str
  uptime: float

start_time = time.time()

@app.get("/health", response_model=HealthResponse)
async def health():
  return {
    "status": "online",
    "version": "0.1",
    "agent": "Hermes",
    "uptime": time.time() - start_time
  }

@app.post("/execute", response_model=ExecuteResponse)
async def execute(request: PromptRequest):
  # Simulate execution times
  exec_id = f"task-{uuid.uuid4().hex[:8]}"
  return {
    "status": "success",
    "message": "Hermes received task",
    "response": "Hermes received task",
    "taskId": exec_id,
    "logs": [
      "Initializing workspace...",
      "Executing request against agent network..."
    ],
    "executionTime": "0.2s"
  }
