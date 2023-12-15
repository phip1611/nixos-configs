ENTRY(entry_32)

/*
 * FORMAT: It's hard to find the right names for this. Keyword: bfdname.
 * Also see GNU ld's source.
 */
OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH("i386:x86-64")

PHDRS
{
    kernel  PT_LOAD FLAGS(7); /* 0b111 - read + write + execute */
}

SECTIONS {

    .hdr 8M : AT(8M) ALIGN(4K)
    {
        KEEP(*(.hdr.multiboot1));
        KEEP(*(.hdr.multiboot2));
    } : kernel

    .text :
    {
        *(.text .text.*)
    } : kernel

    .rodata :
    {
        *(.rodata .rodata.*)
    } : kernel

    .data :
    {
        *(.data .data.*)
    } : kernel

    .bss :
    {
        *(COMMON)
        *(.bss .bss.*)
    } : kernel

    /DISCARD/ :
    {
        *(.note.*)
        *(.comment .comment.*)
        *(.eh_frame*)
        *(.got .got.*)
    }

}
