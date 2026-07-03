# Niranjan AI Hermes Backend Gateway

This is the FastAPI backend gateway for the **Niranjan AI** operating system.

## Setup Instructions

1. Ensure you have Python 3.9+ installed on your system.
2. Open a terminal and navigate to the backend folder:
   ```bash
   cd backend
   ```
3. Run the startup script (which will install requirements and boot uvicorn):
   ```bash
   ./start.sh
   ```

Or run manually:
```bash
pip install -r requirements.txt
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

## API Endpoints

- **GET `/health`**: Returns system status, version, and agent information.
- **POST `/execute`**: Accepts task prompts and returns execution latency status.
