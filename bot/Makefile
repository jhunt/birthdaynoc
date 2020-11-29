IMAGE_NAME ?= iamjameshunt/bdaynoc-bot

build:
	docker build -t $(IMAGE_NAME) .

push: build
	docker push $(IMAGE_NAME)
