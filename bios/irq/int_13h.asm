; Int 13h - Disk Services
IRQ_13h:
  ; back up DS, BX, CX, and DX
  push ds
  push bx
  push cx
  push dx
  push bp

  mov bp, sp

  ; TODO support more features
  cmp ah, .MAX_FUNCTION           ; check we are in bounds
  jae .unsupported_function       ; function not supported (out of range)

  ; get the function address from the function table
  mov si, ax                      ; move the function number into si
  and si, 0xFF00                  ; mask out the upper byte
  shr si, 1                       ; divide by 128 for table offset
  shr si, 1                       ; >> 7 (2 bytes)
  shr si, 1
  shr si, 1                       
  shr si, 1  
  shr si, 1                       
  shr si, 1                    
  jmp [cs:.function_table + si]   ; jump to the function

.fn_reset_disk:
  ; Function 00h - Reset disk
  call CFInit
  ; FIXME do actual error checking
  xor ah, ah                      ; clear AH for success
  jmp .success

.fn_read_sectors:
  ; AH = 02 - Read sectors from disk
  ; AL = number of sectors to read
  ; CH = cylinder number
  ; CL = sector number (1-63)
  ; DH = head number (0-1 for floppy)
  ; DL = drive number (0 for floppy, 0x80 for hard disk)

  ; back up AX
  push ax
  
  ; back up bx
  push bx
  push ax
  call CHStoLBA
  
  ; LBA is in dx (upper) and bx (lower)

  ; restore ax
  pop ax ; restore AX

  ; move sector count into CFREG2
  push dx
  mov dx, CFREG2 ; this is where we will store the sector count
  out dx, al ; send the number of sectors to read

  ; load the LBA
  mov dx, CFREG3 ; LBA 0-7
  mov al, bl ; move the lower lower part of the LBA into AL
  out dx, al ; send the lower lower part of the LBA to CFREG3

  mov dx, CFREG4 ; LBA 8-15
  mov al, bh ; move the upper lower part of the LBA into AL
  out dx, al ; send the upper lower part of the LBA to CFREG4

  pop bx ; grab the upper half from the stack

  mov dx, CFREG5 ; LBA 16-23
  mov al, bl ; move the lower upper part of the LBA into AL
  out dx, al ; send the lower upper part of the LBA to CFREG5

  mov dx, CFREG6 ; LBA 24-31
  mov al, bh ; move the upper upper part of the LBA into AL
  and dh, 0xF ; mask out the upper bits
  ; set up the drive and LBA bits 
  or al, 0xE0
  out dx, al ; send the upper upper part of the LBA to CFREG6

  ; now we need to read the sectors from the disk
  ; set the read command
  mov dx, CFREG7
  mov al, 0x20
  out dx, al

  ; wait for the CF card to be ready
  call CFWaitReady
  call CFCheckError

  ; restore bx
  pop bx ; restore BX

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
  jmp .success

  ; FIXME implement sector writing
.fn_write_sectors:
  jmp .unsupported_function ; not implemented yet


.fn_read_sectors_lba:
  ; AH = 1Bh - Read sectors from disk using LBA
  ; AL = number of sectors to read
  ; BX = buffer address
  ; CX = LBA lower address
  ; DX = LBA upper address

  ; back up AX
  push ax

  mov ax, dx
  mov dx, CFREG5 ; LBA 16-23
  out dx, al 
  mov al, ah
  and al, 0xF ; mask out the upper bits
  or al, 0xE0 ; set the drive number and LBA 
  mov dx, CFREG6 ; LBA 24-31
  out dx, al 
  
  mov ax, cx
  mov dx, CFREG3 ; LBA 0-7
  out dx, al
  mov al, ch
  mov dx, CFREG4 ; LBA 8-15
  out dx, al

  pop ax ; restore AX
  mov dx, CFREG2 ; move sector count into CFREG2
  out dx, al ; send the number of sectors to read

  ; back up AX again
  push ax

  ; set the read command
  mov dx, CFREG7
  mov al, 0x20
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
  jmp .success


 
