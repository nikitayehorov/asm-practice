; ==========================================
; Practice 13: Memory Copy, Reverse & Palindrome Check
; Architecture: i386 (32-bit ELF)
; OS: Debian Linux (using int 0x80 syscalls)
; ==========================================

section .data
    ; [I/O] Messages
    prompt_n        db "Enter n (5..200): ", 0
    prompt_numbers  db "Enter numbers: ", 0
    msg_orig        db "Original: ", 0
    msg_rev         db "Reversed: ", 0
    msg_pal_yes     db "PALINDROME: YES", 0xA, 0
    msg_pal_no      db "PALINDROME: NO", 0xA, 0
    msg_err_n       db "Error: n must be between 5 and 200", 0xA, 0
    msg_err_parse   db "Error: failed to parse integer", 0xA, 0
    
    newline         db 0xA, 0
    space_char      db " ", 0
    minus_char      db "-", 0

section .bss
    ; [memory] Buffers
    n               resd 1
    array_orig      resd 200
    array_copy      resd 200
    array_rev       resd 200
    is_palindrome   resd 1
    
    ; [I/O] Stdin buffering
    input_buf       resb 1024
    input_pos       resd 1
    input_end       resd 1
    
    ; [I/O] Temporary character and numeric output buffer
    temp_char       resb 1
    output_buf      resb 16

section .text
    global _start

_start:
    ; [I/O] Print prompt for n
    mov ecx, prompt_n
    call print_string
    
    ; [parse] Read n
    call read_int
    jc .err_parse
    
    ; [logic] Validate n (5..200)
    cmp eax, 5
    jl .err_invalid_n
    cmp eax, 200
    jg .err_invalid_n
    
    mov [n], eax
    
    ; [I/O] Print prompt for numbers
    mov ecx, prompt_numbers
    call print_string
    
    ; [loops] [parse] Read n integers into array_orig
    xor edi, edi            ; index = 0
.read_loop:
    cmp edi, [n]
    jae .read_done
    
    call read_int
    jc .err_parse
    
    ; [memory] Store in array_orig using [base + idx*4] addressing
    mov [array_orig + edi*4], eax
    inc edi
    jmp .read_loop
    
.read_done:
    ; [memory] Copy array_orig to array_copy using rep movsd
    mov esi, array_orig
    mov edi, array_copy
    mov ecx, [n]
    cld
    rep movsd               ; Copy ecx doublewords
    
    ; [loops] [memory] Reverse array_copy to array_rev
    mov ecx, [n]            ; Loop count
    xor esi, esi            ; Source index (0 to n-1)
    mov edi, [n]
    dec edi                 ; Destination index (n-1 down to 0)
    
.reverse_loop:
    ; Load from array_copy using base+idx*4
    mov eax, [array_copy + esi*4]
    ; Store to array_rev using base+idx*4
    mov [array_rev + edi*4], eax
    inc esi
    dec edi
    dec ecx
    jnz .reverse_loop
    
    ; [logic] [math] Check if original array is a palindrome by comparing pairs
    mov ecx, [n]
    shr ecx, 1              ; [math] Only check up to n/2 pairs
    jz .palindrome_yes      ; If n < 2, it's always palindrome (but n >= 5)
    
    xor esi, esi            ; Start index
    mov edi, [n]
    dec edi                 ; End index
    
.palindrome_loop:
    mov eax, [array_orig + esi*4]
    mov ebx, [array_orig + edi*4]
    cmp eax, ebx
    jne .palindrome_no
    
    inc esi
    dec edi
    dec ecx
    jnz .palindrome_loop
    
.palindrome_yes:
    mov dword [is_palindrome], 1
    jmp .print_results
    
.palindrome_no:
    mov dword [is_palindrome], 0
    
.print_results:
    ; [I/O] Print "Original: "
    mov ecx, msg_orig
    call print_string
    
    ; [I/O] Print array_orig
    mov esi, array_orig
    call print_array
    
    ; [I/O] Print "Reversed: "
    mov ecx, msg_rev
    call print_string
    
    ; [I/O] Print array_rev
    mov esi, array_rev
    call print_array
    
    ; [I/O] Print palindrome status
    mov eax, [is_palindrome]
    test eax, eax
    jz .print_pal_no
    mov ecx, msg_pal_yes
    call print_string
    jmp .exit_success
    
.print_pal_no:
    mov ecx, msg_pal_no
    call print_string
    
.exit_success:
    ; [I/O] Exit with code 0
    mov eax, 1              ; sys_exit
    xor ebx, ebx            ; status = 0
    int 0x80

.err_invalid_n:
    ; [I/O] Print invalid n error
    mov ecx, msg_err_n
    call print_string
    mov eax, 1              ; sys_exit
    mov ebx, 1              ; status = 1
    int 0x80

.err_parse:
    ; [I/O] Print parsing error
    mov ecx, msg_err_parse
    call print_string
    mov eax, 1              ; sys_exit
    mov ebx, 1              ; status = 1
    int 0x80

