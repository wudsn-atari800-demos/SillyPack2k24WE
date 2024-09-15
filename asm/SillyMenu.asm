;
;	>>> SillyMenu by JAC! <<<
;
;	(c) 2012-12-31 - 2013-01-16 by JAC! for SillyVenture 2k12
;	(r) 2014-01-14 by JAC! for SillyVenture 2k13
;	(r) 2017-09-05 by JAC! for SillyVenture 2k17
;	(r) 2023-12-29 by JAC! for SillyVenture 2k22 SE
;
;	@com.wudsn.ide.lng.hardware=ATARI8BIT
;

	opt f+l+


original_stack	 = $a0

screen_lines 	 = 24
screen_line_size = $140

max_cursor_line  = $b0
max_top_line	 = $b1
top_line	 = $b2
old_top_line	 = $b3

text_colors_zp	 = $c0	;1+screen_lines+1+1+1+1 bytes = 29 bytes

cmc_player_zp	 = $e0	;4 bytes, saved to stack

call_ciov	 = resident_org+$00

text_sm		 = $8000	;Start of text screen, aligned to $1000

;===============================================================
	icl "SillyMenu-Kernel-Equates.asm"
	icl "SillyMenu-Global-Equates.asm"

	org main_org

	.proc main
	jmp start

	icl "SillyMenu-Kernel.asm"
	icl "SillyMenu-Controls.asm"
	icl "SillyMenu-IO.asm"

;===============================================================

start	tsx
	stx original_stack

vbxeoff	lda #0				;Disable VBXE
	sta $d600+fx_memc
	sta $d600+fx_mems
	sta $d600+fx_vc
	sta $d700+fx_memc
	sta $d700+fx_mems
	sta $d700+fx_vc
	sta fx_core_reset

restore	ldx original_stack
	txs

	jsr system.off
	jsr text.init

	lda powerup_mode		;If powerup_mode is zero, the resident state must be reset
	bne not_powerup
	inc powerup_mode
	lda #0
	sta cursor_line
	sta status_error_code	
	jsr status.init
not_powerup
	jsr system.init_coldstart

	jsr text.set_top_line
	mva top_line old_top_line
	jsr text.print_initial_lines	;Use and display previous cursor_line
	jsr text.set_lms

	jsr status.init.counters	;Use and display previous status_code
	lda status_error_code		;Use and display previous status_error_code
	spl
	jsr io.disk.handle_io_error.print_error_code

	jsr sound.init

	mwa #nmi $fffa
	mva #$40 nmien

	jsr controls.init

;===============================================================

	.proc main_loop

	jsr move_cursor
	beq handle_cursor_action	;Same cursor line means handle action

	.proc handle_cursor_line
	jsr text.set_top_line
	jsr text.scroll_top_line
	jsr sync.cnt
	jsr text.set_lms
	jmp next_frame
	.endp

	.proc handle_cursor_action
	dex
	beq load_entry
	dex
	bne skip_load_entry
	jsr io.load_entry.with_readme
	jmp skip_load_entry
load_entry
	jsr io.load_entry.without_readme
skip_load_entry
	jsr sync.cnt
	jmp next_frame
	.endp

next_frame
	jsr text.flash_cursor_line
	jsr status.print_status_text

	jmp main_loop
	.endp

;===============================================================

	.proc move_cursor	;OUT: <Z>=0 cursor_line_changed, <X>=0 (do nothing), 1 (load entry), 2 (load with readme)
	mask = joystick.up|joystick.down|joystick.right|joystick.fire
	action = x1

	jsr controls.read
	ldx #0			;Do nothing by default
	and #mask
	cmp #mask
	beq do_nothing
	bit controls.bits.fire	;Load if FIRE is pressed
	sne
	ldx #1
	bit controls.bits.right	;Load with readme if stick RIGHT is pressed
	sne
	ldx #2
do_nothing
	stx action

	lda controls.stick
	ldy cursor_line
	lsr
	bcs not_up
	cpy #0
	beq not_up
	dey
not_up	lsr
	bcs not_down
	cpy max_cursor_line
	bcs not_down
	iny
not_down
	ldx action
	cpy cursor_line
	sty cursor_line
	rts

	.endp
