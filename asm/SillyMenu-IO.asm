;
;	>>> SillyMenu by JAC! <<<
;
;	@com.wudsn.ide.lng.mainsourcefile=SillyMenu.asm

	.proc io
	readme_flag = x1
	file_number = x2
	file_name_ptr = p1
	sm_ptr = p2

	.proc load_entry		;IN: cursor_line
without_readme
	lda #0
	.byte $2c
with_readme
	lda #1
	sta readme_flag

	ldy cursor_line			;Get file number for current line
	lda text_file_numbers,y
	sne
	rts				;No file

	jsr file.find_file		;<A>=file number
	mva #0 status_error_code	;Clear error code under the OS before new I/O starts

	jsr system.init_warmstart

	jsr sync.cnt
	jsr system.on
	jsr sync.cnt
	jsr system.open_editor
	jsr sync.cnt			;Make sure shadow registers have been copied before CRITIC is active

	lda readme_flag
	beq skip_readme
	jsr file.add_file_extension.txt
	jsr screen.print_loading
	jsr disk.print_readme
	lda disk.status
	beq return_to_menu		;Simulation
	bmi return_to_menu		;Error
	lda controls.stick
	bit controls.bits.left		;Back to menu
	beq return_to_menu		
	bit controls.bits.right		;Back to menu
	beq return_to_menu

skip_readme
	jsr file.add_file_extension.xex
	jsr screen.print_loading
	jsr disk.run_executable
	lda disk.status
	beq return_to_menu		;Simulation
;	bmi return_to_menu		;Not possible, because memory has been cleared
	jmp restore_menu

	.proc return_to_menu		;Return from demo mode (SHIFT) or readme
	jsr system.off
	lda #$40
	sta nmien
	lda #joystick.any
	jsr controls.wait_for_key_release
	rts
	.endp

	.proc restore_menu
	jsr disk.check_dos
	beq no_dos_loaded
	inc portb			;DOS active, perform warm start
	jsr system.init_warmstart
	jmp warmsv

no_dos_loaded				
	jmp main.restore		;No DOS active, return to menu directly
	.endp

	.endp				;End of load_entry

;===============================================================

	.proc file

file_name_length	 .byte 0	;Number of characters without drive prefix
current_file_path_length .byte 0	;Number of characters with drive prefix
current_file_path	 .ds 40		;Modifiable file path in RAM 

base_file_name_length	 .byte 0	;Number of characters with drive prefix
current_file_name_length .byte 0	;Number of characters with drive prefix
current_file_name	 .ds 40		;Modifiable file name in RAM 

	.proc find_file			;IN: <A>=file number 1..n, OUT: current_file_path/length, current_file_name/length, status_file_name/length

	sta file_number

	mwa #results.file_names file_name_ptr
file_loop
	ldy #0
	lda #text.LF
char_loop
	cmp (file_name_ptr),y
	beq eol_found
	iny
	bne char_loop

eol_found
	dec file_number
	beq file_found

	sec
	tya
	adc file_name_ptr
	sta file_name_ptr
	scc
	inc file_name_ptr+1
	jmp file_loop

file_found
	dey				;Exclude the $0d in $0a,$0a
	sty file_name_length

	ldx #0				;Create drive prefix "D1:"
	lda #'D'
	jsr store_file_path_character
	lda #'1'
	jsr store_file_path_character
	lda #':'
	jsr store_file_path_character

	ldy #0
copy_name_loop				;Copy file name
	lda (file_name_ptr),y
	jsr store_file_path_character
	iny
	cpy file_name_length
	bne copy_name_loop

	iny				;Add length of "D1:"
	iny
	iny
	sty base_file_name_length	;Remember file name length
	sty current_file_name_length
	sty status_file_name_length

	lda #':'
copy_file_path_loop
	cmp current_file_path,y
	beq path_end_found
	dey
	bpl copy_file_path_loop
	jam
path_end_found
	sty current_file_path_length	;Remeber file path length
	lda #text.EOL			;Terminate file path
	sta current_file_path,y
	rts

	.proc store_file_path_character
	sta current_file_path,x		;Make changeable
	sta current_file_name,x		;Make changeable
	sta status_file_name,x		;Make resident
	inx
	rts
	.endp

	.endp

;===============================================================

	.proc add_file_extension	;Add file extension to base file name
xex	ldx #extensions.xex-extensions
	.byte $2c
txt	ldx #extensions.txt-extensions

	jsr sync.cnt			;Make sure we're in the blank phase

	sei
	lda portb
	pha
	lda #$fe
	sta portb

	ldy base_file_name_length
	lda #'.'
	jsr append_char
	lda extensions+0,x
	jsr append_char
	lda extensions+1,x
	jsr append_char
	lda extensions+2,x
	jsr append_char
	lda #text.EOL
	jsr append_char
	dey				;Do not count EOL
	sty current_file_name_length
	sty status_file_name_length
	pla
	sta portb
	cli
	rts

	.proc append_char
	sta current_file_name,y
	sta status_file_name,y
	iny
	rts
	.endp

	.local extensions
