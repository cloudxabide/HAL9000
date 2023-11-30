# HAL9000

My journey with AI involves many different facets.  I called the repo ["HAL9000"](https://en.wikipedia.org/wiki/HAL_9000) as homage to 2001: A Space Odyssey - which was probably the first time I had been exposed to "AI" or any sort of computer that functioned like a human.  

* Infrastructure
* Machine Learning Operations (MLOps)
* Cost-Optimization
* Data Science (something I have experience with, but will have to become more familiar)

## Ollama
[Ollama](./Ollama.md) details some of my experience runnign Ollama using Docker  

The following are references I had used:  
[Ollama](https://ollama.ai/)  
https://hub.docker.com/r/ollama/ollama

The effort needed to get Ollama up and running as a container was amazingly simple.  They did a tremendous job there.  
Implementing a front-end for it, has been a different story.  Running the LLM and webUI on the same host, and then accessing it from that host, is relatively straight-forward.  Sharing the LLM/webUI on your local - still fairly easy.  
Sharing it "to the world" - not so much.
