#!/usr/bin/env bash
# Initialize Ollama: inject corporate CA certs (ZScaler) and pull the default model

set -euo pipefail

MODEL="${OLLAMA_MODEL:-qwen3:0.6b}"

# Inject ZScaler CA cert into the container if running on macOS with ZScaler
if command -v security &>/dev/null; then
  ZSCALER_CERT=$(security find-certificate -a -c "Zscaler" -p /Library/Keychains/System.keychain 2>/dev/null || true)
  if [ -n "$ZSCALER_CERT" ]; then
    echo "Injecting ZScaler CA cert into Ollama container..."
    echo "$ZSCALER_CERT" | docker compose exec -T ollama tee /usr/local/share/ca-certificates/zscaler.crt > /dev/null
    docker compose exec ollama update-ca-certificates 2>/dev/null
    docker compose restart ollama > /dev/null 2>&1
    echo "  Waiting for Ollama to restart..."
    sleep 3
    until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do sleep 1; done
    echo "  ✓ ZScaler CA injected"
  fi
fi

# Pull model
echo "Pulling Ollama model: ${MODEL}..."
if docker compose exec ollama ollama pull "$MODEL" 2>/dev/null; then
  echo "  ✓ Model ${MODEL} ready"
else
  echo "  WARN: Could not pull model. Pull manually: docker compose exec ollama ollama pull ${MODEL}"
fi
