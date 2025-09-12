 .org $c000
 
reset: 
 lda #$ff
 sta $8003
 
 lda #$50
 sta $8001

loop:
 ror
 sta $8001
 
 jmp loop
 
 .org $fffc
 .word reset
 .word $0000