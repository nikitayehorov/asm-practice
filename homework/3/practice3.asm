section .data
    newline db 0xA

section .bss
    buffer resb 12

section .text
    global _start

_start:
    mov eax, 98765
    mov ebx, 10
    lea ecx, [buffer + 11]
    mov edi, 0

.loop:
    xor edx, edx
    div ebx
    add dl, '0'
    dec ecx
    mov [ecx], dl
    inc edi
    test eax, eax
    jnz .loop

    mov edx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    mov eax, 1
    xor ebx, ebx
    int 0x80
