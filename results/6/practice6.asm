section .data
    prompt_a db "Enter a: ", 0
    prompt_b db "Enter b: ", 0
    msg_s    db "SIGNED: ", 0
    msg_u    db "UNSIGNED: ", 0
    msg_maxs db "max_signed: ", 0
    msg_maxu db "max_unsigned: ", 0
    less     db " < ", 0
    greater  db " > ", 0
    equal    db " = ", 0
    newline  db 0xA

section .bss
    buf_a    resd 1
    buf_b    resd 1
    input    resb 16
    output   resb 16

section .text
    global _start

_start:
    mov eax, prompt_a
    call print_string
    call read_and_atoi
    mov [buf_a], eax

    mov eax, prompt_b
    call print_string
    call read_and_atoi
    mov [buf_b], eax

    mov eax, msg_s
    call print_string

    mov eax, [buf_a]
    mov ebx, [buf_b]
    cmp eax, ebx
    jg .s_greater
    jl .s_less
    jmp .s_equal

.s_greater:
    call print_res_greater
    jmp .unsigned_part
.s_less:
    call print_res_less
    jmp .unsigned_part
.s_equal:
    call print_res_equal

.unsigned_part:
    mov eax, newline
    call print_char
    mov eax, msg_u
    call print_string
    mov eax, [buf_a]
    mov ebx, [buf_b]
    cmp eax, ebx
    ja .u_greater
    jb .u_less
    jmp .u_equal

.u_greater:
    call print_res_greater
    jmp .max_part
.u_less:
    call print_res_less
    jmp .max_part
.u_equal:
    call print_res_equal

.max_part:
    mov eax, newline
    call print_char
    mov eax, msg_maxs
    call print_string
    mov eax, [buf_a]
    mov ebx, [buf_b]
    cmp eax, ebx
    jg .print_maxs
    mov eax, ebx

.print_maxs:
    call print_int_signed

    mov eax, newline
    call print_char
    mov eax, msg_maxu
    call print_string
    mov eax, [buf_a]
    mov ebx, [buf_b]
    cmp eax, ebx
    ja .print_maxu
    mov eax, ebx

.print_maxu:
    call print_int_unsigned

    mov eax, newline
    call print_char

    mov eax, 1
    xor ebx, ebx
    int 0x80

read_and_atoi:
    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 16
    int 0x80

    lea esi, [input]
    xor eax, eax
    xor ebx, ebx
    xor edi, edi
    mov bl, [esi]
    cmp bl, '-'
    jne .parse_loop
    inc edi
    inc esi

.parse_loop:
    mov bl, [esi]
    cmp bl, 0xA
    je .done
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp .parse_loop

.done:
    test edi, edi
    jz .exit
    neg eax

.exit:
    ret

print_int_signed:
    test eax, eax
    jns .positive
    push eax
    mov al, '-'
    call print_char
    pop eax
    neg eax

.positive:
    call print_int_unsigned
    ret

print_int_unsigned:
    mov ebx, 10
    lea ecx, [output + 15]
    mov edi, 0

.itoa:
    xor edx, edx
    div ebx
    add dl, '0'
    dec ecx
    mov [ecx], dl
    inc edi
    test eax, eax
    jnz .itoa
    mov edx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

print_res_greater:
    push eax
    push ebx
    call print_int_signed
    mov eax, greater
    call print_string
    pop ebx
    mov eax, ebx
    call print_int_signed
    pop eax
    ret

print_res_less:
    push eax
    push ebx
    call print_int_signed
    mov eax, less
    call print_string
    pop ebx
    mov eax, ebx
    call print_int_signed
    pop eax
    ret

print_res_equal:
    push eax
    push ebx
    call print_int_signed
    mov eax, equal
    call print_string
    pop ebx
    mov eax, ebx
    call print_int_signed
    pop eax
    ret

print_string:
    push eax
    push ebx
    push ecx
    push edx
    mov ecx, eax
    mov edi, eax
    xor edx, edx

.len:
    cmp byte [edi], 0
    je .out
    inc edi
    inc edx
    jmp .len

.out:
    mov eax, 4
    mov ebx, 1
    int 0x80
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

print_char:
    push eax
    mov [output], al
    mov eax, 4
    mov ebx, 1
    mov ecx, output
    mov edx, 1
    int 0x80
    pop eax
    ret