;===============================================================

	.proc nmi

	bit nmist
	bmi dli

	.proc vbi
	sta nmist
	pha
	txa
	pha
	tya
	pha
	lda #<text_colors_zp
	sta dli.lda_adr+1
	mwa #dl dlptr
	mva #$22 dmactl
	lda #0
	sta colpf1
	lda porta
	sta stick0
	lda trig0
	sta strig0

	lda #10
	sta $d018

	lda #$c0
	sta nmien
	jsr sound.player.play
	inc cnt
	pla
	tay
	pla
	tax
	pla
	rti
	.endp

;===============================================================

	.proc dli
	pha
lda_adr	lda text_colors_zp
	sta wsync
	sta colbk
	sta colpf2
	inc lda_adr+1
	pla
	rti
	.endp		;End of dli

	.endp		;End of nmi

;===============================================================

	.proc text
	LF		= $0a
	CR		= $0d
	EOL		= $9b
	CLEAR	 	= $7d
	FILE_INDICATOR 	= $7f

	characters_per_line = 80
	bytes_per_line = 40
	bytes_per_row = 8*bytes_per_line

	text_ptr	= p1
	sm_ptr		= p2
	sm_ptr1		= p3
	cursor_y 	= x1
	file_number	= x2
	top_line_tmp	= x3
	cursor_x 	= x4

;===============================================================

	.proc init

	jsr init_charset
	jsr init_colors
	jsr init_text
	rts

;===============================================================

	.proc init_charset
	ldy #[[.len charset_left+$ff]/$100]
	ldx #0
loop

lda_adr	= *+1
	lda charset_left,x
	lsr
	lsr
	lsr
	lsr
sta_adr	= *+1
	sta charset_right,x
	inx
	bne loop
	inc lda_adr+1
	inc sta_adr+1
	dey
	bne loop
	rts
	.endp

;===============================================================

	.proc init_colors
	ldx #0
	ldy #0
fill_colors
	lda results.colors.lengths,x
	beq fill_colors_done
	sta x1
fill_colors_loop
	tya
	asl
	and #2
	ora results.colors.chromas,x
	ora #8
	sta text_colors,y
	iny
	dec x1
	bne fill_colors_loop

	inx
	bne fill_colors
fill_colors_done

	lda #14
	sta text_colors_zp
	sta text_colors_zp+25
	sta text_colors_zp+27
	lda #10
	sta text_colors_zp+26
	lda #0
	sta text_colors_zp+28
	rts
	.endp				;End of init_colors

;===============================================================

	.proc init_text			;OUT: <max_cursor_line>, <max_top_line>

	mwa #results.text text_ptr
	lda #0
	sta cursor_y
	sta file_number
line_loop
	ldx cursor_y
	lda text_ptr
	sta text_lo,x
	lda text_ptr+1
	sta text_hi,x
	lda #0
	sta text_file_numbers,x

char_loop
	ldy #0
	lda (text_ptr),y
	inw text_ptr
	cmp #0
	jeq done
	cmp #text.FILE_INDICATOR
	beq file_char
	cmp #text.cr
	beq line_crlf
	cmp #text.lf
	beq line_lf
normal_char
	jmp char_loop

file_char
	ldx cursor_y
	inc file_number
	lda file_number
	sta text_file_numbers,x
	lda #text.FILE_INDICATOR
	jmp normal_char

line_crlf
	inw text_ptr			;Skip $0d/$0a
line_lf
	inc cursor_y
	jmp line_loop

done	lda cursor_y			;Compute max values
	sec
	sbc #1
	sta max_cursor_line
	sbc #23
	sta max_top_line
	rts
	.endp				;End of init_text

	.endp				;End of init

;===============================================================

	.proc print_initial_lines	;IN: <top_line>
	lda top_line			;Print the initial screen starting at the current cursor_line	
	sta top_line_tmp

	mva #screen_lines+1 cursor_y	
print_loop
	ldy top_line_tmp
	mva text_lo,y text_ptr
	mva text_hi,y text_ptr+1
	jsr print_line.at_line_y
	inc top_line_tmp
	dec cursor_y
	bne print_loop
	rts
	.endp

;===============================================================

	.proc print_line
at_line_y				;IN: <y>=screen line
	lda addresses.llo,y
	ldx addresses.lhi,y
at_address_ax				;IN: <A>=screen memory hi log, <X>=screen memory hi
	sta sm_ptr
	clc
	adc #40
	sta sm_ptr1
	stx sm_ptr+1
	scc
	inx
	stx sm_ptr1+1

	mva #0 cursor_x
