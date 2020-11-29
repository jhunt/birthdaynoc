N          ?= 1
IMAGE_NAME ?= iamjameshunt/bdaynoc-writer

build:
	docker build -t $(IMAGE_NAME) .

push: build
	docker push $(IMAGE_NAME)

examples: build
	docker run --rm -i $(IMAGE_NAME) bin/genall < examples/bdaynoc.g \
	  network a.b.c.d/m mask /24 n 256 age 15 mm 01 dd 14 location somewhere
example: build
	docker run --rm -i $(IMAGE_NAME) bin/generate $(N) < examples/bdaynoc.g \
	  network a.b.c.d/m mask /24 n 256 age 15 mm 01 dd 14 location somewhere

test:
	docker build -t $(IMAGE_NAME):test -f Dockerfile.test .
	docker run --rm -v $(PWD)/t:/app/t \
	  $(IMAGE_NAME):test prove -lv t/*.t
