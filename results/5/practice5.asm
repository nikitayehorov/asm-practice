section .data
    msg_input db "Enter x: ", 0
    msg_sum   db "Sum of digits: ", 0
    msg_len   db "Length: ", 0
    newline   db 0xA

section .bss
    input_buf  resb 12
    output_buf resb 12
    sum_res    resd 1
    len_res    resd 1

section .text
    global _start

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_input
    mov edx, 9
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
    je .calc_start
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp .atoi_loop

.calc_start:
    xor ecx, ecx
    xor edi, edi
    mov ebx, 10

.math_loop:
    xor edx, edx
    div ebx
    add ecx, edx
    inc edi
    test eax, eax
    jnz .math_loop

    mov [sum_res], ecx
    mov [len_res], edi

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_sum
    mov edx, 15
    int 0x80

    mov eax, [sum_res]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_len
    mov edx, 8
    int 0x80

    mov eax, [len_res]
    call print_number

    mov eax, 1
    xor ebx, ebx
    int 0x80

print_number:
    push eax
    push ebx
    push ecx
    push edx

    mov ebx, 10
    lea ecx, [output_buf + 11]
    mov byte [ecx], 0xA
    mov edi, 1

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

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
