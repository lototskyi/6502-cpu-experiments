PORTB = $8000
PORTA = $8001
DDRB = $8002
DDRA = $8003
 
 .org $c000

reset:
 lda #%11111111
 sta DDRA
 lda #0
 sta PORTA
 
loop:
 inc PORTA			; Turn LED on
 jsr delay
 dec PORTA			; Turn LED off
 jsr delay
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
 

irq:
 rti
nmi:
 rti
 
 .org $fffa
 .word nmi
 .word reset
 .word irq