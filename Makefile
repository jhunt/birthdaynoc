build:
	make -C bot build
	make -C writer build

push:
	make -C bot push
	make -C writer push

rewrite:
	k delete -f k8s/write.yml
	k apply  -f k8s/write.yml
	sleep 1
	k -n bdaynoc logs -f job/write
