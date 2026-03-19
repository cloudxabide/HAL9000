# DGX to Mac model sync.

Assumptions:

running Ollama "natively" on your mac
running Ollama as a container on your DGX


This is how I start my docker container to run ollam (and openwebui)
```
    docker run -d \
      -p 12000:8080 \
      -p 11434:11434 \
      --gpus=all \
      -v open-webui:/app/backend/data \
      -v open-webui-ollama:/root/.ollama \
      -e OLLAMA_HOST=0.0.0.0:11434 \
      --name "${NAME}" \
      "${IMAGE}" >/dev/null
```

Investigate the local filesystem that is mounted in container
```
root@spark-e:~# docker volume inspect open-webui-ollama
[
    {
        "CreatedAt": "2025-12-04T21:27:52-05:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/open-webui-ollama/_data",
        "Name": "open-webui-ollama",
        "Options": null,
        "Scope": "local"
    }
]
```

On mac - figure out what the Ollama directory looks like
```
glados:.ollama jradtke$ ls -l ~/.ollama/
total 16
drwxr-xr-x@ 95 jradtke  staff  3040 Mar 18 20:45 blobs
-rw-------@  1 jradtke  staff   387 Mar 17 22:12 id_ed25519
-rw-r--r--@  1 jradtke  staff    81 Mar 17 22:12 id_ed25519.pub
drwxr-xr-x@ 14 jradtke  staff   448 Mar 18 20:36 logs
drwxr-xr-x@  3 jradtke  staff    96 Mar 18 20:45 manifests
```

on DGX - also figure out what the Ollama directory looks like
```
root@spark-e:~# ls -l /var/lib/docker/volumes/open-webui-ollama/_data
total 16
-rw------- 1 root root   97 Mar 15 17:26 history
-rw------- 1 root root  387 Dec  4 21:27 id_ed25519
-rw-r--r-- 1 root root   81 Dec  4 21:27 id_ed25519.pub
drwxr-xr-x 4 root root 4096 Dec  4 21:28 models
```

# More comparison
```
root@spark-e:~# ls -l /var/lib/docker/volumes/open-webui-ollama/_data/models
total 20
drwxr-xr-x 2 root root 16384 Mar 15 17:26 blobs
drwxr-xr-x 3 root root  4096 Dec  4 21:32 manifests
```

## NEED TO TEST THIS
```
rsync -tugrpolvv root@10.10.12.251:/var/lib/docker/volumes/open-webui-ollama/_data/models/blobs/ ~/.ollama/blobs/
rsync -tugrpolvv root@10.10.12.251:/var/lib/docker/volumes/open-webui-ollama/_data/models/manifests/ ~/.ollama/manifests/
```


