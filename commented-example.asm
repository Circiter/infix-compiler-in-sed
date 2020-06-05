; Commented assembler output for a formula "1+2".

; Can be compiled with
; nasm -f elf commented-example.asm
; ld -m elf_i386 commented-example.o commented-example

global _start

_start:

call real_start ; "Jump" over the convert proc. to get its address.

convert:
  push edx

  div_mul:
    xor edx, edx
    mov esi, 256
    div esi ; Extract next byte.
    sub edx, 48 ; Get the value of extracted digit (ASCII-dependent).
    push edx
    xchg eax, ebx
    mov esi, 10
    mul esi
    xchg eax, ebx
    pop edx
    add ebx, edx ; Append new digit to the accumulated result.
    cmp eax, 0
    jnz div_mul

  mov eax, ebx

  pop edx
  ret

real_start:

; The TOS contains the address of the label "convert".
pop edx ; edx=[convert].

xor ebx, ebx
mov eax, 0x00000031 ; eax="1".
call edx ; Pass control to convert.
; eax=1.
push eax
xor ebx, ebx
mov eax, 0x00000032 ; eax="2".
call edx
; eax=2.
pop ebx
add eax, ebx
; eax=3.

; Print.

cmp eax, 0
jnl print

neg eax
push eax
mov eax, 0x2d ; Print the minus sign.
push eax
mov ecx, esp
mov ebx, 1 ; stdout.
mov eax, 4 ; sys_write.
mov edx, 1 ; one character.
int 0x80 ; Linux system call.
pop eax
pop eax

print:

xor ecx, ecx

extract_digits:
  inc ecx
  xor edx, edx
  mov esi, 10
  div esi
  add edx, 48 ; Convert back to ASCII-code.
  push edx
  cmp eax, 0
  jnz extract_digits

; The stack now contains all the digits
; and we can show them in correct order.

show_digits:
  dec ecx
  mov eax, esp
  push ecx
  mov ecx, eax ; Message address.
  mov ebx, 1
  mov eax, 4
  mov edx, 1
  int 0x80 ; System call.
  pop ecx
  pop eax
  cmp ecx, 0
  jnz show_digits

; Exit (I place this optional code here because
; the sed script inserts some garbage at the
; end of a generated code).
mov eax, 1
xor ebx, ebx
int 80h
