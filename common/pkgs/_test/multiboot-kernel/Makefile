CFLAGS = -m64 -ffreestanding -nostdlib -O3 \
         -pedantic -Wall -Wshadow -Wpointer-arith -Wcast-qual \
         -Wstrict-prototypes -Wmissing-prototypes \
         -mcmodel=large \
         -T link.lds

.PHONY: default
default: build

.PHONY: build
build: kernel.elf64 kernel.elf32

kernel.elf64: kernel.S
	gcc $(CFLAGS) -o $@ $<
	grub-file --is-x86-multiboot kernel.elf64
	grub-file --is-x86-multiboot2 kernel.elf64
	strip $@

kernel.elf32: kernel.elf64
	objcopy kernel.elf64 -O elf32-i386 $@
	grub-file --is-x86-multiboot kernel.elf32
	grub-file --is-x86-multiboot2 kernel.elf32

.PHONY: clean
clean:
	rm -f kernel.elf32 kernel.elf64
