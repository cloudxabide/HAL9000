# HAL9000

My journey with AI involves many different facets.  I called the repo ["HAL9000"](https://en.wikipedia.org/wiki/HAL_9000) as homage to 2001: A Space Odyssey - which was probably the first time I had been exposed to "AI" or any sort of computer that functioned like a human.  

My objectives are typically focused on the "how" to run an LLM, and less on "what" to do with the LLM, at this time.  I will look at how doing this on my own hardware, etc.. compares to using a managed service.  (This is not a fair comparison, as I will be looking at one aspect of a complete ecosystem  - running a model or three vs. Amazon Sagemaker, Bedrock, EMR, PartyRock, etc...)

* Cost-Optimization
* Infrastructure
* Machine Learning Operations (MLOps)
* Data Engineering 
* Data Science (something I have experience with, but will have to become more familiar)

## Ollama
The following doc on my [Ollama Experience](./Ollama.md) details some of my experience runnign Ollama using Docker and the technical implementation steps.  

The following are references I had used:  
[Ollama](https://ollama.ai/)  
https://hub.docker.com/r/ollama/ollama

The effort needed to get Ollama up and running as a container was amazingly simple.  They did a tremendous job there.  
Deploying an implementation of a front-end for it, has been a different story.  Running the LLM and webUI on the same host, and then accessing it from that host, is relatively straight-forward.  Sharing the LLM/webUI on your local network - still fairly easy.  
Sharing it "to the world" - not so much.  I recognize the inherent risk in doing this (as there is not Authentication built in to this solution).  I am, however, interested in how sharing an LLM outside of my network would be done.

