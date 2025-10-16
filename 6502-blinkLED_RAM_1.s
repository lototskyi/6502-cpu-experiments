PORTB = $8000
PORTA = $8001
DDRB = $8002
DDRA = $8003

 .org $10FA

counter = $0280
 
reset:
 stz counter
 lda #%11111111 ; Set all pins on port A to output
 sta DDRA
 lda #0
 sta PORTA
 
loop:
 inc PORTA
 jsr delay
 dec PORTA
 jsr delay
 inc counter
 lda counter
 cmp #$0A
 beq halt
 jmp loop
 
delay:
 ldy #$ff
delay2:
 ldx #$ff
delay1:
 nop
 dex
 bne delay1
 dey
 bne delay2 
 rts
 
halt:
 jmp $ff00