;
;	>>> SillyMenu Loader by JAC! <<<
;
;	@com.wudsn.ide.lng.hardware=ATARI8BIT

;	MEMLO ($2e7/8)=$1ee8 under MyDos

check_value = x1
dup_flag    = x2


	icl "SillyMenu-Kernel-Equates.asm"
	icl "SillyMenu-Global-Equates.asm"

;===============================================================

	org loader_org
	
	.proc initialize
	mva #$ff portb
	mva #$01 basicf

	ldx #0
	lda ch			;Any key pressed before?
	cmp #$ff
	seq
	inx
	lda skstat		;Any key pressed now?
	and #12
	cmp #12
	seq
	inx
	stx dup_flag		;$00 means no
	cpx #0
	beq do_load_menu

	ldy #.len load_dup_text-1
loop	lda load_dup_text,y
	sta (savmsc),y
	dey
	bpl loop
	rts
 
 	.local load_dup_text
 	.byte "  Loading DUP menu..."
 	.endl
 
do_load_menu
	lda #0
	sta sdmctl
	sta dmactl
	rts
	.endp
	
	ini initialize

;===============================================================

	org resident_org

	.proc resident		;Must be between $400-$47f!

	.proc call_ciov		;Called from SillyMenu, IN: <X>=channel
	lda boot
	pha
	jsr ciov
	jsr system_off		;Enable RAM under OS to store status
	sty status_error_code
	inc portb
	pla			;Fix for buggy G2F pictures which overwrite $07/$08/$09
	sta boot		;So they work at least when they exit regularly
	jmp warmsv
	.endp

	.proc reset		;Called via DOSINI ($0c) upon RESET
	lda #0
	sta sdmctl
	sta dmactl
 
casini_adr = *+1		;Original CASINI vector
	jsr return
dosini_adr = *+1		;Original DOSINI vector
	jsr return
	mwa #restore dosvec	;After loading an exeuctable, DOS jumps through DOSVEC to enter the DUP
restore	ldx #>main_rom
	ldy #>main_org
	jsr copy_main

	cmp main_check_value
	jeq main_org

	inc portb
	jmp coldsv
	.endp

	.proc copy_main		;IN: <X>=source high byte, <Y>=target high byte, OUT: <A>=checksum
	jsr system_off
	stx rom_adr+1
	sty ram_adr+1
	ldy #>[.len loader.main_packed+$ff]
	ldx #0
	stx check_value
	clc
loop
rom_adr	= *+1
	lda $ff00,x
ram_adr	= *+1
	sta $ff00,x
	adc check_value
	sta check_value
	inx
	bne loop
	inc rom_adr+1
	inc ram_adr+1
	dey
	bne loop
	rts
	
	.endp

	.proc system_off	;IN/OUT: <Y>=unchanged
	sei
	lda #0
	sta irqen
	sta nmien
	sta dmactl
	lda #$fe
	sta portb
	.endp

return	rts
	
	.endp			;End of resident

	m_info resident

;===============================================================

	org loader_org

	.proc loader

;===============================================================

	.proc check_main_in_rom		;Check if main is already in the ROM area
	lda dup_flag
	seq
	rts				;Goto DUP instead

	ldx #>main_rom
	ldy #>main_rom
	jsr resident.copy_main
	cmp main_check_value		;Store check value
	bne not_initialized

	lda powerup_mode		;System if off here
	cmp #1
	beq start_main.in_previous_mode

not_initialized
	inc portb
	lda #$40
	sta nmien
	lda pokmsk
	sta irqen
	cli
	rts
	.endp

;===============================================================

	.proc start_main		;Start main via warm start
in_powerup_mode
	mva #0 powerup_mode		;Ensure initializion of main part
in_previous_mode

	mwx dosini resident.reset.dosini_adr
	lda boot
	and #2
	beq no_casini
	ldx casini+1
	cpx #>speeder_org		;Free memory area?
	bne no_casini
	mwx casini resident.reset.casini_adr
no_casini

	mwa #resident.reset dosini	;The menu only uses DOSINI
	mva #1 boot			;Activate DOSINI
	mva #0 coldst
	inc portb
	jmp warmsv
	.endp

;===============================================================

old_org					;Fix for older MADS version
	ini loader.check_main_in_rom	;Make sure this INI is after start_main is already loaded.
	org old_org

;===============================================================

	.proc copy_main_to_rom		;Copy main to the ROM area
	lda dup_flag
	beq no_dup
	mva #$ff ch			;Clear last key stroke
	rts				;Goto DUP instead

no_dup	ldx #>main_packed
	ldy #>main_rom
	jsr resident.copy_main
	sta main_check_value		;Store check value
	jmp start_main.in_powerup_mode
	.endp

	.align $100			;Align to page boundary to prevent page boundary crossing in copy loop

	.local main_packed
	ins "SillyMenu-Packed.xex",+6
	.endl

	.if .len main_packed > (hi_base-main_rom)
	m_info main_packed
	.error "SillyMenu-Packed.xex is too large."
	.endif
	
	m_info main_packed
	.endp

	run loader.copy_main_to_rom
