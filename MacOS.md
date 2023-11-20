# MacOS


Exploring options for running AI Workloads on my M2 Mac
Docker with Linux can be tricky, but working with Docker + MacOS is proving rather tricky, and fairly annoying.  (Bind mounts are my current struggle.  Not a fan of having to run Docker Desktop, instead of just plain ol' Docker.  Ugh)


```
mkdir ${HOME}/work
```

```
docker container run --name jupyter -p 8888:8888 -v /Users/jradtke/work:/home/joyvan/ jupyter/base-notebook
```

```
docker exec -it <containerID> /bin/bash
# ls -l
# exit
```

NOTES:
* When you start the container, it *should* display 2 x URL to access the lab (IPv4 and IPv6).  You *may* have to replace 127.0.0.1 with "localhost"
* To get the IP of your container, run docker ps to get the container id.  Then 
``` 
docker inspect <containerID> | grep IPAddress
docker rm $(docker ps -a | grep Exit | awk '{ print $1 }')
``` 


This would appear like a logical approach.  It fails to address the fact that Docker does not actually run on MacOS, and instead runs a Virtual Machine.  I'm not a fan at this point - as I cannot figure how Docker intended you to interact, directly, with the filesystem.  I will admit tht my use-case may be unorthodox - I want to have Jupyter running (in Docker) and manipulate files via my MacOS Terminal.  Meh?
```
cd ${HOME}/Docker
docker container run --name jupyter -p 8888:8888 -v $(pwd):/home/joyvan/work/ jupyter/base-notebook
```
