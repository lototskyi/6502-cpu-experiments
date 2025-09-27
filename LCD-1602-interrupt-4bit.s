PORTB = $8000
PORTA = $8001
DDRB = $8002
DDRA = $8003

; 6522 registers
IFR = $800d
IER = $800e
PCR = $800c

E  = %01000000
RW = %00100000
RS = %00010000 

value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes
counter = $020a ; 2 bytes
 
 .org $c000

reset:
 ldx #$ff		; Initialize stack pointer to 0x01ff
 txs
 cli
 
 ; 6522 interrupt configuration
 lda #$82 ; set CA1 active
 sta IER
 lda #$01
 sta PCR

 lda #%11111111	; Set all pins on port B to output
 sta DDRB
 
 lda #%00000000	; Set all pins on port A to input
 sta DDRB
 
 
 jsr lcd_init
 lda #%00101000	; Set 4-bit mode; 2-line display; 5x8 font
 jsr lcd_instruction
 lda #%00001110	; Display on; Cursor on; Blink off
 jsr lcd_instruction
 lda #%00000110	; Increment and shift cursor; don't shift display
 jsr lcd_instruction
 lda #%00000001 ; Clear display
 jsr lcd_instruction

 lda #0
 sta counter
 sta counter + 1

loop:
 lda #%00000010 ; Home
 jsr lcd_instruction

 lda #0
 sta message
 
 ; Initialize value to be the number to convert
 sei
 lda counter
 sta value
 lda counter + 1
 sta value + 1
 cli

divide:
 ; Initialize the remainder to zero
 lda #0
 sta mod10
 sta mod10 + 1
 clc
 
 ldx #16
divloop:
 ; Rotate quotient and remainder
 rol value
 rol value + 1
 rol mod10
 rol mod10 + 1
 
 ; a,y = dividend - divisor
 sec
 lda mod10
 sbc #10
 tay ; save low byte in Y
 lda mod10 + 1
 sbc #0
 bcc ignore_result ; branch if dividend < divisor
 sty mod10
 sta mod10 + 1

ignore_result:
 dex
 bne divloop
 rol value ; shift in the last bit of the quotient
 rol value + 1

 lda mod10
 clc
 adc #"0"
 jsr push_char

 ; if value != 0, then continue dividing
 lda value
 ora value + 1
 bne divide ; branch if value not zero

 ldx #0
print:
 lda message,x
 beq loop
 jsr print_char
 inx
 jmp print


 jmp loop
 
number: .word 1729

; Add the character in the A register to the beginning of the
; null-terminated string `message`
push_char:
 pha ; Push new first char onto stack
 ldy #0
 
char_loop:
 lda message,y ; Get char on string and put into X
 tax
 pla
 sta message,y ; Pull char off stack and add it to the string
 iny
 txa
 pha           ; Push char from string onto stack
 bne char_loop
 
 pla
 sta message,y ; Pull the null off the stack and to the end of the string
 
 rts
 
lcd_wait:
 pha			; push A register into stack
 lda #%11110000 ; LCD data input
 sta DDRB
lcd_busy:
 lda #RW
 sta PORTB
 lda #(RW | E)
 sta PORTB
 lda PORTB      ; Read high nibble
 pha            ; and put on stack since it has the busy flag
 lda #RW
 sta PORTB
 lda #(RW | E)
 sta PORTB
 lda PORTB      ; Read low nibble
 pla            ; Get high nible off stack
 and #%00001000
 bne lcd_busy   ; branch if Z not 0 (LCD is busy)
 
 lda #RW
 sta PORTB
 lda #%11111111 ; Port B is output
 sta DDRB
 pla
 rts
 
lcd_init:
 lda #%00000010 ; Set 4-bit mode
 sta PORTB
 ora #E
 sta PORTB
 and #%00001111
 sta PORTB
 rts
 
lcd_instruction:
 jsr lcd_wait
 pha
 lsr
 lsr
 lsr
 lsr
 sta PORTB      ; Send high 4 bits
 ora #E         ; Set E bit to send instruction
 sta PORTB
 eor #E			; Clear E bit
 sta PORTB
 pla
 and #%00001111 ; Send low 4 bits
 sta PORTB
 ora #E
 sta PORTB
 eor #E
 sta PORTB
 rts
 
print_char:
 jsr lcd_wait
 pha
 lsr
 lsr
 lsr
 lsr            ; Send high 4 bits
 ora #RS        ; Set RS
 sta PORTB
 ora #E         ; Set E bit to send instruction
 sta PORTB
 eor #E         ; Clear E bita
 sta PORTB
 pla
 and #%00001111 ; Send low 4 bits
 ora #RS
 sta PORTB
 ora #E
 sta PORTB
 eor #E
 sta PORTB
 rts

nmi:
irq:
 inc counter
 bne exit_irq
 inc counter + 1
exit_irq:
 bit PORTA		; clear interrupt by reading from PORTA
 rti
 
 .org $fffa
 .word nmi
 .word reset
 .word irq