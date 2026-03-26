section .data
    msg_input db "Vedit Text! ", 0
    msg_len equ $ - msg_input
    newline db 0xA

section .bss
    input_buf resb 12
    output_buf resb 12

section .text
    global _start

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_input
    mov edx, msg_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 12
    int 0x80

    lea esi, [input_buf]
    xor eax, eax
    xor ebx, ebx

.atoi_loop:
    mov bl, [esi]
    cmp bl, 0xA
    je .done_parsing
    cmp bl, '0'
    jb .done_parsing
    cmp bl, '9'
    ja .done_parsing
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp .atoi_loop

.done_parsing:
    mov ebx, 10
    lea ecx, [output_buf + 11]
    mov edi, 0

.itoa_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    dec ecx
    mov [ecx], dl
    inc edi
    test eax, eax
    jnz .itoa_loop

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
