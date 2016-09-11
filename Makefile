all:
	$(MAKE) -C alpine

alpine/initrd.img.gz:
	$(MAKE) -C alpine initrd.img.gz

alpine/kernel/x86_64/vmlinuz64:
	$(MAKE) -C alpine/kernel x86_64/vmlinuz64

alpine/mobylinux-bios.iso:
	$(MAKE) -C alpine mobylinux-bios.iso

qemu: Dockerfile.qemu alpine/initrd.img.gz alpine/kernel/x86_64/vmlinuz64
	tar cf - $^ | docker build -f Dockerfile.qemu -t mobyqemu:build -
	docker run -it --rm mobyqemu:build

qemu-iso: Dockerfile.qemuiso alpine/mobylinux-bios.iso
	tar cf - $^ | docker build -f Dockerfile.qemuiso -t mobyqemuiso:build -
	docker run -it --rm mobyqemuiso:build

test: Dockerfile.test alpine/initrd.img.gz alpine/kernel/x86_64/vmlinuz64
	$(MAKE) -C alpine
	tar cf - $^ | docker build -f Dockerfile.test -t mobytest:build -
	touch test.log
	docker run --rm mobytest:build 2>&1 | tee -a test.log &
	tail -f test.log 2>/dev/null | grep -m 1 -q 'Moby test suite '
	cat test.log | grep -q 'Moby test suite PASSED'

.PHONY: clean

clean:
	$(MAKE) -C alpine clean
	docker images -q mobyqemu:build | xargs docker rmi -f || true
	docker images -q mobytest:build | xargs docker rmi -f || true
