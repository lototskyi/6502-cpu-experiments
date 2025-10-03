PORTB = $8000
PORTA = $8001
DDRB = $8002
DDRA = $8003
T1CL = $8004
T1CH = $8005
ACR = $800b
IFR = $600d
 
 .org $c000

reset:
 lda #%11111111
 sta DDRA
 lda #0
 sta PORTA
 sta ACR
 
loop:
 inc PORTA			; Turn LED on
 jsr delay
 dec PORTA			; Turn LED off
 jsr delay
 jmp loop
 
delay:
 lda #$50
 sta T1CL
 lda #$c3
 sta T1CH
delay1:
 bit IFR
 bvc delay1
 lda T1CL			; clear interrupt flag
 rts
 

irq:
 rti
nmi:
 rti
 
 .org $fffa
 .word nmi
 .word reset
 .word irq