xex	.byte 'XEX'
txt	.byte 'TXT'
	.endl

	.endp		;End of add_file_extension

	.endp		;file
;===============================================================

	.proc screen

	.proc print_loading	;Print "Loading <filename>..."
	ldy #2			;Clear cursor
	lda #0
	sta (savmsc),y
	adw savmsc #42 sm_ptr

	ldx #0
	ldy #0
loading_loop
	lda loading,x
	sta (sm_ptr),y
	inw sm_ptr
	inx
	cpx #.len loading
	bne loading_loop

file_name_loop
	lda file.current_file_name,y
	sec
	sbc #32
	sta (sm_ptr),y
	iny
	cpy file.current_file_name_length
	bne file_name_loop

file_name_done
	lda #"."		;Loading message
	sta (sm_ptr),y
	iny
	sta (sm_ptr),y
	iny
	sta (sm_ptr),y
	
	mva #2 rowcrs		;Set cursor row for subsequent output
	rts

	.local loading
	.byte "Loading "	;Screen code
	.endl

	.endp			;End of print_loading

;===============================================================

	.proc print_char_with_check	;OUT: controls.stick, <C>=1 if page was full (check for RIGHT)
	key_mask = joystick.left|joystick.right|joystick.fire

	ldx #0
	cmp #text.CR		;Ignore CR
	beq skip_char
	cmp #text.LF		;Normalize LF to EOL
	sne
	lda #text.EOL
	jsr print_char

	lda rowcrs		;Last row reached? 
	cmp #23
	bne not_last_row
	jsr message.init.next_page
	lda #key_mask
	ldx #<screen.message.print
	ldy #>screen.message.print
	jsr controls.wait_for_key_press
	jsr clear_screen
	sec
	rts

not_last_row
skip_char
	clc
	rts
	.endp

;===============================================================

	.proc message

delay	.byte 0
offset	.byte 0

	.proc init
next_page
	ldx #messages.next_page-messages
	.byte $2c
last_page
	ldx #messages.last_page-messages
	stx print.index_adr
	mva #0 delay
	jmp print
	.endp

	.proc print		;Print status message at bottom of screen
	sm_ptr = p1

	lda delay		;Count down delay
	beq no_delay
	dec delay
	rts

no_delay
	mva #100 delay		;New delay
	lda offset		;Toggle inner message
	eor #messages.length
	sta offset
index_adr = *+1
	lda #0			;Outer message index
	clc
	adc offset
	tax

	adw savmsc #920 sm_ptr
	ldy #0
loop	lda messages,x
	ora #$80
	sta (sm_ptr),y
	inx
	iny
	cpy #messages.length
	bne loop
	rts

	.endp			;End of print


	.local messages	;Exactly 2*40 bytes of screen code per message
	length = 40

	.local next_page
	.byte " LEFT menu | RIGHT more | FIRE   start  "
	.byte " ESC  menu | SPACE more | RETURN start  "
	.endl
	.local last_page
	.byte " LEFT menu | RIGHT menu | FIRE   start  "
	.byte " ESC  menu | SPACE menu | RETURN start  "
	.endl
	.endl

	.endp			;End of message

;===============================================================

	.proc clear_screen	;Clear the screen
	lda #text.CLEAR
	.endp			;Fall through

;===============================================================

	.proc print_char	;IN: char, changes <A>, <X>, <Y>
	tax
	lda $e407		;Use PUT_CHAR from E: handler
	pha
	lda $e406
	pha
	txa
	rts
	.endp			;End of print_char

	.endp			;End of screen

;===============================================================

	.proc disk
channel	= $10			;CIO channel for disk I/O

status	.byte $00

	.proc check_dos		;OUT: <Y>=0 & <Z>=1 if DOS is missing or SHIFT is pressed, <Y>=1 & <Z>=0 otherwise
	lda $700		;No DOS means simuation mode
	beq do_simulation
	lda skstat		;SHIFT means simulation mode
	and #8
	bne no_simulation
do_simulation
	ldy #0
	rts
no_simulation
	ldy #1
	rts
	.endp

;===============================================================

	.proc print_readme		;IN: file.current_file_name, OUT: disk.status, read_controls.stick
	key_mask = joystick.left|joystick.right|joystick.fire
	
	mva #0 status
	jsr check_dos
	jeq handle_io_error

	jsr close_channel
	jmi handle_io_error

	ldx #channel
	lda #cio_command.open		;Open channel
	sta iccom,x
	lda #4				;Read
	sta icax1,x
	lda #0
	sta icax2,x
	mwa #file.current_file_name icbal,x
	jsr ciov
	jmi handle_io_error

	mva #1 crsinh			;Disable cursor
	lda #text.EOL
	jsr screen.print_char

	jsr controls.init
