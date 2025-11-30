#!/bin/bash

# Setup script to pull required models on both Ollama instances
# Run this before running the performance tests

MAC_HOST="192.168.0.218"
PC_HOST="10.10.12.252"
OLLAMA_PORT="11434"

# Models to pull
MODELS=(
    "qwen:1.5b"
    "qwen:4b"
    "gemma:2b"
    "gemma:7b"
    "qwen2.5-coder:1.5b"
)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pull_model() {
    local host=$1
    local host_name=$2
    local model=$3

    echo -e "${CYAN}Pulling $model on $host_name...${NC}"

    # Trigger model pull via API
    response=$(curl -s -X POST "http://$host:$OLLAMA_PORT/api/pull" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$model\", \"stream\": false}" 2>/dev/null)

    if echo "$response" | grep -q "success"; then
        echo -e "${GREEN}✓ Successfully pulled $model on $host_name${NC}"
    else
        echo -e "${YELLOW}⚠ Check if $model pulled correctly on $host_name${NC}"
    fi
}

echo "This script will pull the required models on both Ollama instances."
echo "This may take some time depending on your network speed."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

echo -e "\n${CYAN}Pulling models on Mac ($MAC_HOST)...${NC}"
for model in "${MODELS[@]}"; do
    pull_model "$MAC_HOST" "Mac" "$model"
    sleep 1
done

echo -e "\n${CYAN}Pulling models on PC ($PC_HOST)...${NC}"
for model in "${MODELS[@]}"; do
    pull_model "$PC_HOST" "PC" "$model"
    sleep 1
done

echo -e "\n${GREEN}Model setup complete!${NC}"
echo "You can now run: ./ollama_performance_test.sh"
