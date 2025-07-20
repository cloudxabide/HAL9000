#!/bin/bash

# Purpose:  a script that runs commands I would often have to run to invoke LLMs on my local machine
 
# Set default model name
MODEL_NAME="llama3"

usage() {
echo "
# Use default model
$0 

# Specify custom model
$0 -m mistral
$0--model-name phi3

# Stop Containers
$0 [-k|--kill]
"
}

## TODO - probably should add logic here to determine whether the containers
##        are already running, and if they are, ask if we should restart them

# Handle container termination and removal 
kill() {
    echo "Stop and remove existing containers"
    echo "Stopping..."
    docker stop ollama open-webui 2>/dev/null
    echo "Removing..."
    docker rm ollama open-webui 2>/dev/null
    echo "Exiting program"
    exit 0
}

start() {
echo "Starting Ollama and Open-WebUI containers"

# Run Ollama container
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama && echo "Ollama started" || echo "Error: Ollama did not start"

# Run the specified model (this is only necessary if you want to run from CLI)
# docker exec -it ollama ollama run "$MODEL_NAME" && echo "$MODEL_NAME has bee added."
# docker exec -it ollama ollama run qwen:4b

# Run Open WebUI container
docker run --detach \
  --publish 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  --volume open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main && echo "Open-WebUI container start initiated." || echo "Error: Open-WebUI did not start."

while sleep 2; do echo "Waiting for Open-WebUI to start" ; docker ps -a | grep "(healthy)" && break; done
}

# Parse command-line arguments
if [[ $# -eq 0 ]]; then
    start
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model-name)
            MODEL_NAME="$2"
            start
            shift 2
            ;;
        -k|--kill)
            kill
            usage
            ;;
        -s|--status)
            clear
            docker ps -a | egrep '^CONTAINER|ollama|open-webui'
            echo ""
            nvidia-smi
            shift
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done
