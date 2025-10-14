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

ACIA_DATA = $8400
ACIA_STATUS = $8401
ACIA_CMD = $8402
ACIA_CTRL = $8403

 .org $c000
 
reset:
 ldx #$ff
 txs
 
 lda #%10111111 	; Set all pins on port A
 sta DDRA
 lda #%11111111	; Set all pins on port B to output
 sta DDRB
 
 lda #0
 sta ACIA_CMD
 
 jsr lcd_init
 lda #%00101000	; Set 4-bit mode; 2-line display; 5x8 font
 jsr lcd_instruction
 lda #%00001110	; Display on; Cursor on; Blink off
 jsr lcd_instruction
 lda #%00000110	; Increment and shift cursor; don't shift display
 jsr lcd_instruction
 lda #%00000001 ; Clear display
 jsr lcd_instruction
 
 
 lda #$00
 sta ACIA_STATUS	; soft reset (value not important)
 
 lda #$1f 			; N-8-1, 19200 baud
 sta ACIA_CTRL
 
 lda #$0b			; no parity, no echo, no interrupts
 sta ACIA_CMD

 ldx #0
send_msg:
 lda message,x
 beq done
 jsr send_char
 inx
 jmp send_msg
done:
 
 
rx_wait:
 lda ACIA_STATUS
 and #$08			; check rx buffer status flag
 beq rx_wait		; loop if rx buffer empty

 lda ACIA_DATA
 jsr send_char		; echo 
 jsr print_char
 jmp rx_wait
 
message: .asciiz "Hello, world!"
 
send_char:
 sta ACIA_DATA
 pha
tx_wait:
 lda ACIA_STATUS
 and #$10			; check tx buffer status flag
 beq tx_wait		; loop if tx buffer not empty
 jsr tx_delay
 pla
 rts
 
tx_delay:
 phx
 ldy #3
delay2:
 ldx #105
delay1:
 dex
 bne delay1
 dey
 bne delay2
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

irq:
 
 rti
 
 .org $fffc
 .word reset
 .word irq