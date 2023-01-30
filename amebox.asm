; AMEBOX - BY GUN7SUM, 2023.01.30
; a DOS game. Your screen will appear some colorful block when you pressed alphabet key or number key.
; Press Esc or Ctrl-Break to quit.

[BITS 16]
[INSTRSET "i486p"]	

		ORG		0x100

BUFFER_SEG		EQU		0x7000
BUFFER_ADDR		EQU		0
		
Main:
		MOV		AX, CS
		MOV		DS, AX
		MOV		ES, AX
		
.initscr1:
		CALL	InitScreen
		
		MOV		BX, __msg_welcome
		CALL	PrintStr


.wait1:
		MOV		AH, 0x00
		INT		0x16
		
.initsrc2:
		CALL	InitScreen
		
		MOV		AX, 0x0100
		MOV		CX, 0x2e0f
		INT		0x10
		
		MOV		AX, ES
		PUSH	AX
		
		MOV		AX, BUFFER_SEG
		MOV		ES, AX
		
		MOV		BX, BUFFER_ADDR
		MOV		AL, 0
		MOV		CX, 1024
		CALL	Memset
		
		POP		AX
		MOV		ES, AX
		
.wait2:
		MOV		AH, 0x00
		INT		0x16
		
		CMP		AX, 0x5300
		JE		.exit
		CMP		AX, 0x011b
		JE		.exit
		
		PUSH	AX
		
		MOV		DH, 'a'
		MOV		DL, 'z'
		CALL	Range8bit
		CMP		AX, 0
		JE		.alphabet
		
		POP		AX
		PUSH	AX
		
		MOV		DH, 'A'
		MOV		DL, 'Z'
		CALL	Range8bit
		CMP		AX, 0
		JE		.alphabet
		
		POP		AX
		PUSH	AX
		
		MOV		DH, '0'
		MOV		DL, 'Z'
		CALL	Range8bit
		CMP		AX, 0
		JE		.number
		
		POP		AX
		JMP		.wait2
		
.alphabet:
		POP		AX
		
		MOV		BX, 1000
		MOV		DX, AX
		CALL	Random
		
		CALL	ApplyAlphabet
		
		JMP		.wait2
		
.number:
		POP		AX
		
		PUSH	AX
		MOV		BX, 2
		MOV		DX, AX
		CALL	Random
		
		CMP		AX, 0
		JE		.row
		CMP		AX, 1
		JE		.line
.row:
		POP		AX
		MOV		BX, 40
		MOV		DX, AX
		CALL	Random
		
		CALL	ApplyRow
		
		JMP		.wait2
		
.line:
		POP		AX
		MOV		BX, 25
		MOV		DX, AX
		CALL	Random
		
		CALL	ApplyLine
		
		JMP		.wait2
.exit:
		CALL	InitScreen
		
		MOV		BX, __msg_exit
		CALL	PrintStr
		
		RET

; Function Part

; Function InitScreen:
;	IN - (null)
; 	OUT - (null)
InitScreen:
		PUSHA
		MOV		AX, 0x0003
		INT		0x10
		
		MOV		AX, 0x0200
		MOV		DX, 0
		MOV		BH, 0
		INT		0x10
		
		MOV		AX, 0x0100
		MOV		CX, 0x0e0f
		INT		0x10
		
		POPA
		RET
		
; Function PrintStr:
; 	IN  - [DS:BX] 	WORD	String address
;	 	  [DS:BX+2]	WORD	Print coord
;		  [DS:BX+4]	WORD	Print color
;	OUT - (null)
PrintStr:
		PUSHA
		
		MOV		SI, BX
		MOV		BX, [SI]
		MOV		DX, [SI+2]
.loop1:
		CALL	Strlen
		PUSH	AX
		
		MOV		BP, BX
		MOV		BH, 0
		MOV		BL, [SI+4]
		MOV		AX, 0x1301
		INT		0x10
		
		POP		AX
		CMP		AH, 0x00
		JE		.ret
		
		INC		DH
		MOV		BX, BP
		ADD		BX, CX
		ADD		BX, 1
		JMP		.loop1
