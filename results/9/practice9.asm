
; =============================================================================
; Практична робота №9
; Мова: Assembler i386 (NASM)
; Завдання: LCG Генератор та Гістограма
; =============================================================================

section .data
    msg_n       db "Введіть n (100..1000): ", 0
    len_n       equ $ - msg_n
    
    hash        db "#", 0
    colon       db ": ", 0
    open_p      db " (", 0
    close_p     db ")", 0xA, 0
    newline     db 0xA, 0
    
    ; LCG константи
    lcg_a       dd 1103515245
    lcg_c       dd 12345
    lcg_m       dd 0x7FFFFFFF  ; 2^31 - 1
    seed        dd 42          ; початкове значення

section .bss
    ; [memory]
    freq        resd 10         ; масив частот (10 інтервалів)
    n           resd 1
    current_x   resd 1
    
    output_buf  resb 16

section .text
    global _start

_start:
    ; [I/O] - Запит n
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_n
    mov edx, len_n
    int 0x80

    call read_and_atoi
    mov [n], eax
    
    ; Ініціалізація
    mov eax, [seed]
    mov [current_x], eax
    
    ; Обнулення масиву частот
    xor edi, edi
.clear_freq:
    mov dword [freq + edi*4], 0
    inc edi
    cmp edi, 10
    jne .clear_freq

    ; [loops] [math] - Генерація n чисел та підрахунок
    xor edi, edi                ; i = 0
.gen_loop:
    cmp edi, [n]
    je .print_histogram
    
    ; LCG: x = (a*x + c) mod 2^31
    mov eax, [current_x]
    mov edx, [lcg_a]
    mul edx                     ; edx:eax = a * x
    add eax, [lcg_c]
    and eax, 0x7FFFFFFF         ; eax = eax mod 2^31
    mov [current_x], eax
    
    ; Отримання числа від 0 до 9
    ; Використовуємо старші біти для кращої випадковості
    shr eax, 16
    xor edx, edx
    mov ebx, 10
    div ebx                     ; edx = eax % 10
    
    ; [logic] - Інкремент частоти
    inc dword [freq + edx*4]
    
    inc edi
    jmp .gen_loop

.print_histogram:
    ; [loops] [I/O] - Вивід гістограми
    xor esi, esi                ; bucket_idx = 0
.bucket_loop:
    cmp esi, 10
    je .exit
    
    ; Вивід "i: "
    mov eax, esi
    call print_num_raw
    
    mov eax, 4
    mov ebx, 1
    mov ecx, colon
    mov edx, 2
    int 0x80
    
    ; Вивід '#' пропорційно count
    mov edi, [freq + esi*4]     ; count
.hash_loop:
    test edi, edi
    jz .print_count_val
    
    push edi
    mov eax, 4
    mov ebx, 1
    mov ecx, hash
    mov edx, 1
    int 0x80
    pop edi
    
    dec edi
    jmp .hash_loop

.print_count_val:
    ; Вивід " (count)"
    mov eax, 4
    mov ebx, 1
    mov ecx, open_p
    mov edx, 2
    int 0x80
    
    mov eax, [freq + esi*4]
    call print_num_raw
    
    mov eax, 4
    mov ebx, 1
    mov ecx, close_p
    mov edx, 2
    int 0x80
    
    inc esi
    jmp .bucket_loop

.exit:
    ; [exit]
    mov eax, 1
    xor ebx, ebx
    int 0x80

; --- [parse] read_and_atoi ---
read_and_atoi:
    push ebx
    push ecx
    push edx
    push esi
    xor eax, eax
    xor esi, esi
.r_loop:
    push eax
    mov eax, 3
    mov ebx, 0
    mov ecx, output_buf
    mov edx, 1
    int 0x80
    cmp eax, 0
    jle .r_pop_done
    mov bl, [output_buf]
    pop eax
    cmp bl, '0'
    jb .check_sep
    cmp bl, '9'
    ja .check_sep
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    mov esi, 1
    jmp .r_loop
.check_sep:
    test esi, esi
    jz .r_loop
    jmp .r_final_done
.r_pop_done:
    pop eax
.r_final_done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; --- [I/O] print_num_raw ---
print_num_raw:
    pusha
    lea edi, [output_buf + 15]
    mov byte [edi], 0
    mov ebx, 10
    xor ecx, ecx
.itoa_l:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx
    test eax, eax
    jnz .itoa_l
    mov edx, ecx
    mov ecx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80
    popa
    ret
