;
;	>>> SillyPack Noter by JAC! <<<
;

	icl "Kernel-Equates.asm"

	org $2000

	.proc note

cnt	 = $14
char	 = $80
sound_zp = $81
x1	 = $82

.if .not .def ntsc_mode
wait_time_second	= 10
wait_time_click		= 1
.else
wait_time_second	= 15
wait_time_click		= 1
.endif

	.macro m_pm_effect
	sta $d012
	sta $d000
	eor #$40
	sta $d013
	sta $d001
	.endm

	.proc main
	mva #2 lmargn
	lda #125
	jsr print_char
	jsr sound.init

	mva #4 gprior
	lda #$ff
	sta $d00d
	sta $d008
	sta $d00e
	sta $d009

	ldx #0
init_color_tab
	txa
	and #$f0
	sta x1
	txa
	and #$0f
	cmp #8
	scc
	eor #$0f
	asl
	ora x1
	sta color_tab,x
	sta color_tab+$100,x
	inx
	bne init_color_tab

	lda #setvbv.immediate
	ldx #>vbi
	ldy #<vbi
	jsr setvbv

	.proc text_loop
lda_ptr	= *+1
	lda text
 	sta char
	jeq text_end
	inw lda_ptr
	cmp #text.CR
	beq text_loop
	cmp #text.LF
	bne no_lf
	lda #text.EOL
	sta char
	bne do_print
no_lf
do_print
	jsr print_char
no_print
	lda char
	cmp #' '
	beq no_click
	adc #$10
;	jsr click
	m_pm_effect
	jmp do_click
no_click
	lda #0
	m_pm_effect
do_click
	lda char
	cmp #text.EOL
	bne no_wait
	lda #wait_time_second
	.byte $2c
no_wait
	lda #wait_time_click
	jsr wait
	lda rowcrs
	cmp #23
	bne not_last_line

page_end
	jsr next_page_effect

	lda 710
	clc
	adc #$10
	sne
	lda #$10
	sta 710

	lda #text.CLEAR
	sta char
	jsr print_char	

not_last_line
	jmp text_loop
	.endp

text_end
	mwa #text text_loop.lda_ptr
	jmp text_loop.page_end
	
	.macro m_effect
	lda color_tab+:1,x
	sta $d40a
	m_pm_effect
	.endm

	.proc next_page_effect
	mva #$ff ch
wait_key
	lda $d40b
	bne wait_key
	ldx $14
:250	m_effect #

	lda #$ff
	cmp ch
	jeq wait_key
	sta ch

	lda #0
	sta $d000
	sta $d001
	rts
	.endp			;End of next_page_effect

	.endp			;End of main

	.proc vbi
	escape = $1c
	space  = $21

	lda stick0
	and #$04	;Left?
	bne no_left
	mva #escape ch
no_left
	lda stick0
	and #$08	;Right?
	bne no_right
	mva #space ch
no_right
	lda strig0
	bne no_trigger
	mva #space ch	;Space
no_trigger

	lda ch
	cmp #escape	;ESC?
	bne no_esc
	jmp $e474

no_esc	jsr sound.play
	jmp sysvbv
	.endp

	.proc wait	;IN: <A>=number of frames
	clc
	adc cnt
loop	cmp cnt
	bne loop
	rts
	.endp

	.proc print_char;IN: char, changes <A>, <X>, <Y>
	lda $e407	;Use PUT_CHAR from E: handler
	pha
	lda $e406
	pha
	lda char
	rts
	.endp

	.local text
	CR = 13
	LF = 10
	EOL = 155
	WAIT = 156
	SOUND = 157
	CLEAR = 125

	.byte CLEAR,EOL
	m_text
	.byte 0
	.endl

	.proc sound
	init = mpt_player.init
	play = mpt_player.play
	position = mpt_player.pozsng
	pointer = mpt_player.pozptr
	volumes = mpt_player.volume

	icl "Noter-MPT-Relocator.mac"
	icl "Noter-MPT-Player.asm"
sound_module
	mpt_relocator '../../../menu/Noter-Music.mpt' , sound_module
	.sav [6] ?length
	.endp

	.align $100
color_tab	.ds $200
	.endp

	run note.main
