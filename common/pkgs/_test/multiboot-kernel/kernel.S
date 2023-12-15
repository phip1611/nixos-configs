/*
 * Test kernel that is bootable via Multiboot 1 and Multiboot 2.
 * It prints to the QEMU debugcon device over which method it is booted.
 * If booted in QEMU, the kernel shuts down the VMM automatically.
 *
 * As GRUB cannot really downgrade to 32-bit when booting a Multiboot 2 kernel
 * in a x86_64 EFI system, this kernel provides multiple entries:
 * - Multiboot1 entry in protected 32-bit mode
 * - Multiboot2 entry in protected 32-bit mode
 * - Multiboot2 entry in 64-bit mode long mode (EFI only)
 */

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
                .balign 8
                /* Boot service tag. Required by EFI AMD64 tag. */
                .word   0x7 /* type */
                .word   0x0 /* flags */
                .long   0x8 /* size */
                .balign 8
                /* EFI AMD64 entry tag */
                .word   0x9 /* type */
                .word   0x0 /* flags */
                .long   0xc /* size */
                .long   entry_64 /* address */
                .balign 8
                /* relocatable tag */
                .word   0xa /* type */
                .word   0x0 /* flags */
                .long   0x18 /* size */
                .long   0x800000 /* min: 8 MiB */
                .long   0xc0000000 /* max: 3 GiB */
                .long   0x1000 /* align: 4 K */
                .long   0 /* no preference */
                .balign 8
                /* end tag */
                .word   0x0 /* type */
                .word   0x0 /* flags */
                .long   0x8 /* size */
multiboot2_hdr_end:

# Prints a character to the QEMU debugcon port.
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

# Prints a character to the QEMU debugcon port (0xe9).
.macro M_DEBUGCON_PRINT_BYTE byte
  M_IO_OUT_U8  0xe9 \byte
.endm

# Code as macro, so that it can be used as template for 32-bit and 64-bit code.
.macro M_PRINT_MODE mode
    .if \mode == 32
      M_DEBUGCON_PRINT_BYTE '3'
      M_DEBUGCON_PRINT_BYTE '2'
    .endif
    .if \mode == 64
      M_DEBUGCON_PRINT_BYTE '6'
      M_DEBUGCON_PRINT_BYTE '4'
    .endif

    M_DEBUGCON_PRINT_BYTE 'b'
    M_DEBUGCON_PRINT_BYTE 'i'
    M_DEBUGCON_PRINT_BYTE 't'
.endm

.macro M_PRINT_MB_VERSION
  cmp  $0x2badb002, %eax  # Multiboot1 magic
  jne  1f
  M_DEBUGCON_PRINT_BYTE 'm'
  M_DEBUGCON_PRINT_BYTE 'b'
  M_DEBUGCON_PRINT_BYTE '1'
  jmp 3f
  1:
  cmp  $0x36d76289, %eax  # Multiboot2 magic
  jne  2f
  M_DEBUGCON_PRINT_BYTE 'm'
  M_DEBUGCON_PRINT_BYTE 'b'
  M_DEBUGCON_PRINT_BYTE '2'
  jmp 3f
  2:
  M_DEBUGCON_PRINT_BYTE 'n'
  M_DEBUGCON_PRINT_BYTE 'o'
  M_DEBUGCON_PRINT_BYTE ' '
  M_DEBUGCON_PRINT_BYTE 'm'
  M_DEBUGCON_PRINT_BYTE 'b'
  3:
.endm

.macro M_DONE
  # Invoke QEMU shutdown device
  # https://wiki.osdev.org/Shutdown
  M_IO_OUT_U16  0x604 0x2000
  cli
  hlt
  ud2
.endm

.macro M_MAIN mode
  M_PRINT_MB_VERSION
  M_DEBUGCON_PRINT_BYTE ' '
  M_PRINT_MODE \mode
  M_DEBUGCON_PRINT_BYTE '\n'
  M_DONE
.endm

.section .text
.code32

.global entry_32
entry_32:
  M_MAIN 32

.code64
entry_64:
  M_MAIN 64
