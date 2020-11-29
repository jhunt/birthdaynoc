N          ?= 1
IMAGE_NAME ?= iamjameshunt/bdaynoc-writer

build:
	docker build -t $(IMAGE_NAME) .

push: build
	docker push $(IMAGE_NAME)

examples: build
	docker run --rm -i $(IMAGE_NAME) bin/genall < examples/bdaynoc.g \
	  subnet a.b.c.d/m n 25 years 15 location somewhere
example: build
	docker run --rm -i $(IMAGE_NAME) bin/generate $(N) < examples/bdaynoc.g \
	  subnet a.b.c.d/m n 25 years 15 location somewhere

test:
	docker build -t $(IMAGE_NAME):test -f Dockerfile.test .
	docker run --rm -v $(PWD)/t:/app/t \
	  $(IMAGE_NAME):test prove -lv t/*.t
