PORTB = $8000
PORTA = $8001
DDRB = $8002
DDRA = $8003

; 6522 registers
IFR = $800d
IER = $800e
PCR = $800c

kb_wptr = $0000
kb_rptr = $0001
kb_flags = $0002

RELEASE = %00000001
SHIFT   = %00000010

kb_buffer = $0200		; 256-byte kb buffer 0200-02ff

E  = %01000000
RW = %00100000
RS = %00010000 

 .org $c000

reset:
 ldx #$ff				; Initialize stack pointer to 0x01ff
 txs
 cli
 
 ; 6522 interrupt configuration
 lda #$82 				; set CA1 active
 sta IER
 lda #$01
 sta PCR

 lda #%11111111		; Set all pins on port B to output
 sta DDRB
 
 lda #%00000000		; Set all pins on port A to input
 sta DDRA
 
 
 jsr lcd_init
 lda #%00101000		; Set 4-bit mode; 2-line display; 5x8 font
 jsr lcd_instruction
 lda #%00001111		; Display on; Cursor on; Blink on
 jsr lcd_instruction
 lda #%00000110		; Increment and shift cursor; don't shift display
 jsr lcd_instruction
 lda #%00000001 		; Clear display
 jsr lcd_instruction

 lda #$00
 sta kb_wptr
 sta kb_rptr
 sta kb_flags
 
loop:
 sei
 lda kb_rptr
 cmp kb_wptr
 cli 
 bne key_pressed
 jmp loop
 
key_pressed:
 ldx kb_rptr
 lda kb_buffer, x
 jsr print_char
 inc kb_rptr
 jmp loop
  
lcd_wait:
 pha					; push A register into stack
 lda #%11110000 		; LCD data input
 sta DDRB
lcd_busy:
 lda #RW
 sta PORTB
 lda #(RW | E)
 sta PORTB
 lda PORTB      		; Read high nibble
 pha            		; and put on stack since it has the busy flag
 lda #RW
 sta PORTB
 lda #(RW | E)
 sta PORTB
 lda PORTB      		; Read low nibble
 pla            		; Get high nible off stack
 and #%00001000
 bne lcd_busy   		; branch if Z not 0 (LCD is busy)
 
 lda #RW
 sta PORTB
 lda #%11111111 		; Port B is output
 sta DDRB
 pla
 rts
 
lcd_init:
 lda #%00000010 		; Set 4-bit mode
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
 sta PORTB      		; Send high 4 bits
 ora #E         		; Set E bit to send instruction
 sta PORTB
 eor #E					; Clear E bit
 sta PORTB
 pla
 and #%00001111 		; Send low 4 bits
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
 lsr            		; Send high 4 bits
 ora #RS        		; Set RS
 sta PORTB
 ora #E         		; Set E bit to send instruction
 sta PORTB
 eor #E         		; Clear E bita
 sta PORTB
 pla
 and #%00001111 		; Send low 4 bits
 ora #RS
 sta PORTB
 ora #E
 sta PORTB
 eor #E
 sta PORTB
 rts



nmi:
 rti
 
keyboard_interrupt:
 pha
 txa
 pha
 
 lda kb_flags
 and #RELEASE			; check if we're releasing a key
 beq read_key			; otherwise, read the key
 
 lda kb_flags
 eor #RELEASE			; exclusive OR to set flags back
 sta kb_flags
 lda PORTA				; read key value that's being released
 cmp #$12				; left shift
 beq shift_up
 cmp #$59				; right shift
 beq shift_up
 jmp exit
 
shift_up:
 lda kb_flags
 eor #SHIFT				; flip the shift bit
 sta kb_flags
 jmp exit
 
read_key:
 lda PORTA
 cmp #$f0
 beq key_release
 
 cmp #$12				; left shift
 beq shift_down
 cmp #$59				; right shift
 beq shift_down
 
 cmp #$76        		; ESC
 beq esc_down
 
 cmp #$5a         		; Enter
 beq enter_down  
 
 tax
 lda kb_flags
 and #SHIFT
 bne shifted_key
 
 lda keymap, x
 jmp push_key

shifted_key:
 lda keymap_shifted, x
 
push_key:
 ldx kb_wptr
 sta kb_buffer, x
 inc kb_wptr
 jmp exit
 
esc_down:
 lda #%00000001 		; Clear display
 jsr lcd_instruction
 jmp exit
 
enter_down:
 lda #%11000000 		; Move cursor to the next row (+0x40)
 jsr lcd_instruction
 jmp exit 

shift_down:
 lda kb_flags
 ora #SHIFT
 sta kb_flags
 jmp exit
 
key_release:
 lda kb_flags
 ora #RELEASE
 sta kb_flags
 
exit:
 pla
 tax
 pla
 rti
 
 .org $fd00
keymap:
 .byte "????????????? `?" ; 00-0F
 .byte "?????q1???zsaw2?" ; 10-1F
 .byte "?cxde43?? vftr5?" ; 20-2F
 .byte "?nbhgy6???mju78?" ; 30-3F
 .byte "?,kio09??./l;p-?" ; 40-4F
 .byte "??'?[=????",$0a,"]?\??" ; 50-5F
 .byte "?????????1?47???" ; 60-6F
 .byte "0.2568",$1b,"??+3-*9??" ; 70-7F
 .byte "????????????????" ; 80-8F
 .byte "????????????????" ; 90-9F
 .byte "????????????????" ; A0-AF
 .byte "????????????????" ; B0-BF
 .byte "????????????????" ; C0-CF
 .byte "????????????????" ; D0-DF
 .byte "????????????????" ; E0-EF
 .byte "????????????????" ; F0-FF
keymap_shifted:
 .byte "????????????? ~?" ; 00-0F
 .byte "?????Q!???ZSAW@?" ; 10-1F
 .byte "?CXDE#$?? VFTR%?" ; 20-2F
 .byte "?NBHGY^???MJU&*?" ; 30-3F
 .byte "?<KIO)(??>?L:P_?" ; 40-4F
 .byte '??"?{+?????}?|??' ; 50-5F
 .byte "?????????1?47???" ; 60-6F
 .byte "0.2568???+3-*9??" ; 70-7F
 .byte "????????????????" ; 80-8F
 .byte "????????????????" ; 90-9F
 .byte "????????????????" ; A0-AF
 .byte "????????????????" ; B0-BF
 .byte "????????????????" ; C0-CF
 .byte "????????????????" ; D0-DF
 .byte "????????????????" ; E0-EF
 .byte "????????????????" ; F0-FF
 
 
; Reset/IRQ vectors 
 .org $fffa
 .word nmi
 .word reset
 .word keyboard_interrupt