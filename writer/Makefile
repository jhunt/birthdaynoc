writer:
	docker build -t bdaynoc/writer .

examples: writer
	docker run --rm -i bdaynoc/writer bin/genall < examples/bdaynoc.g \
	  subnet a.b.c.d/m n 25 years 15 location somewhere

test:
	docker build -t bdaynoc/writer:test -f Dockerfile.test .
	docker run --rm -v $(PWD)/t:/app/t \
	  bdaynoc/writer:test prove -lv t/*.t