.ret:
		POPA
		RET
		
; Function Strlen:
;	IN  - 	DS:BX		String address
;	OUT - 	CX			String length
;	    -	AH			The last char of string
Strlen:
		PUSH	BX
		MOV		CX, 0
.loop1:
		CMP		BYTE[BX], 0
		JE		.ret
		CMP		BYTE[BX], 0x0a
		JE		.ret
		INC		BX
		INC		CX
		JMP		.loop1
.ret:
		MOV		AH, BYTE[BX]
		POP		BX
		RET
		
; Function Memset:
;	IN  -	ES:BX		Buffer address
;		-	CX			Buffer size
;		-	AL			Fill char
;	OUT -	(null)
Memset:
		PUSH	BX
		PUSH	CX
.loop1:
		MOV		[ES:BX], AL
		INC		BX
		DEC		CX
		CMP		CX, 0
		JNE		.loop1
.ret:
		POP		CX
		POP		BX
		RET
		
; Function Random:
;	IN	-	BX			Max random number
;		-	DX			Argument
;	OUT	-	AX			a Random number
Random:
		PUSH	BX
		PUSH	CX
		PUSH	DX
		
		MOV		AX, 0x2c00
		INT		0x21
		
		ADD		CX, DX
		XOR		CX, 0xffff
		
		POP		DX
		ADD		CX, DX
		
		MOV		DX, 0
		MOV		AX, CX
		DIV		BX
		
		MOV		AX, DX
		
		POP		CX
		POP		BX
		RET
		
; Function Range8bit:
;	IN	-	AL		Target number		
;		- 	DX		DH is min and DL in max
;	OUT -	AX		0 is in the range and 1 is out
Range8bit:
		PUSH	CX
		MOV		CX, 1
		
		CMP		AL, DH
		JB		.ret
		CMP		AL, DL
		JA		.ret
		
		MOV		CX, 0
.ret:
		MOV		AX, CX
		POP		CX
		RET
		
; Function ApplyBlock:
;	IN	-	AX			Target block
;	OUT - 	AX			a New number	
ApplyBlock:
		PUSH	BX
		PUSH	DX
		
		MOV		BX, ES
		PUSH	BX
		
		MOV		BX, BUFFER_SEG
		MOV		ES, BX
		MOV		BX, AX
		
		MOV		DH, 0
		MOV		DL, [ES:BX]
		INC		DL
		
		CMP		DL, 16
		JB		.ret
		
		MOV		DL, 0
.ret:
		MOV		[ES:BX], DL
		MOV		AX, DX
		
		POP		BX
		MOV		ES, BX
		
		POP		DX
		POP		BX
		RET
		
; Function Block2Coord
;	IN	-	AX		Block
;	OUT	-	DX		Coord
Block2Coord:
		PUSH	BX
		PUSH	AX
		
		MOV		BL, 40
		DIV		BL
		MOV		DX, AX
		
		POP		AX
		POP		BX
		RET
		
; Function Coord2Block
;	IN	-	AX		Coord
;	OUT -	DX		Block
Coord2Block:
		PUSH	CX
		PUSH	BX
		PUSH	AX
		
		MOV		BH, 0
		MOV		BL, AL
		
		MOV		AL, AH
		MOV		CL, 40
		MUL		CL
		
		ADD		AX, BX
		MOV		DX, AX

		POP		AX
		POP		BX
		POP		CX
		RET

; Function ApplyAlphabet
;	IN	-	AX			Target block
;	OUT - 	(null)
ApplyAlphabet:
		PUSHA
		
		MOV		SI, AX
		
		CALL	ApplyBlock
		
		CMP		AX, 1
		JE		.ret

.instance:
		MOV		BX, coords
		MOV		CX, AX
		
		MOV		AX, SI
		CALL	Block2Coord
		
		ADD		DH, CL
		MOV		WORD [BX], DX
		
		SUB		DH, CL
		SUB		DH, CL
		MOV		WORD [BX+2], DX
		
		ADD		DH, CL
		ADD		DL, CL
		MOV		WORD [BX+4], DX
		
		SUB		DL, CL
		SUB		DL, CL
		MOV		WORD [BX+6], DX

