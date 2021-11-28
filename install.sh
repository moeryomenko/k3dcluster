#!/usr/bin/env bash

PLATFORM=$(uname -s | tr A-Z a-z)
ARCH=$([[ $(uname -m) == arm64 ]] && echo arm64 || echo amd64)
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
HELM_VERSION=3.7.1
TKN_VERSION=0.21.0
GOPATH=$(go env GOPATH)
GL_PLATFORM=kubernetes
GL_OPERATOR_VERSION=0.2.0 # https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/releases

case $1 in
	"helm")
		mkdir helm && curl -SL https://get.helm.sh/helm-v${HELM_VERSION}-${PLATFORM}-${ARCH}.tar.gz | tar xz -C helm --strip-components=1
		mv helm/helm ${GOPATH}/bin
		rm -rf helm
		;;
	"kubectl")
		curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${PLATFORM}/${ARCH}/kubectl"
		curl -LO "https://dl.k8s.io/${KUBECTL_VERSION}/bin/${PLATFORM}/${ARCH}/kubectl.sha256"
		SUM=$(cat ./kubectl.sha256); echo "$$SUM kubectl" | sha256sum --check
		rm kubectl.sha256
		chmod +x kubectl
		mv kubectl ${GOPATH}/bin
		;;
	"tkn")
		curl -SL https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_`uname -s`_`uname -m`.tar.gz | tar -xz -C ${GOPATH}/bin
		;;
	"vm")
		helm repo add vm https://victoriametrics.github.io/helm-charts/
		helm repo update
		helm install operator vm/victoria-metrics-operator
		;;
	"netdata")
		helm repo add netdata https://netdata.github.io/helmchart/
		helm repo update
		helm install netdata netdata/netdata
		;;
	"cert-manager")
		helm repo add jetstack https://charts.jetstack.io
		helm repo update
		helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.2.0 --set installCRDs=true
		;;
	"gitlab")
		kubectl create namespace gitlab-system
		kubectl apply -f https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${GL_PLATFORM}-${GL_OPERATOR_VERSION}.yaml
		;;
	"argocd")
		curl -sSL -o ${GOPATH}/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-${PLATFORM}-${ARCH}
		chmod +x ${GOPATH}/bin/argocd
		kubectl create namespace argocd
		kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
		;;
	"tekton")
		echo "don't implemeted"
		;;
	"ambassador")
		helm repo add datawire https://app.getambassador.io
		helm repo update
		kubectl create namespace ambassador
		helm install --devel edge-stack --namespace ambassador datawire/edge-stack
		kubectl -n ambassador wait --for condition=available --timeout=90s deploy -lproduct=aes
		;;
	"chaos")
		helm repo add chaos-mesh https://charts.chaos-mesh.org
		helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-testing --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/k3s/containerd/containerd.sock --version 2.0.5
		;;
esac
