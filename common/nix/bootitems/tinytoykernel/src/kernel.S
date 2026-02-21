/**
 * This file uses GNU as assembly with AT&T syntax.
 *
 * Source code of tinykernel. All the code is relocatable and doesn't reference
 * anything by a link address. Because of that, it looks a little ugly. But we
 * can be relocatable and have 32-bit and 64-bit entries in the same file.
 */

#include "elfnote.h"

ELFNOTE(xen_pvh, Xen, 18 /* XEN_ELFNOTE_PHYS32_ENTRY  */, .long entry_32_xen)

.balign 8
.section .hdr.multiboot1, "a", @progbits
multiboot1_hdr: .long   0x1badb002
                .long   0x0
                .long  -0x1badb002

.balign 8
.section .hdr.multiboot2, "a", @progbits
multiboot2_hdr: .long   0xe85250d6
                .long   0x0
                .long   (multiboot2_hdr_end - multiboot2_hdr)
                .long  -(0xe85250d6 + (multiboot2_hdr_end - multiboot2_hdr))
                /* Entry address tag. */
                .balign 8
                /* i386 entry tag */
                .word   0x3 /* type */
                .word   0x0 /* flags */
                .long   0xc /* size */
                .long   entry_32_mb2 /* address */
                /* Boot service tag. Required by EFI AMD64 tag when using GRUB. */
                .balign 8
                .word   0x7 /* type */
                .word   0x1 /* flags */
                .long   0x8 /* size */
                /* EFI AMD64 entry tag */
                .balign 8
                .word   0x9 /* type */
                .word   0x0 /* flags */
                .long   0xc /* size */
                .long   entry_64_mb2 /* address */
                /* relocatable tag */
                .balign 8
                .word   0xa /* type */
                .word   0x0 /* flags */
                .long   0x18 /* size */
                .long   0x800000 /* min: 8 MiB */
                .long   0xc0000000 /* max: 3 GiB */
                .long   0x1000 /* align: 4 K */
                .long   0 /* no preference */
                /* end tag */
                .balign 8
                .word   0x0 /* type */
                .word   0x0 /* flags */
                .long   0x8 /* size */
multiboot2_hdr_end:

.macro M_IO_OUT_U16  port byte
  movw    $\port,   %dx  # 2 byte
  movw    $\byte,   %ax  # 2 byte
  out     %ax,      %dx
.endm

.macro M_IO_OUT_U8  port byte
  movw    $\port,   %dx  # 2 byte
  movb    $\byte,   %al  # 1 byte
  out     %al,      %dx
.endm

/* Prints a character to the QEMU debugcon port (0xe9). */
.macro M_DEBUGCON_PRINT_BYTE byte
  M_IO_OUT_U8  0xe9 \byte
.endm

.macro M_PRINT_32_BIT
  M_DEBUGCON_PRINT_BYTE '3'
  M_DEBUGCON_PRINT_BYTE '2'
  M_DEBUGCON_PRINT_BYTE ' '
  M_DEBUGCON_PRINT_BYTE 'b'
  M_DEBUGCON_PRINT_BYTE 'i'
  M_DEBUGCON_PRINT_BYTE 't'
.endm

.macro M_PRINT_64_BIT
  M_DEBUGCON_PRINT_BYTE '6'
  M_DEBUGCON_PRINT_BYTE '4'
  M_DEBUGCON_PRINT_BYTE ' '
  M_DEBUGCON_PRINT_BYTE 'b'
  M_DEBUGCON_PRINT_BYTE 'i'
  M_DEBUGCON_PRINT_BYTE 't'
.endm

.macro M_PRINT_VIA
  M_DEBUGCON_PRINT_BYTE ' '
  M_DEBUGCON_PRINT_BYTE 'v'
  M_DEBUGCON_PRINT_BYTE 'i'
  M_DEBUGCON_PRINT_BYTE 'a'
  M_DEBUGCON_PRINT_BYTE ' '
.endm

.macro M_EXIT
  M_DEBUGCON_PRINT_BYTE '\n'
  /* Invoke QEMU shutdown device: https://wiki.osdev.org/Shutdown */
  M_IO_OUT_U16  0x604 0x2000
  /* Invoke Cloud Hypervisor shutdown device. */
  M_IO_OUT_U8  0x600 0x34
  cli
  hlt
  ud2
.endm

.section .text
.code32

.global entry_32_mb1
entry_32_mb1:
  M_PRINT_32_BIT
  M_PRINT_VIA
  M_DEBUGCON_PRINT_BYTE 'M'
  M_DEBUGCON_PRINT_BYTE 'B'
  M_DEBUGCON_PRINT_BYTE '1'
  M_EXIT

entry_32_mb2:
  M_PRINT_32_BIT
  M_PRINT_VIA
  M_DEBUGCON_PRINT_BYTE 'M'
  M_DEBUGCON_PRINT_BYTE 'B'
  M_DEBUGCON_PRINT_BYTE '2'
  M_EXIT

entry_32_xen:
  M_PRINT_32_BIT
  M_PRINT_VIA
  M_DEBUGCON_PRINT_BYTE 'X'
  M_DEBUGCON_PRINT_BYTE 'e'
  M_DEBUGCON_PRINT_BYTE 'n'
  M_DEBUGCON_PRINT_BYTE ' '
  M_DEBUGCON_PRINT_BYTE 'P'
  M_DEBUGCON_PRINT_BYTE 'V'
  M_DEBUGCON_PRINT_BYTE 'H'
  M_EXIT

.code64
entry_64_mb2:
  M_PRINT_64_BIT
  M_PRINT_VIA
  M_DEBUGCON_PRINT_BYTE 'M'
  M_DEBUGCON_PRINT_BYTE 'B'
  M_DEBUGCON_PRINT_BYTE '2'
  M_EXIT
