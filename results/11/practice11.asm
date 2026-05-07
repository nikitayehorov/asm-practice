
; =============================================================================
; Практична робота №11
; Мова: Assembler i386 (NASM)
; Завдання: Символьна фігура (Ялинка)
; =============================================================================

section .data
    msg_h       db "Введіть висоту h (5..25): ", 0
    len_h       equ $ - msg_h
    
    star        db "*"
    space       db " "
    newline     db 0xA

section .bss
    ; [memory]
    h           resd 1
    row_buf     resb 128        ; буфер для формування рядка
    
    input_buf   resb 16
    output_buf  resb 16

section .text
    global _start

_start:
    ; [I/O] - Запит висоти
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_h
    mov edx, len_h
    int 0x80

    call read_and_atoi
    mov [h], eax

    ; [logic] [loops] - Зовнішній цикл по рядах (i від 1 до h)
    mov esi, 1                  ; i = 1
.outer_loop:
    mov eax, [h]
    cmp esi, eax
    jg .exit
    
    ; Формування рядка у буфері
    lea edi, [row_buf]
    
    ; 1. Додавання пробілів (h - i)
    mov ecx, [h]
    sub ecx, esi                ; ecx = h - i
.space_loop:
    test ecx, ecx
    jz .stars_init
    mov byte [edi], ' '
    inc edi
    dec ecx
    jmp .space_loop

.stars_init:
    ; 2. Додавання зірочок (2*i - 1)
    mov ecx, esi
    shl ecx, 1                  ; ecx = 2*i
    dec ecx                     ; ecx = 2*i - 1
.star_loop:
    test ecx, ecx
    jz .row_done
    mov byte [edi], '*'
    inc edi
    dec ecx
    jmp .star_loop

.row_done:
    ; 3. Додавання переходу на новий рядок
    mov byte [edi], 0xA
    inc edi
    
    ; [I/O] - Вивід сформованого рядка через підпрограму
    ; Рахуємо довжину: edi - row_buf
    mov edx, edi
    sub edx, row_buf
    push edx                    ; len
    push row_buf                ; buf
    call print_line
    add esp, 8
    
    inc esi
    jmp .outer_loop

.exit:
    ; [exit]
    mov eax, 1
    xor ebx, ebx
    int 0x80

; --- Підпрограма print_line(buf, len) ---
print_line:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    
    mov ecx, [ebp + 8]          ; buf
    mov edx, [ebp + 12]         ; len
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    int 0x80
    
    pop edx
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret

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