.success:
  ; set carry flag to 0
  and word [ss:bp + 7*2], 0xFFFE ; clear carry flag to indicate success

.done:
  ; restore DS, BX, CX, and DX
  pop bp
  pop dx
  pop cx
  pop bx
  pop ds
  ; return from interrupt
  iret

.unsupported_function:
  ; Function not supported
  ; set carry flag to 1
  or word [ss:bp + 7*2], 0x0001 ; set the carry flag
  jmp .done

.function_table:
  dw .fn_reset_disk                 ; Function 00h
  dw .unsupported_function          ; Function 01h
  dw .fn_read_sectors               ; Function 02h  
  dw .fn_write_sectors              ; Function 03h
  dw .unsupported_function          ; Function 04h
  dw .unsupported_function          ; Function 05h
  dw .unsupported_function          ; Function 06h  
  dw .unsupported_function          ; Function 07h
  dw .unsupported_function          ; Function 08h  
  dw .unsupported_function          ; Function 09h
  dw .unsupported_function          ; Function 0Ah
  dw .unsupported_function          ; Function 0Bh
  dw .unsupported_function          ; Function 0Ch
  dw .unsupported_function          ; Function 0Dh
  dw .unsupported_function          ; Function 0Eh
  dw .unsupported_function          ; Function 0Fh
  dw .unsupported_function          ; Function 10h
  dw .unsupported_function          ; Function 11h
  dw .unsupported_function          ; Function 12h
  dw .unsupported_function          ; Function 13h
  dw .unsupported_function          ; Function 14h
  dw .unsupported_function          ; Function 15h
  dw .unsupported_function          ; Function 16h
  dw .unsupported_function          ; Function 17h
  dw .unsupported_function          ; Function 18h
  dw .unsupported_function          ; Function 19h
  dw .unsupported_function          ; Function 1Ah
  dw .fn_read_sectors_lba           ; Function 1Bh
.MAX_FUNCTION equ $ - .function_table

CHStoLBA:
  ; convert CHS to LBA
  ; set up an IDE read operation
  ; we need to convert this from CHS to LBA
  ; we'll assume 1024 cylinders, 16 heads & 63 sectors
  ; LBA = (sector - 1) + (head * SECTORS_PER_TRACK) + (cylinder * SECTORS_PER_TRACK * 16)

  ; back up ax and dx for the multiply
  push ax
  push dx

  mov dx, 16 ; set up the multiplier
  mov al, ch ; move the cylinder number into AL
  mov ah, cl ; move the sector number into AH (upper 2 bits are cylinder)
  shr ah, 1 ; shift right to get the cylinder number
  shr ah, 1 ; ditto
  mul dx ; multiply AX by 16 (the number of heads)

  mov dx, SECTORS_PER_TRACK ; set up the multiplier
  mul dx ; multiply AX by SECTORS_PER_TRACK

  ; bx is backed up
  ; grab the head number from stack and store it there
  pop bx

  ; lower part in AX, upper part in DX
  push ax ; save the lower part of the result
  push dx ; save the upper part of the result

  ; calculate head * 63
  xor ax, ax ; clear AX
  mov al, bh ; move the head number into AL
  mov dl, SECTORS_PER_TRACK ; set up the multiplier
  mul dl ; multiply AL by SECTORS_PER_TRACK

  ; ax now contains the head * SECTORS_PER_TRACK
  ; restore dx 
  pop dx ; restore the upper part of the result
  ; restore lower part of the result to bx
  pop bx 
  ; add the head * SECTORS_PER_TRACK to the result
  add bx, ax ; add the head * SECTORS_PER_TRACK to the result

  ; increment dx by 1 if there was a carry
  adc dx, 0 ; add the carry to DX

  ; clear out ax
  xor ax, ax ; clear AX
  ; move the sector number into AL
  mov al, cl ; move the sector number into AL
  dec al ; decrement the sector number by 1

  add bx, ax ; add the result to the sector number
  ; increment dx by 1 if there was a carry
  adc dx, 0 ; add the carry to 

  ; restore ax that was backed up for multiply
  pop ax

  ; LBA is in dx (upper) and bx (lower)
  ret