print_char_loop
	ldy #0
	lda (text_ptr),y
	inw text_ptr 
	cmp #text.cr
	beq line_crlf
	cmp #text.lf
	beq line_lf
	jsr print_char
	jmp print_char_loop

line_crlf
line_lf

clear_char_loop
	lda cursor_x
	cmp #characters_per_line
	beq line_done
	lda #' '
	jsr print_char
	jmp clear_char_loop

line_done
	rts

	.proc print_char		;IN: <A>=char, <Y>=0, <cursor_x>, <sm_ptr>
	sec
	sbc #32
	and #127
	tax
	lda cursor_x
	inc cursor_x
	and #1
	bne print_char_right

	.proc print_char_left
	ldy #0
	lda charset_left+0*charset_left.line_size,x
	sta (sm_ptr),y
	lda charset_left+1*charset_left.line_size,x
	sta (sm_ptr1),y

	ldy #80
	lda charset_left+2*charset_left.line_size,x
	sta (sm_ptr),y
	lda charset_left+3*charset_left.line_size,x
	sta (sm_ptr1),y

	ldy #160
	lda charset_left+4*charset_left.line_size,x
	sta (sm_ptr),y
	lda charset_left+5*charset_left.line_size,x
	sta (sm_ptr1),y

	ldy #240
	lda charset_left+6*charset_left.line_size,x
	sta (sm_ptr),y
	lda charset_left+7*charset_left.line_size,x
	sta (sm_ptr1),y
	rts
	.endp

	.proc print_char_right
	ldy #0
	lda charset_right+0*charset_left.line_size,x
	ora (sm_ptr),y
	sta (sm_ptr),y
	lda charset_right+1*charset_left.line_size,x
	ora (sm_ptr1),y
	sta (sm_ptr1),y
	ldy #80
	lda charset_right+2*charset_left.line_size,x
	ora (sm_ptr),y
	sta (sm_ptr),y
	lda charset_right+3*charset_left.line_size,x
	ora (sm_ptr1),y
	sta (sm_ptr1),y
	ldy #160
	lda charset_right+4*charset_left.line_size,x
	ora (sm_ptr),y
	sta (sm_ptr),y
	lda charset_right+5*charset_left.line_size,x
	ora (sm_ptr1),y
	sta (sm_ptr1),y
	ldy #240
	lda charset_right+6*charset_left.line_size,x
	ora (sm_ptr),y
	sta (sm_ptr),y
	lda charset_right+7*charset_left.line_size,x
	ora (sm_ptr1),y
	sta (sm_ptr1),y
	inw sm_ptr
	inw sm_ptr1
	rts
	.endp

	.endp				;End of print_char

	.endp				;End of print_line

;===============================================================

	.proc set_top_line		;IN: <cursor_line>, <max_top_line>, OUT: <top_line>
	lda cursor_line
	sec
	sbc #screen_lines/2
	bcs is_more
	lda #0
	beq not_more

is_more	cmp max_top_line
	bcc not_more
	lda max_top_line
not_more
	sta top_line
	rts
	.endp

;===============================================================

	.proc scroll_top_line
	lda old_top_line
	cmp top_line			;Check if actual scrolling has occured? 
	beq skip

	ldy top_line
	bcs scroll_up			;New top_line is smaller, so first screen line needs an update
	tya				;New top_line is greater, so last screen line needs an update
	clc
	adc #screen_lines-1
	tay
scroll_up
	mva text_lo,y text_ptr
	mva text_hi,y text_ptr+1
	jsr print_line.at_line_y

	mva top_line old_top_line	;Now the text_sm is up to date again
skip	rts
	.endp

;===============================================================

	.proc set_lms			;IN: <top_line>
	lda top_line
	sta colors_adr
	sta llo_adr
	sta lhi_adr
	ldy #0
	ldx #0
loop
colors_adr = *+1
	lda text_colors,y
	sta text_colors_zp+1,y
llo_adr	= *+1
	lda addresses.llo,y
	sta dl.lms+1,x
lhi_adr	= *+1
	lda addresses.lhi,y
	sta dl.lms+2,x
	iny
	txa
	clc
	adc #10
	tax
	cpy #screen_lines
	bne loop
	jmp flash_cursor_line
	.endp

