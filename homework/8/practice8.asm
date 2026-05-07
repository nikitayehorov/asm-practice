
; =============================================================================
; Практична робота №8
; Мова: Assembler i386 (NASM)
; Завдання: Лінійний пошук та підрахунок входжень
; =============================================================================

section .data
    msg_n       db "Введіть n (10..100): ", 0
    len_n       equ $ - msg_n
    msg_nums    db "Введіть числа (через пробіл або Enter): ", 0
    len_nums    equ $ - msg_nums
    msg_target  db "Введіть шукане число (target): ", 0
    len_target  equ $ - msg_target
    
    msg_res1    db "Перший індекс: ", 0
    len_res1    equ $ - msg_res1
    msg_res2    db 0xA, "Кількість входжень: ", 0
    len_res2    equ $ - msg_res2
    msg_res3    db 0xA, "Всі індекси: ", 0
    len_res3    equ $ - msg_res3
    
    space       db " ", 0
    newline     db 0xA, 0
    minus_one   db "-1", 0

section .bss
    ; [memory]
    array       resd 100        ; основний масив
    res_indices resd 100        ; масив знайдених індексів
    n           resd 1
    target      resd 1
    count       resd 1
    first_idx   resd 1
    
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

    ; [I/O] - Запит чисел
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_nums
    mov edx, len_nums
    int 0x80

    ; [loops] [memory] - Зчитування n чисел
    xor edi, edi                ; лічильник i = 0
.read_loop:
    cmp edi, [n]
    je .get_target
    call read_and_atoi
    mov [array + edi*4], eax
    inc edi
    jmp .read_loop

.get_target:
    ; [I/O] - Запит target
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_target
    mov edx, len_target
    int 0x80
    
    call read_and_atoi
    mov [target], eax

    ; [logic] - Пошук значення
    mov dword [first_idx], -1
    mov dword [count], 0
    xor edi, edi                ; i = 0
    xor esi, esi                ; j = 0

.search_loop:
    cmp edi, [n]
    je .print_results
    
    mov eax, [array + edi*4]
    cmp eax, [target]
    jne .next_search
    
    inc dword [count]
    mov [res_indices + esi*4], edi
    inc esi
    
    cmp dword [first_idx], -1
    jne .next_search
    mov [first_idx], edi

.next_search:
    inc edi
    jmp .search_loop

.print_results:
    ; [I/O] - Вивід першого індексу
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_res1
    mov edx, len_res1
    int 0x80
    
    mov eax, [first_idx]
    cmp eax, -1
    je .print_minus_one
    call print_number
    jmp .print_count_res

.print_minus_one:
    mov eax, 4
    mov ebx, 1
    mov ecx, minus_one
    mov edx, 2
    int 0x80

.print_count_res:
    ; [I/O] - Вивід кількості
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_res2
    mov edx, len_res2
    int 0x80
    
    mov eax, [count]
    call print_number

    ; [I/O] - Вивід списку індексів
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_res3
    mov edx, len_res3
    int 0x80
    
    xor edi, edi
.print_idx_loop:
    cmp edi, [count]
    je .exit_prog
    
    mov eax, [res_indices + edi*4]
    call print_number
    
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80
    
    inc edi
    jmp .print_idx_loop

.exit_prog:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; [exit]
    mov eax, 1
    xor ebx, ebx
    int 0x80

; --- [parse] Функція read_and_atoi ---
read_and_atoi:
    push ebx
    push ecx
    push edx
    push esi
    
    xor eax, eax                ; накопичувач
    xor esi, esi                ; прапорець "цифри були"

.r_loop:
    push eax                    ; зберігаємо накопичувач
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin
    mov ecx, output_buf
    mov edx, 1
    int 0x80
    
    cmp eax, 0
    jle .r_pop_done
    
    mov bl, [output_buf]
    pop eax                     ; повертаємо накопичувач
    
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

; --- [I/O] Функція print_number ---
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
    
    mov edx, ecx
    mov ecx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80
    popa
    ret
