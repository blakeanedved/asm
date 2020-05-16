segment .data
	puts_gets_format_string db "%s",0 ; DO NOT DELETE, TEMPORARY FOR GETS() AND PUTS()
	holdrand dd 1                     ; DO NOT DELETE, TEMPORARY FOR RAND()
	printf_format db "%d",10,0
	string_format db "%s",0
	get_num_string db "Please enter a number: ",0
	wrong_answer db "Wrong! Guess again.",10,0
	right_answer db "Correct! You Won!",10,0

segment .bss
	scanf_int_temp resb 1             ; DO NOT DELETE, TEMPORARY FOR SCANF()
	getchar_temp resb 1               ; DO NOT DELETE, TEMPORARY FOR GETCHAR()

	num resb 1

segment .text
	global  asm_main

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********

	; srand(time(0))
	call time
	push eax
	call srand
	add esp, 4
	
	; eax = rand()
	call rand
	
	; eax %= 36
	push 10
	push eax
	call mod
	add esp, 8

	mov dword[num], eax

	; printf("%d\n", eax)
	;push dword[num]
	;push printf_format
	;call printf
	;add esp, 8

	start_game_loop:
		push get_num_string
		push string_format
		call printf
		add esp, 8

		call getchar
		sub eax, 48
		cmp eax, dword[num]
		je end_game_loop

		call getchar
		
		push wrong_answer
		push string_format
		call printf
		jmp start_game_loop
	end_game_loop:

	call getchar
	push right_answer
	push string_format
	call printf

	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

; push arguments in reverse order
; push format_string
; call printf
; no return value
printf:
	push ebp
	mov ebp, esp

	mov ebx, 1
	mov ecx, dword[ebp + 8]
	mov edx, 1
	sub esp, 4
	mov dword[ebp - 4], 0
	
	printf_start_loop:
		mov al, byte[ecx]
		cmp al, 0
		je printf_end_loop
		cmp al, '%'
		jne printf_normal
		
		inc ecx
		mov al, byte[ecx]
		cmp al, 'd'
		je printf_int
		cmp al, 's'
		je printf_string
		cmp al, 'c'
		je printf_char
		cmp al, '%'
		je printf_normal

		printf_int:
			mov edi, dword[ebp - 4]
			mov eax, dword[ebp + 12 + (edi * 4)]

			push eax
			call pitos
			
			inc ecx
			inc dword[ebp - 4]
			jmp printf_start_loop

		printf_string:
			mov esi, ecx
			mov edi, dword[ebp - 4]
			mov ecx, dword[ebp + 12 + (edi * 4)]
			
			printf_string_start_loop:
				mov al, byte[ecx]
				cmp al, 0
				je printf_string_end_loop
				mov eax, 0x04
				int 0x80
				inc ecx
				jmp printf_string_start_loop
			printf_string_end_loop:
			
			mov ecx, esi
			inc ecx
			inc dword[ebp - 4]
			jmp printf_start_loop

		printf_char:
			mov esi, ecx
			mov ecx, dword[ebp - 4]
			add ecx, ecx
			add ecx, ecx
			add ecx, ebp
			add ecx, 12

			mov eax, 0x04
			int 0x80
			mov ecx, esi
			inc ecx
			inc dword[ebp - 4]
			jmp printf_start_loop

		printf_normal:
			mov eax, 0x04
			int 0x80
			inc ecx
			jmp printf_start_loop
	printf_end_loop:

	mov esp, ebp
	pop ebp
	ret

