build:
	make -C bot build
	make -C writer build

push:
	make -C bot push
	make -C writer push
