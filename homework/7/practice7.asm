
; =============================================================================
; Практична робота №7
; Мова: Assembler i386 (NASM)
; ОС: Debian Linux (RPi5 Emulation)
; Ввід/вивід: лише int 0x80 (sys_read/sys_write/sys_exit)
; =============================================================================

section .data
    msg_prompt  db "Введіть n (5..50): ", 0
    len_prompt  equ $ - msg_prompt
    
    msg_arr     db "Масив: ", 0
    len_arr     equ $ - msg_arr
    
    msg_min     db 0xA, "Min: ", 0
    len_min     equ $ - msg_min
    
    msg_max     db 0xA, "Max: ", 0
    len_max     equ $ - msg_max
    
    msg_at_idx  db " на індексі ", 0
    len_at_idx  equ $ - msg_at_idx
    
    space       db " ", 0
    newline     db 0xA, 0

section .bss
    ; [memory]
    array       resd 50         ; масив dd 50 dup(?)
    n           resd 1          ; кількість елементів
    min_val     resd 1
    min_idx     resd 1
    max_val     resd 1
    max_idx     resd 1
    
    input_buf   resb 16         ; буфер для вводу
    output_buf  resb 16         ; буфер для виводу числа

section .text
    global _start

_start:
    ; [I/O] - Запит на введення n
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, msg_prompt
    mov edx, len_prompt
    int 0x80

    ; [I/O] - Читання n
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin
    mov ecx, input_buf
    mov edx, 15
    int 0x80

    ; [parse] - Конвертація рядка в число (atoi)
    lea esi, [input_buf]
    xor eax, eax
    xor ebx, ebx
.atoi_loop:
    mov bl, [esi]
    cmp bl, 0xA                 ; кінець рядка (newline)
    je .atoi_done
    cmp bl, '0'
    jb .atoi_done
    cmp bl, '9'
    ja .atoi_done
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp .atoi_loop
.atoi_done:
    mov [n], eax

    ; [logic] [math] [loops] - Заповнення масиву за формулою: a[i] = (i * 11 + 13) % 100
    xor ecx, ecx                ; i = 0
.fill_loop:
    cmp ecx, [n]
    je .init_minmax
    
    mov eax, ecx
    imul eax, 11
    add eax, 13
    xor edx, edx
    mov ebx, 100
    div ebx                     ; edx = (i*11+13) % 100
    
    mov [array + ecx*4], edx    ; індексація [base + idx*4]
    inc ecx
    jmp .fill_loop

.init_minmax:
    ; [logic] - Ініціалізація min/max першим елементом
    mov eax, [array]
    mov [min_val], eax
    mov [max_val], eax
    mov dword [min_idx], 0
    mov dword [max_idx], 0
    
    mov ecx, 1                  ; цикл for по індексах від 1 до n-1
.minmax_loop:
    cmp ecx, [n]
    je .print_array_info
    
    mov eax, [array + ecx*4]
    
    ; [logic] - Пошук min
    cmp eax, [min_val]
    jge .check_max
    mov [min_val], eax
    mov [min_idx], ecx
    jmp .next_iter

.check_max:
    ; [logic] - Пошук max
    cmp eax, [max_val]
    jle .next_iter
    mov [max_val], eax
    mov [max_idx], ecx

.next_iter:
    inc ecx
    jmp .minmax_loop

.print_array_info:
    ; [I/O] - Вивід заголовка "Масив: "
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_arr
    mov edx, len_arr
    int 0x80

    xor ecx, ecx                ; i = 0
.print_arr_loop:
    cmp ecx, [n]
    je .print_min_res
    
    push ecx                    ; зберігаємо лічильник
    mov eax, [array + ecx*4]
    call print_number
    
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80
    
    pop ecx
    inc ecx
    jmp .print_arr_loop

.print_min_res:
    ; [I/O] - Вивід Min та його індексу
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_min
    mov edx, len_min
    int 0x80
    
    mov eax, [min_val]
    call print_number
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_at_idx
    mov edx, len_at_idx
    int 0x80
    
    mov eax, [min_idx]
    call print_number

    ; [I/O] - Вивід Max та його індексу
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_max
    mov edx, len_max
    int 0x80
    
    mov eax, [max_val]
    call print_number
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_at_idx
    mov edx, len_at_idx
    int 0x80
    
    mov eax, [max_idx]
    call print_number

    ; Перевід рядка в кінці
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; [exit] - Вихід із програми
    mov eax, 1                  ; sys_exit
    xor ebx, ebx
    int 0x80

; --- Допоміжна функція: print_number (виводить EAX у консоль) ---
print_number:
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
    
    mov edx, ecx                ; довжина рядка
    mov ecx, edi                ; адреса рядка
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    int 0x80
    popa
    ret