; push arguments in reverse order (strings must have a length pushed before they are)
; push format_string
; call scanf
; no return value
scanf:
	push ebp
	mov ebp, esp

	sub esp, 8
	mov dword[ebp - 4], 0
	mov dword[ebp - 8], 0

	mov esi, dword[ebp + 8]

	scanf_start_loop:
		mov al, byte[esi]
		cmp al, 0
		je scanf_end_loop
		cmp al, '%'
		je scanf_inc
		cmp al, 'd'
		je scanf_int
		cmp al, 's'
		je scanf_string
		cmp al, 'c'
		je scanf_char
		
		scanf_int:

			mov ecx, 0

			scanf_int_clear_start_loop:
				cmp ecx, 10
				je scanf_int_clear_end_loop

				mov byte[scanf_int_temp + ecx], 0

				inc ecx

				jmp scanf_int_clear_start_loop
			scanf_int_clear_end_loop:

			mov eax, 0x03
			mov ebx, 0
			mov edi, dword[ebp - 4]
			mov edi, [ebp + 12 + (edi * 4)]
			mov ecx, scanf_int_temp
			mov edx, 1
			mov dword[ebp + 8], esi
			mov esi, 10
	
			scanf_int_start_loop:
				mov eax, 0x03
				int 0x80
				cmp esi, 0
				je scanf_int_end_loop
				cmp byte[ecx], 10
				je scanf_int_end_loop
				inc ecx
				dec esi
				jmp scanf_int_start_loop
			scanf_int_end_loop:
			
			push scanf_int_temp
			call stoi

			mov esi, dword[ebp + 8]

			mov [edi], eax

			mov dword[ecx], 0
			inc dword[ebp - 4]
			jmp scanf_inc
		scanf_string:
			mov eax, 0x03
			mov ebx, 0
			mov edi, dword[ebp - 4]
			mov ecx, dword[ebp + 12 + (edi * 4)]
			mov edi, dword[ebp + 12 + (edi * 4) + 4]
			mov edx, 1

			scanf_string_start_loop:
				mov eax, 0x03
				int 0x80
				cmp edi, 0
				je scanf_string_end_loop
				cmp byte[ecx], 10
				je scanf_string_end_loop
				inc ecx
				dec edi
				jmp scanf_string_start_loop
			scanf_string_end_loop:
			
			mov dword[ecx], 0
			inc dword[ebp - 4]
			inc dword[ebp - 4]
			jmp scanf_inc
		
		scanf_char:
			
			call getchar
			
			mov ecx, dword[ebp - 4]
			mov ecx, dword[ebp + 12 + (ecx * 4)]

			mov byte[ecx], al

			inc dword[ebp - 4]
			jmp scanf_inc

		scanf_inc:
			inc esi
			jmp scanf_start_loop

	scanf_end_loop:			
	
	mov esp, ebp
	pop ebp
	ret

; had problems with itos so i made it p(rint)itos
; push num
; call pitos
; no return value
pitos:
	push ebp
	mov ebp, esp
	
	sub esp, 12
	mov dword[ebp - 4], ebx
	mov dword[ebp - 8], ecx
	mov dword[ebp - 12], edx
	mov eax, dword[ebp + 8]
	mov ebx, 10
	mov edi, 0
	
	pitos_start_loop:
		cmp eax, 0
		je pitos_end_loop
		mov edx, 0
		div ebx
		dec esp
		add edx, 48
		mov byte[esp], dl
		inc edi
		jmp pitos_start_loop
	pitos_end_loop:

	pitos_start_print_loop:
		cmp edi, 0
		je pitos_end_print_loop
		mov eax, 0x04
		mov ebx, 1
		mov ecx, esp
		mov edx, 1
		int 0x80
		inc esp
		dec edi
		jmp pitos_start_print_loop
	pitos_end_print_loop:

	mov ebx, dword[ebp - 4]
	mov ecx, dword[ebp - 8]
	mov edx, dword[ebp - 12]
	
	mov esp, ebp
	pop ebp
	ret

; push string
; call stoi
; returned in eax
stoi:
	push ebp
	mov ebp, esp

	sub esp, 12
	mov dword[ebp - 4], ebx
	mov dword[ebp - 8], ecx
	mov dword[ebp - 12], edx
	
	mov eax, 0
	mov ebx, dword[ebp + 8]
	mov ecx, 1
	mov esi, 0

	stoi_start_loop:
		cmp byte[ebx], 0
		je stoi_end_loop
		cmp byte[ebx], 10
		je stoi_end_loop
		mov eax, 0
		mov al, byte[ebx]
		sub eax, 48
	
		sub esp, 4
		mov dword[esp], eax

		inc ebx
		inc esi

		jmp stoi_start_loop
	stoi_end_loop:

	mov ebx, 0

	stoi_convert_start_loop:
		cmp esi, 0
		je stoi_convert_end_loop

		mov eax, dword[esp]
		add esp, 4
		mul ecx
		add ebx, eax
		mov eax, ecx
		mov ecx, 10
		mul ecx
		mov ecx, eax

		dec esi

		jmp stoi_convert_start_loop
	stoi_convert_end_loop:

	mov eax, ebx

	mov ebx, dword[ebp - 4]
	mov ecx, dword[ebp - 8]
	mov edx, dword[ebp - 12]

	mov esp, ebp
	pop ebp
	ret