.loop1:
		MOV		AX, WORD [BX]
		PUSH	AX
		CALL	Coord2Block
		MOV		AX, DX
		CALL	ApplyBlock
		POP		AX
		DEC		AH
		DEC		AL
		MOV		WORD [BX], AX
		
		MOV		AX, WORD [BX+2]
		PUSH	AX
		CALL	Coord2Block
		MOV		AX, DX
		CALL	ApplyBlock
		POP		AX
		INC		AH
		INC		AL
		MOV		WORD [BX+2], AX
		
		MOV		AX, WORD [BX+4]
		PUSH	AX
		CALL	Coord2Block
		MOV		AX, DX
		CALL	ApplyBlock
		POP		AX
		INC		AH
		DEC		AL
		MOV		WORD [BX+4], AX
		
		MOV		AX, WORD [BX+6]
		PUSH	AX
		CALL	Coord2Block
		MOV		AX, DX
		CALL	ApplyBlock
		POP		AX
		DEC		AH
		INC		AL
		MOV		WORD [BX+6], AX
		
		DEC		CX
		CMP		CX, 0
		JNE		.loop1
		
.ret:
		CALL	RefreshScreen
		POPA
		RET

; Function ApplyRow
;	IN 	-	AX		Target row
;	OUT	-	(null)
ApplyRow:
		PUSHA

		MOV		CX, AX
.loop1:
		MOV		AX, CX
		CALL	Coord2Block
		MOV		AX, DX
		CALL	ApplyBlock
		
		INC		CH
		CMP		CH, 25
		JB		.loop1
		
.ret:
		CALL	RefreshScreen
		POPA
		RET
		
; Function ApplyLine
;	IN 	-	AX		Target line
;	OUT	-	(null)
ApplyLine:
		PUSHA
		
		MOV		AH, AL
		MOV		AL, 0
		MOV		CX, AX
		
.loop1:
		MOV		AX, CX
		CALL	Coord2Block
		MOV		AX, DX
		CALL	ApplyBlock
		
		INC		CL
		CMP		CL, 40
		JB		.loop1
		
.ret:
		CALL	RefreshScreen
		POPA
		RET

; Function RefreshScreen
;	IN 	-	(null)
;	OUT - 	(null)
RefreshScreen:
		PUSHA
		
		MOV		BX, ES
		PUSH	BX
		MOV		DX, DS
		PUSH	DX
		
		MOV		DX, BUFFER_SEG
		MOV		DS, DX
		MOV		SI, BUFFER_ADDR
		
		MOV		BX, 0xb800
		MOV		ES, BX
		MOV		BX, 0
		
		MOV		CX, 0
.loop1:
		MOV		AL, [DS:SI]
		CMP		AL, 0
		JE		.put
		
		MOV		AH, 16
		SUB		AH, AL
		MOV		AL, AH
.put:
		MOV		BYTE [ES:BX], 0xdb
		MOV		BYTE [ES:BX+1], AL
		MOV		BYTE [ES:BX+2], 0xdb
		MOV		BYTE [ES:BX+3], AL
		
		INC		SI
		INC		CX
		ADD		BX, 4
		
		CMP		CX, 1000
		JB		.loop1
		
.ret:
		POP		DX
		MOV		DS, DX
		POP		BX
		MOV		ES, BX
		
		POPA
		RET
		
; Data Part
__msg_welcome:
		DW		msg_welcome, 0x0101
		DB		0x0f
		ALIGN	8
		
__msg_exit:
		DW		msg_exit, 0x0000
		DB		0x07
		ALIGN	8

msg_welcome:
		DB		"AMEBOX - BY GUN7SUM, 2023.01.30 [build 6]", 0x0a, 0x0a, "a DOS game. Your screen will appear some colorful block", 0x0a, "when you press alphabet or number key.", 0x0a, 0x0a
		DB		"Press any key to continue.", 0x0a, 0
		
msg_exit:
		DB		"The exit is right there.", 0x0a, 0
		
coords:
		DW		0, 0, 0, 0
