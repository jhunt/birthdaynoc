writer:
	docker build -t bdaynoc/writer .

examples: writer
	docker run --rm -i bdaynoc/writer bin/genall < examples/bdaynoc.g \
	  subnet a.b.c.d/m n 25 years 15 location somewhere