; push char
; call putchar
; no return value
putchar:
	push ebp
	mov ebp, esp
	
	sub esp, 16
	mov dword[ebp - 4], eax
	mov dword[ebp - 8], ebx
	mov dword[ebp - 12], ecx
	mov dword[ebp - 16], edx
	
	mov eax, 0x04
	mov ebx, 1
	mov ecx, ebp
	add ecx, 8
	mov edx, 1

	int 0x80

	mov eax, dword[ebp - 4]
	mov ebx, dword[ebp - 8]
	mov ecx, dword[ebp - 12]
	mov edx, dword[ebp - 16]

	mov esp, ebp
	pop ebp
	ret

; call getchar
; returned in al
getchar:
	push ebp
	mov ebp, esp

	sub esp, 12
	mov dword[ebp - 4], ebx
	mov dword[ebp - 8], ecx
	mov dword[ebp - 12], edx
	
	mov eax, 0x03
	mov ebx, 0
	mov ecx, getchar_temp
	mov edx, 1

	int 0x80
	mov eax, 0
	mov al, byte[getchar_temp]

	mov ebx, dword[ebp - 4]
	mov ecx, dword[ebp - 8]
	mov edx, dword[ebp - 12]

	mov esp, ebp
	pop ebp
	ret

; push string
; call puts
; no return value
puts:
	push ebp
	mov ebp, esp
	
	push dword[ebp + 8]
	push puts_gets_format_string
	call printf
	
	mov esp, ebp
	pop ebp
	ret

; push string_length
; push string
; call gets
; no return value
gets:
	push ebp
	mov ebp, esp
	
	push dword[ebp + 12]
	push dword[ebp + 8]
	push puts_gets_format_string
	call scanf
	
	mov esp, ebp
	pop ebp
	ret

; push seed
; call srand
; no return value
srand:
	push ebp
	mov ebp, esp

	sub esp, 4
	mov dword[ebp - 4], eax
	
	mov eax, dword[ebp + 8]
	mov dword[holdrand], eax

	mov eax, dword[ebp - 4]
	
	mov esp, ebp
	pop ebp
	ret

; call rand
; returned in eax
rand:
	push ebp
	mov ebp, esp
	
	sub esp, 4
	mov dword[ebp - 4], ebx

	mov eax, dword[holdrand]
	mov ebx, 214013
	mul ebx
	add eax, 2531011
	shr eax, 16
	and eax, 0x7fff
	mov dword[holdrand], eax
	
	mov ebx, dword[ebp - 4]

	mov esp, ebp
	pop ebp
	ret

; call time
; returned in eax
time:
	push ebp
	mov ebp, esp
	
	mov eax, 13
	push eax
	mov ebx, esp
	int 0x80
	pop eax
	
	mov esp, ebp
	pop ebp
	ret

; push exponent
; push base
; call pow
; returned in eax
pow:
	push ebp
	mov ebp, esp
	
	sub esp, 8
	mov dword[ebp - 4], ebx
	mov dword[ebp - 8], ecx

	mov eax, dword[ebp + 8]
	mov ebx, dword[ebp + 12]
	mov ecx, eax
	
	pow_start_loop:
		cmp ebx, 0
		je pow_end_loop
		mul ecx
		dec ebx
		jmp pow_start_loop
	pow_end_loop:

	mov ebx, dword[ebp - 4]
	mov ecx, dword[ebp - 8]
	
	mov esp, ebp
	pop ebp
	ret

; push mod
; push num
; call mod
; returned in eax
mod:
	push ebp
	mov ebp, esp
	
	sub esp, 8
	mov dword[ebp - 4], ebx
	mov dword[ebp - 8], ecx

	mov eax, dword[ebp + 8]
	mov ebx, dword[ebp + 12]
	mov edx, 0
	
	div ebx
	mov eax, edx

	mov ebx, dword[ebp - 4]
	mov edx, dword[ebp - 8]
	
	mov esp, ebp
	pop ebp
	ret
