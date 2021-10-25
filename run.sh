#!/bin/bash

docker run -d --rm --name registry -p 5000:5000 \
	-e REGISTRY_PROXY_REMOTEURL="https://registry-1.docker.io" registry:2

export K3D_FIX_CGROUPV2=1
k3d cluster create dev --k3s-arg "--disable=traefik@server:0" \
	--registry-config "$(pwd)/registries.yaml" \
	--port 8080:80@loadbalancer --port 8443:443@loadbalancer \
	--image rancher/k3s:v1.22.2-k3s2-amd64 \
	--servers 1 --agents 3 # -v /dev/mapper:/dev/mapper
