; Int 19h - Boot Services
IRQ_19h:
    mov ax, 0x0040
    mov ds, ax
    mov word [ds:BDA_COLD_BOOT], 0x1234 ; set the cold boot flag to 0x1234

    ; clear the segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    jmp 0xffff:0x0000 ; jump to the reset vector

    ; if this fails, loop forever
    jmp $