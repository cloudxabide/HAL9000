# HAL9000

My journey with AI involves many different facets.  I called the repo ["HAL9000"](https://en.wikipedia.org/wiki/HAL_9000) as homage to 2001: A Space Odyssey - which was probably the first time I had been exposed to "AI" or any sort of computer that functioned like a human.  

* Infrastructure
* Machine Learning Operations (MLOps)
* Cost-Optimization
* Data Science (something I have experience with, but will have to become more familiar)

## Ollama
The following doc on [Ollama](./Ollama.md) details some of my experience runnign Ollama using Docker and the technical implementation steps.  

The following are references I had used:  
[Ollama](https://ollama.ai/)  
https://hub.docker.com/r/ollama/ollama

The effort needed to get Ollama up and running as a container was amazingly simple.  They did a tremendous job there.  
Deploying an implementation of a front-end for it, has been a different story.  Running the LLM and webUI on the same host, and then accessing it from that host, is relatively straight-forward.  Sharing the LLM/webUI on your local network - still fairly easy.  
Sharing it "to the world" - not so much.  I recognize the inherent risk in doing this (as there is not Authentication built in to this solution).  I am, however, interested in how sharing an LLM outside of my network would be done.

