PLATFORM=$(uname -s | tr A-Z a-z)
ARCH=$([[ $(uname -m) == arm64 ]] && echo arm64 || echo amd64)
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
HELM_VERSION=2.17.0
GOPATH=$(go env GOPATH)

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
esac
