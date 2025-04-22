; IRQ 10h video service

IRQ_10h:
  ; back up ds, es, ss, bx, cx, dx
  push ds
  push es
  push ss
  push bx
  push cx
  push dx
  push bp

  mov bp, sp

  ; compare ah for the function
  ; TODO support more features
  cmp ah, .MAX_FUNCTION           ; check we are in bounds
  jae .unsupported_function       ; function not supported (out of range)

  ; get the function address from the function table
  xor bh, bh                      ; clear upper part of bx
  mov bl, ah                      ; move the function number into bl  
  shl bx, 1                       ; multiply by 2 for table offset
  jmp [cs:.function_table + bx]   ; jump to the function

.fn_set_video_mode:
  ; Function 00h - Set video mode
  ; AH = 00
  ; AL = video mode number
  ; BH = page number (text modes)
  ; BL = foreground pixel color (graphics modes)

  ; only allow video modes below 4
  cmp al, 4
  jae .unsupported_function
  ; set the video mode

  ; update video mode in the BDA
  mov bx, 0x0040
  mov ds, bx
  mov [ds:BDA_VIDEO_MODE], al

  call fn_uart_set_vidmode      ; call the UART set video mode function
  jmp .success

.fn_set_cursor_position:
  ; Function 02h - Set cursor position
  ; AH = 02
  ; BH = page number (text modes)
  ; DH = row (0-24)
  ; DL = column (0-79)
  push ax
  ; check if the row and column are in range
  mov ax, 0x0040
  mov ds, ax
  pop ax

  cmp dh, 25
  jae .unsupported_function

  cmp byte [ds:BDA_VIDEO_MODE], 0x02
  jae .check_80_col 
  cmp dl, 40
  jae .unsupported_function
.check_80_col:
  cmp dl, 80
  jae .unsupported_function

  mov al, dh 
  mov ah, dl
  ; al contains the line
  ; ah contains the column
  call fn_uart_move_cursor ; call the UART set cursor position function
  jmp .success


.fn_teletype_output:
  ; Function 0Eh - Teletype output
  ; TTY output function
  ; AH = 0E
  ; AL = ASCII character to write
  ; BH = page number (text modes)
  ; BL = foreground pixel color (graphics modes)
  call fn_uart_print_char ; call the UART print character function
  jmp .success
  
.success:
  and word [bp + 10 * 2], 0xFFFE ; clear the carry flag

.done:
  ; restore ds, es, ss, bx, cx, dx
  pop bp
  pop dx
  pop cx
  pop bx
  pop ss
  pop es
  pop ds
  ; return from interrupt
  iret

.unsupported_function:
  or word [bp + 10 * 2], 0x0001    ; set the carry flag
  jmp .done
  
.function_table:
  dw .fn_set_video_mode       ; Function 00h
  dw .unsupported_function    ; Function 01h
  dw .fn_set_cursor_position  ; Function 02h
  dw .unsupported_function    ; Function 03h
  dw .unsupported_function    ; Function 04h
  dw .unsupported_function    ; Function 05h
  dw .unsupported_function    ; Function 06h
  dw .unsupported_function    ; Function 07h
  dw .unsupported_function    ; Function 08h
  dw .unsupported_function    ; Function 09h
  dw .unsupported_function    ; Function 0Ah
  dw .unsupported_function    ; Function 0Bh
  dw .unsupported_function    ; Function 0Ch
  dw .unsupported_function    ; Function 0Dh
  dw .fn_teletype_output      ; Function 0Eh
  dw .unsupported_function    ; Function 0Fh
.MAX_FUNCTION equ $ - .function_table
