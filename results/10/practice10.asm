
; =============================================================================
; Практична робота №10
; Мова: Assembler i386 (NASM)
; Завдання: Бітові операції, Popcount та двійковий вивід
; =============================================================================

section .data
    msg_input   db "Введіть число x: ", 0
    len_input   equ $ - msg_input
    
    msg_bin     db "Двійковий вигляд: ", 0
    len_bin     equ $ - msg_bin
    
    msg_pop     db 0xA, "Popcount(x): ", 0
    len_pop     equ $ - msg_pop
    
    msg_bits    db 0xA, "Результат маніпуляцій (set 3,7, clear 0): ", 0
    len_bits    equ $ - msg_bits
    
    space       db " ", 0
    newline     db 0xA, 0
    
    ; Позиції бітів (за замовчуванням)
    P_BIT       equ 3
    Q_BIT       equ 7
    R_BIT       equ 0

section .bss
    ; [memory]
    x           resd 1
    temp_x      resd 1
    count       resd 1
    output_buf  resb 64         ; збільшений буфер для виводу

section .text
    global _start

_start:
    ; [I/O] - Запит числа x
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_input
    mov edx, len_input
    int 0x80

    call read_and_atoi
    mov [x], eax

    ; --- 1. Вивід у двійковому вигляді ---
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_bin
    mov edx, len_bin
    int 0x80

    mov eax, [x]
    mov edi, 32                 ; 32 біти
.bin_loop:
    test edi, edi
    jz .popcount_start
    
    rol eax, 1                  ; цикловий зсув вліво, біт потрапляє в CF
    push eax                    ; зберігаємо число
    
    jc .print_one
    mov byte [output_buf], '0'
    jmp .do_print_bit
.print_one:
    mov byte [output_buf], '1'

.do_print_bit:
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf
    mov edx, 1
    int 0x80
    
    ; Перевірка на групу по 4 (якщо (32-edi+1) % 4 == 0 і edi != 1)
    mov eax, edi
    dec eax
    test eax, 0x03              ; перевірка на кратність 4 (залишок від ділення на 4)
    jnz .no_space
    cmp edi, 1                  ; не ставимо пробіл в самому кінці
    je .no_space
    
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

.no_space:
    pop eax
    dec edi
    jmp .bin_loop

.popcount_start:
    ; --- 2. Рахунок бітів (popcount) ---
    mov eax, [x]
    xor ecx, ecx                ; count = 0
    mov edi, 32
.pop_loop:
    test edi, edi
    jz .pop_done
    
    mov edx, eax
    and edx, 1                  ; перевіряємо молодший біт
    add ecx, edx
    shr eax, 1                  ; зсув вправо
    
    dec edi
    jmp .pop_loop

.pop_done:
    mov [count], ecx
    
    ; [I/O] - Вивід popcount
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_pop
    mov edx, len_pop
    int 0x80
    
    mov eax, [count]
    call print_num_raw

    ; --- 3. Маніпуляції з бітами (set p,q, clear r) ---
    mov eax, [x]
    
    ; [logic] [math] - Застосування масок
    or eax, (1 << P_BIT)        ; set bit P
    or eax, (1 << Q_BIT)        ; set bit Q
    and eax, ~(1 << R_BIT)      ; clear bit R
    
    mov [temp_x], eax

    ; [I/O] - Вивід результату в десятковому вигляді
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_bits
    mov edx, len_bits
    int 0x80
    
    mov eax, [temp_x]
    call print_num_raw

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

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
    lea edi, [output_buf + 63]
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
