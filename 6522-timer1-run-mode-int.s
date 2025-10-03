PORTB = $8000
PORTA = $8001
DDRB = $8002
DDRA = $8003
T1CL = $8004
T1CH = $8005
ACR = $800b
IFR = $800d
IER = $800e

ticks = $00
toggle_time = $04
 
 .org $c000

reset:
 lda #%11111111
 sta DDRA
 lda #0
 sta PORTA
 sta toggle_time
 jsr init_timer
 
loop:
 jsr update_led
 ;other stuff
 jmp loop
 
update_led:
 sec
 lda ticks
 sbc toggle_time
 cmp #25			; Have 250ms elapsed?
 bcc exit_update_led
 lda #$01
 eor PORTA
 sta PORTA			; Toggle LED
 lda ticks
 sta toggle_time
exit_update_led:
 rts
 
init_timer:
 lda #0
 sta ticks
 sta ticks + 1
 sta ticks + 2
 sta ticks + 3
 lda #%01000000
 sta ACR
 lda #$12
 sta T1CL
 lda #$48
 sta T1CH
 lda #%11000000
 sta IER
 cli
 rts
 

irq:
 bit T1CL
 inc ticks
 bne end_irq
 inc ticks + 1
 bne end_irq
 inc ticks + 2
 bne end_irq
 inc ticks + 3
end_irq:
 rti
nmi:
 rti
 
 .org $fffa
 .word nmi
 .word reset
 .word irq