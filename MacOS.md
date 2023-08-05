# MacOS


Exploring options for running AI Workloads on my M2 Mac

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
``` 

