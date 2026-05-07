
section .data
    msg_text    db "Введіть текст: ", 0
    msg_pat     db "Введіть шаблон: ", 0
    msg_pos     db "Перша позиція: ", 0
    msg_count   db 0xA, "Кількість входжень: ", 0
    minus_one   db "-1", 0
    newline     db 0xA, 0

section .bss
    text        resb 256
    pattern     resb 64
    text_len    resd 1
    pat_len     resd 1
    first_pos   resd 1
    total_count resd 1
    temp_char   resb 1
    output_buf  resb 16

section .text
    global _start

_start:
    ; Читання тексту
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_text
    mov edx, 15
    int 0x80

    mov edi, text
    mov edx, 255
    call read_line
    mov [text_len], eax

    ; Читання шаблону
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_pat
    mov edx, 16
    int 0x80

    mov edi, pattern
    mov edx, 63
    call read_line
    mov [pat_len], eax

    ; Пошук
    mov dword [first_pos], -1
    mov dword [total_count], 0
    
    mov eax, [pat_len]
    test eax, eax
    jz .finish
    
    xor esi, esi                ; i
.l1:
    mov eax, esi
    add eax, [pat_len]
    cmp eax, [text_len]
    ja .finish
    
    ; Порівняння
    xor ecx, ecx                ; j
.l2:
    cmp ecx, [pat_len]
    je .match
    
    mov al, [text + esi + ecx]
    mov bl, [pattern + ecx]
    cmp al, bl
    jne .mismatch
    
    inc ecx
    jmp .l2

.match:
    inc dword [total_count]
    cmp dword [first_pos], -1
    jne .s1
    mov [first_pos], esi
.s1:
    add esi, [pat_len]
    jmp .l1

.mismatch:
    inc esi
    jmp .l1

.finish:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_pos
    mov edx, 15
    int 0x80
    
    mov eax, [first_pos]
    cmp eax, -1
    je .m
    call print_num
    jmp .c
.m:
    mov eax, 4
    mov ebx, 1
    mov ecx, minus_one
    mov edx, 2
    int 0x80
.c:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_count
    mov edx, 20
    int 0x80
    mov eax, [total_count]
    call print_num
    
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    mov eax, 1
    xor ebx, ebx
    int 0x80

read_line:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    xor esi, esi                ; len
.loop:
    cmp esi, edx
    je .out
    
    mov eax, 3
    mov ebx, 0
    lea ecx, [temp_char]
    push edx                    ; save edx (max)
    mov edx, 1
    int 0x80
    pop edx
    
    cmp eax, 1
    jne .out
    
    mov al, [temp_char]
    cmp al, 0xA
    je .out
    cmp al, 0xD
    je .out
    
    mov [edi + esi], al
    inc esi
    jmp .loop
.out:
    mov byte [edi + esi], 0
    mov eax, esi
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

print_num:
    pusha
    test eax, eax
    jnz .p
    mov byte [output_buf], '0'
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    mov edx, 1
    int 0x80
    popa
    ret
.p:
    lea edi, [output_buf + 15]
    mov byte [edi], 0
    mov ebx, 10
    xor ecx, ecx
.l:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx
    test eax, eax
    jnz .l
    mov edx, ecx
    mov ecx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80
    popa
    ret
