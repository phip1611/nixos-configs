# Quick and Dirty Makefile. Not following best practices.

CFLAGS = -m64 -ffreestanding -nostdlib -O3 \
         -pedantic -Wall -Wshadow -Wpointer-arith -Wcast-qual \
         -Wstrict-prototypes -Wmissing-prototypes \
         -static -mcmodel=large \
         -Isrc/include \
         -T src/link.lds

.PHONY: default
default: build

.PHONY: build
build: build/kernel.elf64 build/kernel.elf32

build/kernel.elf64: src/kernel.S src/link.lds src/include
	mkdir -p build
	gcc $(CFLAGS) -o $@ src/kernel.S
	grub-file --is-x86-multiboot $@
	grub-file --is-x86-multiboot2 $@
	grub-file --is-x86-xen-dom0 $@
	strip $@

build/kernel.elf32: build/kernel.elf64
	objcopy $< -O elf32-i386 $@


.PHONY: run
run: build/kernel.elf32
	qemu-system-x86_64 -debugcon stdio -kernel build/kernel.elf32

.PHONY: clean
clean:
	rm -rf build
