; ==========================================
; Practice 15: Recursive Factorial & Call Counter
; Architecture: i386 (32-bit ELF)
; OS: Debian Linux (using int 0x80 syscalls)
; ==========================================

section .data
    ; [I/O] Messages
    prompt_n        db "Enter n (0..12): ", 0
    msg_fact        db "fact: ", 0
    msg_calls       db "calls: ", 0
    msg_err_n       db "Error: n must be between 0 and 12", 0xA, 0
    msg_err_parse   db "Error: failed to parse integer", 0xA, 0
    
    newline         db 0xA, 0
    minus_char      db "-", 0

section .bss
    ; [memory] Buffers
    n               resd 1
    calls           resd 1
    result_fact     resd 1
    
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
    
    ; [logic] Validate n (0..12)
    cmp eax, 0
    jl .err_invalid_n
    cmp eax, 12
    jg .err_invalid_n
    
    mov [n], eax
    
    ; Reset calls counter
    mov dword [calls], 0
    
    ; [loops] Call recursive factorial function
    ; Parameter is in EAX, result returned in EAX
    call fact
    mov [result_fact], eax
    
.print_results:
    ; [I/O] Print "fact: "
    mov ecx, msg_fact
    call print_string
    
    ; [I/O] Print factorial result
    mov eax, [result_fact]
    call print_num
    
    ; [I/O] Print newline
    mov ecx, newline
    call print_string
    
    ; [I/O] Print "calls: "
    mov ecx, msg_calls
    call print_string
    
    ; [I/O] Print calls count
    mov eax, [calls]
    call print_num
    
    ; [I/O] Print newline
    mov ecx, newline
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
; Recursive Factorial Subroutine
; ==========================================

; [loops] [memory] Recursive factorial function
; Input: EAX - parameter n
; Output: EAX - factorial of n
fact:
    ; [memory] Increment global calls counter
    inc dword [calls]
    
    ; Prologue
    push ebp
    mov ebp, esp
    
    ; [logic] Check base case: n <= 1
    cmp eax, 1
    jle .base_case
    
    ; Recursive case: fact(n) = n * fact(n-1)
    push eax                ; Save n on stack
    
    ; [math] Decrement n
    dec eax
    call fact               ; Recursive call: EAX = fact(n-1)
    
    pop ebx                 ; Restore n into EBX
    
    ; [math] Multiply fact(n-1) * n
    imul eax, ebx           ; EAX = EAX * EBX
    
    jmp .done
    
.base_case:
    mov eax, 1              ; fact(0) = 1, fact(1) = 1
    
.done:
    ; Epilogue
    mov esp, ebp
    pop ebp
    ret

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