; ==========================================
; Helpers / Subroutines
; ==========================================

; [I/O] Returns next char in AL from stdin buffer
; Carry flag (CF) is set on EOF/error
get_char:
    push ebx
    push ecx
    push edx
    
    mov eax, [input_pos]
    cmp eax, [input_end]
    jb .read_from_buf
    
    ; Buffer is empty, read from stdin
    mov eax, 3              ; sys_read
    mov ebx, 0              ; stdin
    mov ecx, input_buf
    mov edx, 1024
    int 0x80
    
    test eax, eax
    jle .eof                ; EOF or error
    
    mov [input_end], eax    ; bytes read
    xor edx, edx
    mov [input_pos], edx    ; reset position to 0
    
.read_from_buf:
    mov edx, [input_pos]
    movzx eax, byte [input_buf + edx]
    inc edx
    mov [input_pos], edx
    clc                     ; success
    pop edx
    pop ecx
    pop ebx
    ret

.eof:
    stc                     ; EOF
    pop edx
    pop ecx
    pop ebx
    ret

; [parse] Read an integer from stream
; Output: EAX - the integer
;         CF set if EOF/error and no digits read
read_int:
    push ebx
    push ecx
    push edx
    push edi                ; Save EDI as we use it for accumulator
    
    ; Skip whitespace
.skip_ws:
    call get_char
    jc .eof
    
    cmp al, ' '
    je .skip_ws
    cmp al, 9               ; tab
    je .skip_ws
    cmp al, 10              ; lf
    je .skip_ws
    cmp al, 13              ; cr
    je .skip_ws
    
    ; Non-whitespace char found. Check for sign.
    xor ecx, ecx            ; sign: 0 = positive, 1 = negative
    cmp al, '-'
    jne .check_plus
    mov ecx, 1
    jmp .read_first_digit
.check_plus:
    cmp al, '+'
    je .read_first_digit
    
    ; Must be digit
    cmp al, '0'
    jb .invalid
    cmp al, '9'
    ja .invalid
    
    movzx ebx, al
    sub ebx, '0'
    mov edi, ebx            ; EDI is the accumulator
    mov edx, 1              ; count = 1
    jmp .digit_loop

.read_first_digit:
    call get_char
    jc .invalid
    
    cmp al, '0'
    jb .invalid
    cmp al, '9'
    ja .invalid
    
    movzx ebx, al
    sub ebx, '0'
    mov edi, ebx
    mov edx, 1
    jmp .digit_loop

.digit_loop:
    call get_char
    jc .done_digits
    
    cmp al, '0'
    jb .non_digit
    cmp al, '9'
    ja .non_digit
    
    ; [math] Multiply accumulator by 10 and add new digit
    imul edi, 10
    movzx ebx, al
    sub ebx, '0'
    add edi, ebx
    inc edx
    jmp .digit_loop

.non_digit:
    ; Non-digit consumed, we are done
    jmp .done_digits

.done_digits:
    mov eax, edi            ; Move accumulated value to EAX for return
    test ecx, ecx
    jz .positive
    ; [math] Negate for negative input
    neg eax
.positive:
    clc
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret

.invalid:
.eof:
    stc
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret

; [I/O] Print null-terminated string in ECX
print_string:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    
    mov edi, ecx
    xor edx, edx
.len_loop:
    cmp byte [edi + edx], 0
    je .print
    inc edx
    jmp .len_loop
.print:
    test edx, edx
    jz .done
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    int 0x80
.done:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; [I/O] [math] Print signed integer in EAX
print_num:
    pusha
    
    test eax, eax
    jns .positive
    
    ; [I/O] Print '-'
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, minus_char
    mov edx, 1
    int 0x80
    pop eax
    
    ; [math] Negate to print positive part
    neg eax
    
.positive:
    test eax, eax
    jnz .p
    
    ; [I/O] Print '0'
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
    xor ecx, ecx            ; digit count
.l:
    ; [math] Divide by 10 to extract digits
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    inc ecx
    test eax, eax
    jnz .l
    
    ; [I/O] Print the formatted digits
    mov edx, ecx
    mov ecx, edi
    mov eax, 4
    mov ebx, 1
    int 0x80
    
    popa
    ret

; [I/O] Prints array of [n] elements starting at address in ESI
print_array:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov ecx, [n]
    xor edi, edi            ; index = 0
.loop:
    cmp edi, ecx
    jae .done
    
    ; [memory] Load element using base+idx*4
    mov eax, [esi + edi*4]
    call print_num
    
    ; [I/O] Space separator if not last element
    mov edx, ecx
    dec edx
    cmp edi, edx
    jae .no_space
    
    push ecx
    mov eax, 4
    mov ebx, 1
    mov ecx, space_char
    mov edx, 1
    int 0x80
    pop ecx
    
.no_space:
    inc edi
    jmp .loop
    
.done:
    ; [I/O] Print newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
