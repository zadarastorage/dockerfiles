PROJECT:=$(shell basename $(shell pwd))
REPO=`git config --get remote.origin.url 2>/dev/null || echo offline`
BRANCH=`git symbolic-ref --short -q HEAD 2>/dev/null || echo offline`
COMMIT=`git rev-parse --short HEAD 2>/dev/null || date +%s`

build:
	docker build -t ${PROJECT}_${COMMIT} .
	docker save --output ${PROJECT}_${COMMIT}.tar ${PROJECT}_${COMMIT}
