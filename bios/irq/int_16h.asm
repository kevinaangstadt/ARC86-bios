; Int 16h - Keyboard Services
IRQ_16h:
  ;back up DS, BX, CX, and DX
  push ds
  push bx
  push cx
  push dx
  push bp

  mov bp, sp

  ; FIXME support more than AH=0x00
  cmp ah, 0x00
  jne .unsupported_function

  ; clear the RX buffer
  mov dx, UART_FIFO
  in al, dx
  and al, 0xC1
  or al, 0x02
  out dx, al

  ; wait for a key to be pressed on the uart
  call fn_uart_wait_to_read

  ; read the key from the uart
  mov dx, UART_DATA
  in al, dx

  ; success unset carry flag
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
