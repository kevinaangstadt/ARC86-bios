; BIOS interrupt handlers

IRQ_halt:
  ; halt the CPU
  hlt
  jmp IRQ_halt

IRQ_nop:
  ; do nothing
  iret

IRQ_timer:
  ; backup ax
  push ax
  ; backup ds
  push ds

  ; set ds to BDA
  mov ax, 0x0040
  mov ds, ax
  
  ; dec the timer count
  dec byte [ds:BDA_TIMER_COUNT]
  ; check if the timer count is 0
  cmp byte [ds:BDA_TIMER_COUNT], 0
  ; if not, return
  jne .done

  ; reset the timer count (61 Hz)
  mov byte [ds:BDA_TIMER_COUNT], 61

  ; increment the clock by 1
  inc word [ds:BDA_CLK]

  ; check if there was a carry
  jnz .done

  ; there was a carry, increment the second
  inc word [ds:BDA_CLK + 2]

  ; check if there was a carry
  jnz .done

  ; increment the rollover
  inc byte [ds:BDA_CLK_Rollover]

.done:
  ; restore ds
  pop ds
  ; restore ax
  pop ax
  ; return from interrupt
  iret

IRQ_text:
  ; backup ax
  push ax
  ; backup dx
  push dx
  ; backup di
  push di
  ; backup ds
  push ds
  ; set ds to BDA
  mov ax, 0x0040
  mov ds, ax

  ; read the interrupt identification register
  mov dx, UART_IIR
  in al, dx

  ; check if the interrupt is for reading data
  and al, 0b00001110
  cmp al, 0b00000010

  ; if equal, this was a line status error
  je .done

  ; set the destinatino to the tail
  mov di, BDA_KB_BUFFER_TL

.read:
  ; check if there is space in the keyboard buffer
  mov al, [ds:BDA_KB_BUFFER_SIZE]
  cmp al, KB_BUFFER_SIZE
  jge .done

  ; there is space in the buffer

  ; check if there is data in the uart buffer
  mov dx, UART_LSR
  in al, dx
  and al, 0b00000001
  cmp al, 0
  je .done

  ; there is data in the buffer

  ; read the character from the uart buffer
  mov dx, UART_DATA
  in al, dx

  ; write the character to the keyboard buffer
  stosb

  ; increment the buffer size
  inc byte [ds:BDA_KB_BUFFER_SIZE]

  ; check if TL needs to wrap around
  cmp di, KB_BUFFER_SIZE + BDA_KB_BUFFER
  jb .read

  ; wrap around
  mov di, BDA_KB_BUFFER 

.done:
  ; restore ds
  pop ds
  ; restore di
  pop di
  ; restore dx
  pop dx
  ; restore ax
  pop ax
  ; return from interrupt
  iret


; IRQ 5 will be temporary to test the UART
IRQ_5h:
  ; print a string
  ; start of string in ax

  call fn_uart_print_str
  iret

; IRQ 10h video service
IRQ_10h:
  ; back up ds, es, ss, bx, cx, dx
  push ds
  push es
  push ss
  push bx
  push cx
  push dx

  ; compare ah for the function
  ; TODO support more features
  cmp ah, 0x0E ; check for teletype output
  jne .done

  ; TTY output function
  ; AH = 0E
	; AL = ASCII character to write
	; BH = page number (text modes)
	; BL = foreground pixel color (graphics modes)
  call fn_uart_print_char ; call the UART print character function
  jmp .done

.done:
  ; restore ds, es, ss, bx, cx, dx
  pop dx
  pop cx
  pop bx
  pop ss
  pop es
  pop ds
  ; return from interrupt
  iret

; Int 13h - Disk Services
IRQ_13h:
  ; back up DS, BX, CX, and DX
  push ds
  push bx
  push cx
  push dx

  cmp ah, 0x02 ; check for read sector function
  jne .done ; if not read sector, return
  ; AH = 02 - Read sectors from disk
  ; AL = number of sectors to read
  ; CH = cylinder number
  ; CL = sector number (1-63)
  ; DH = head number (0-1 for floppy)
  ; DL = drive number (0 for floppy, 0x80 for hard disk)

  ; set up an IDE read operation
  ; move sector count into CFREG2
  push ax
  push dx
  mov dx, CFREG2 ; this is where we will store the sector count
  out dx, al ; send the number of sectors to read

  ; starting sector
  push cx 
  mov dx, CFREG3 ; this is where we will store the starting sector
  and cl, 0x3F ; mask out the sector number (1-63)
  mov al, cl ; move the sector number into AL
  out dx, al ; send the sector number to CFREG2
  pop cx ; restore CX

  ; cylinder number
  mov dx, CFREG4 ; this is where we will store the cylinder number
  ; CH contains the cylinder number
  mov al, ch ; move the cylinder number into AL
  out dx, al ; send the cylinder number to CFREG4

  ; cylinder high
  push cx
  mov dx, CFREG5 ; this is where we will store the high byte of the cylinder number
  ; upper 2 bits of cl contain the high byte of the cylinder number
  mov al, cl ; move the high byte of the cylinder number into AL
  mov cx, 6
  shr al, cl ; shift right to get the high byte
  pop cx 

  ; set up drive head, drive, and CHS values
  ; move the head number into CFREG6
  pop dx ; restore drive info
  mov al, dh ; move the head number into AL
  and al, 0x0F ; mask out the upper bits
  or al, 0b10100000 ; set drive number, CHS mode
  out dx, al ; send the head number to CFREG6

  ; now we need to read the sectors from the disk
  ; set the read command
  mov dx, CFREG7
  mov al, 0x20
  out dx, al

  ; wait for the CF card to be ready
  call CFWaitReady
  call CFCheckError

  ; ES:BX contains the buffer to read the data into
  ; we need it to be DS:DI for the read function
  ; set DS to the buffer segment
  mov ax, es
  mov ds, ax

  push di ; save DI to restore later
  mov di, bx ; set DI to the buffer address in BX

  ; read the data
  call CFRead

  pop di ; restore DI

  call CFCheckError

  ; FIXME do actual error checking
  ; set up return values
  pop ax
  xor ah, ah ; clear AH for success
  ; set carry flag to 0
  clc ; clear carry flag to indicate success
  

.done:
  ; restore DS, BX, CX, and DX
  pop dx
  pop cx
  pop bx
  pop ds
  ; return from interrupt
  iret