;===============================================================	

	.proc flash_cursor_line	;IN: cursor_line, top_line
	lda cursor_line
	sec
	sbc top_line
	tay
	lda cnt
	lsr
	and #31
	cmp #16
	bcc *+4
	eor #31
	sta text_colors_zp+1,y
	rts
	.endp

;===============================================================	

	.local addresses		;Repeated blocks of screen_lines+1 addresses
	blocks = 256/(screen_lines+1)

	.align $100			;Must be page aligned
	.local llo
	.rept blocks
:12	.byte <(text_sm+#*screen_line_size)
:12	.byte <(text_sm+$1000+#*screen_line_size)
	.byte <(text_sm+$2000)
	.endr
	.endl				;End of llo

	.align $100			;Must be page aligned
	.local lhi
	.rept blocks
:12	.byte >(text_sm+#*screen_line_size)
:12	.byte >(text_sm+$1000+#*screen_line_size)
	.byte >(text_sm+$2000)
	.endr
	.endl				;End of lhi
	
	.endl				;End of addresses

	.endp				;End of text

;===============================================================	

	.proc status

	.var frame_counter .byte
	.var status_id_counter .byte

;===============================================================	

	.proc init			;IN: <A>=status_id
	sta status_id
counters
	lda #0
	sta frame_counter
	sta status_id_counter
	m_fill_memory status_sm screen_line_size $00
	rts
	.endp

;===============================================================	

	.proc print_status_text
	lda frame_counter
	bne not_next
	ldx status_id
	bne status_not_0

	ldx status_id_counter
	cpx #status.texts.max_id+1
	sne
	ldx #0
	stx status_id_counter	
	inc status_id_counter
	jmp do_next

status_not_0
	lda #0
	sta status_id
do_next
	lda text_addresses.lo,x
	sta text.text_ptr
	lda text_addresses.hi,x
	sta text.text_ptr+1
	lda #<status_sm
	ldx #>status_sm
	jsr text.print_line.at_address_ax

not_next
	lda frame_counter
	lsr
	lsr
	and #63
	cmp #8
	bcc do_flash
	cmp #56
	bcs do_flash1
	jmp no_flash

do_flash1
	eor #7
do_flash
	and #7
	.byte $2c
no_flash
	lda #7
	tax
	lda status_colors,x
	sta text_colors_zp+26
	inc frame_counter
	rts

status_colors
	.byte 0,0,2,4,6,8,10,10

	.local text_addresses
lo	.byte <texts.text1,<texts.text2,<texts.text3,<texts.text4,<texts.error_text
hi	.byte >texts.text1,>texts.text2,>texts.text3,>texts.text4,>texts.error_text
	.endl

	.endp

;===============================================================	

	.local texts
	max_id = 3
	error_id = 4

	icl "..\menu\SillyMenu-Texts.asm"

text1	.byte 'Use joystick up and down or cursor keys to select entry.',text.LF,0
text2	.byte 'Press FIRE or RETURN to start. Press RIGHT or SPACE to read info.',text.LF,0
text3	.byte 'Press RESET to return from entry to the menu or to cold start in the menu.',text.LF,0
text4	m_credits_text
	.byte text.LF,0

error_text
	.byte 'I/O error '
error_code
	.byte '000 when reading '
error_file
	.byte '01234567890123456789123456789',0
	.endl
	.endp

	.align $400
;===============================================================	

	.local charset_left
	line_size	= $80

	ins "SillyMenu-Font.chr"
	.endl
	m_info charset_left

;===============================================================	

	.local dl
	dc = $0f

	.byte $70,$60+$80,$80
lms
	.rept 24
	.byte $40+dc,a(text_sm+#*text.bytes_per_row)
	.byte dc,dc,dc,dc,dc,dc,$80+dc
	.endr
	.byte $80
	.byte $40+dc,a(status_sm)
	.byte dc,dc,dc,dc,dc,dc,$80+dc,$80
	.byte $41,a(dl)
	.endl

;	m_assert_same_1k dl
	m_info dl

;===============================================================

	icl "SillyMenu-Sound.asm"

;===============================================================	

	.local results

	.local text
	ins "..\menu\SillyMenu-Entries.txt"
	.byte 0,0
	.endl

	.local colors
	icl "..\menu\SillyMenu-Entries-Colors.asm"
	.endl

	.local file_names
	ins "..\menu\SillyMenu-Entries-Files.txt"
	.endl

	.endl

	.endp		;End of main

	m_info main

	m_assert_end_of_code text_sm
