# ARC86 BIOS

This is a BIOS for ARC86-based computers (such as the
[ARC86-512](https://github.com/kevinaangstadt/ARC86-512) and the [8088
Breadboard
Computer](https://github.com/kevinaangstadt/8088_breadboard_computer)).

# BIOS Interrupts
This BIOS implements a number of interrupts that can be used by the operating
system or other software running on the computer.

> [!CAUTION]
> The BIOS is not complete and is still a work in progress. Some interrupts may
> not be fully implemented or may not work as expected. Use at your own risk.
> Interrupts are also subject to change.

## Interrupt 0x05:
Print provided string to UART (the screen)
### Parameters
- DS = the segment of the string to print
- AX = the start of the string in memory (null-terminated)

### Register Manipulation
- registers CS, DS, ES, SS, BX, CX, SI, DI are preserved
- registers AX, DX are modified
