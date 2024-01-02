# Ollama Experience

These days, when I am trying to learn something, I find myself trending towards using containers rather than building a VM (or Baremetal in this case) and then installing "bits" in a VM.

## Assumptions

I cover these in other files/scripts in this repo:

* NVIDIA Drivers are already installed and functioning

## Clean up 

### Kill/Remove the pods
NOTE: This will kill and rm **ALL** containers on your node with "ollama" in the name. (which is fine for me - as this will be the only thing I am working on)
```
docker kill $(docker ps -a | grep ollama | awk '{ print $1 }' | grep -v CONTAINER)
docker rm $(docker ps -a | grep ollama | awk '{ print $1 }' | grep -v CONTAINER)
```

## Run the Ollama Server in a Docker Container
```
# docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
OLLAMA_ENV_FILE=${HOME}/ollama-env-file.txt
echo "OLLAMA_ORIGINS=\"http://10.10.10.20:*,http://hal9000.matrix.lab:*\"" > $OLLAMA_ENV_FILE
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --env-file=$OLLAMA_ENV_FILE --name ollama ollama/ollama
```

## Monitor the system
In a separate terminal, run the following
```
nvidia-smi -l 1
```

## User-Interfaces to utilize the LLM

### CLI interface
You can run your prompt in an ollama container itself
```
docker exec -it ollama ollama run llama2
```

### Ollama-webUI (container)
Source: https://github.com/ollama-webui/ollama-webui
```
# docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway --name ollama-webui --restart always ghcr.io/ollama-webui/ollama-webui:main
## Ubuntu
docker run -d -p 3000:8080 --name ollama-webui --restart always ghcr.io/ollama-webui/ollama-webui:main
google-chrome http://localhost:3000/
# MacOS 
docker run -it --platform linux/amd64 -d -p 3000:8080 -e OLLAMA_API_BASE_URL=http://10.10.10.20:11434/api --name ollama-webui --restart always ghcr.io/ollama-webui/ollama-webui:main
```

### Ollama-UI (local server)
NOTE:  I continued to have "CORS issues" which I am fairly aggravated by. (the output is somewhat ambiguous as to what component actually needs updating.  I'll revisit this project at some point - but, for now I am going to use something else.
```
cd
git clone https://github.com/ollama-ui/ollama-ui
cd ollama-ui
make
sudo ufw allow port 8000
# Now open the following:  http://localhost:8000 # in browser
```

### API test direct to Ollama Server endpoint
```
curl http://10.10.10.20:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "[INST] why is the sky blue? [/INST]",
  "raw": true,
  "stream": false
}'
```

### Kill/Remove the pods
NOTE: This will kill and rm **ALL** containers on your node. (which is fine for me - as this will be the only thing I am working on)
```
docker kill $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
docker rm $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
```

## Notes and troublshooting
I had run in to issues with CORS.  And while the seemed to point toward "ollama server" being the issue, any testing seemed to indicate that it was *not* the case.  I.e. a simple curl to the ollama endpoint seemed to work without issues.

```
docker ps -a
docker logs -f <docker id>
```

## References
https://ollama.ai/ => https://github.com/jmorganca/ollama  
https://hub.docker.com/r/ollama/ollama
