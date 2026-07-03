#!/bin/bash
# Start script for Niranjan AI Hermes backend

echo "Installing backend dependencies from requirements.txt..."
pip install -r requirements.txt

echo "Booting FastAPI server on port 8000..."
uvicorn main:app --reload --host 127.0.0.1 --port 8000