loop	ldx #channel
	lda #cio_command.get_character	;Get character
	sta iccom,x
	lda #4
	sta icax1,x
	lda #0
	sta icax2,x
	mwa #file.current_file_name icbal,x
	jsr ciov
	cpy #136
	beq all_done
	jmi handle_io_error
	jsr screen.print_char_with_check
	lda controls.stick
	bit controls.bits.left		;Exit to menu
	beq return
	bit controls.bits.right		;Next page
	beq loop
	bit controls.bits.fire		;Exit to load executable
	beq return
	jmp loop			;Not end of page

all_done
	jsr screen.message.init.last_page
	jsr close_channel
	lda #key_mask
	jsr controls.wait_for_key_release
	lda #key_mask
	ldx #<screen.message.print
	ldy #>screen.message.print
	jsr controls.wait_for_key_press

return	mva #1 status			;Indicate that DOS is present
	mva #0 crsinh			;Enable cursor
	jmp screen.clear_screen
	.endp				;End of print_readme

;===============================================================

	.proc run_executable		;IN: file.current_file_name

	mva #0 status
	inx
	jsr check_dos
	jeq handle_io_error

	jsr close_channel
	jmi handle_io_error

	jsr clear_memory

	ldx #channel
	lda #cio_command.change_directory;BRUN in MyDOS and SpartaDOS
	sta iccom,x
	lda #0				;See http://www.mathyvannisselroy.nl/tech.doc
	sta icax1,x
	sta icax2,x
	mwa #file.current_file_path icbal,x
	jsr ciov
	bmi handle_io_error

	lda #cio_command.run_executable	;BRUN in MyDOS and SpartaDOS
	sta iccom,x
	lda #4				;See http://www.mathyvannisselroy.nl/tech.doc
	sta icax1,x
	lda #0
	sta icax2,x
	mwa #file.current_file_name icbal,x
	jmp call_ciov


	.proc clear_memory	;Clear RAM for compatibility

	.proc clear_ram
	ram_size = (ram_end-ram_start)/4
	mva #>[ram_start+0*ram_size] clear_ram_adr1+1
	mva #>[ram_start+1*ram_size] clear_ram_adr2+1
	mva #>[ram_start+2*ram_size] clear_ram_adr3+1
	mva #>[ram_start+3*ram_size] clear_ram_adr4+1
	ldy #>ram_size
	lda #0
	tax
loop
clear_ram_adr1 = *+1
	sta $ff00,x
clear_ram_adr2 = *+1
	sta $ff00,x
clear_ram_adr3 = *+1
	sta $ff00,x
clear_ram_adr4 = *+1
	sta $ff00,x
	inx
	bne loop
	inc clear_ram_adr1+1
	inc clear_ram_adr2+1
	inc clear_ram_adr3+1
	inc clear_ram_adr4+1
	dey
	bne loop
	.endp

	.proc clear_zp		;Clear uper zero page for compatibility
loop	sta $80,x
	inx
	bpl loop
	.endp
	rts
	.endp			;End of clear_memory


	.endp			;End of run_executable

;===============================================================

	.proc close_channel		;Close channel
	ldx #channel
	lda #cio_command.close
	sta iccom,x
	jmp ciov
	.endp

;===============================================================

	.proc handle_io_error		;IN: <Y>=error code 0,1,128,129...
	sty status
	jsr close_channel

	jsr system.off			;Disable ROM
	lda status
	sta status_error_code		;Preseve under ROM

	.proc print_error_code		;IN: <A>=error code 0,1,128,129...
	ldx #'0'
	stx status.texts.error_code
	stx status.texts.error_code+1

next_100
	cmp #100
	bcc next_10
	inc status.texts.error_code
	sbc #100
	bne next_100

next_10	cmp #10
	bcc next_1
	inc status.texts.error_code+1
	sbc #10
	bne next_10

next_1	clc
	adc #'0'
	sta status.texts.error_code+2
	.endp

	.proc print_file_name
	ldy #0
loop	lda status_file_name,y
	sta status.texts.error_file,y
	iny
	cpy status_file_name_length
	bne loop

	lda #'!'		;Error message
	sta status.texts.error_file,y
	lda #text.lf
	sta status.texts.error_file+1,y
	lda #0
	sta status.texts.error_file+2,y
	.endp			;End of print_file_name

	lda #status.texts.error_id
	jsr status.init
	rts

	.endp			;End of handle_io_error

;===============================================================

	.endp			;End of dos

	.endp			;End of io

ram_start = ((*+255)/256)*256	;Start of memory cleared when running an entry
