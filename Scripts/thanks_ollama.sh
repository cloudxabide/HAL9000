#!/bin/bash
 
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
    docker stop ollama open-webui 2>/dev/null
    docker rm ollama open-webui 2>/dev/null
    echo "Exiting program"
    exit 0
}

start() {
# Run Ollama container
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama

# Run the specified model
docker exec -it ollama ollama run "$MODEL_NAME"

# Run Open WebUI container
docker run --detach \
  --publish 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  --volume open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
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
            docker ps -a | grep ollama
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
