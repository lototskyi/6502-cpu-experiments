PORTB = $8000
PORTA = $8001
DDRB = $8002
DDRA = $8003

ACR = $800B
IFR = $800D
IER = $800E

E  = %01000000
RW = %00100000
RS = %00010000

 .org $c000
 
reset:
 lda #%10111111 ; Set all pins on port A
 sta DDRA
 lda #1
 sta PORTA
 lda #%11111111	; Set all pins on port B to output
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
 
 ; Transmit
 lda #1				; Serial idle
 sta PORTA
 
 lda #"*"
 sta $0200
 
 lda #$01
 trb PORTA			; Send start bit
 
 ldx #8				; Send 8 bits
write_bit:
 jsr bit_delay
 
 ror $0200			; Rotate the next bit right into C flag
 bcs send_1
 trb PORTA			; Send a 0
 jmp tx_done
send_1:
 tsb PORTA			; Send a 1
 
tx_done:
 dex
 bne write_bit
 
 jsr bit_delay
 tsb PORTA			; Stop bit
 jsr bit_delay

; Receive
rx_wait:
 bit PORTA			; Put PORTA.6 into V flag
 bvs rx_wait		; Loop if no start bit yet
 
 jsr half_bit_delay
 
 ldx #8
read_bit:
 jsr bit_delay
 bit PORTA
 bvs recv_1
 clc				; We read a 0, put a 0 into the C flag
 jmp rx_done
recv_1:
 sec				; We read a 1, put a 1 into the C flag
rx_done: 
 ror				; Rotate A rigester, putting C flag as new MSB
 dex
 bne read_bit
 
 ; All 8 bits are now in A register
 jsr print_char
 
 jsr bit_delay
 jmp rx_wait

bit_delay:
 phx
 ldx #30
bit_delay_1:
 dex
 bne bit_delay_1
 plx
 rts

half_bit_delay:
 phx
 ldx #15
half_bit_delay_1:
 dex
 bne half_bit_delay_1
 plx
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
 
; Add the character in the A register to the beginning of the
; null-terminated string `message`
push_char:
 pha ; Push new first char onto stack
 ldy #0
 
irq:
 
 rti
 
 .org $fffc
 .word reset
 .word irq