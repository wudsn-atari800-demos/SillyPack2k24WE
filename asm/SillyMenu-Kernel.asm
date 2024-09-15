;
;	>>> SillyMenu by JAC! <<<
;
;	@com.wudsn.ide.lng.mainsourcefile=SillyMenu.asm


;===============================================================

	empty_procedure 	= fill_memory.return

;===============================================================

;	Use as "m_fill_memory start length value", or "m_fill_memory start length" to use the current value of fill_memory.value
	.macro m_fill_memory
	.if :0=3
	mva #:3 fill_memory.value
	.endif
	
	.if (:1 & $ff == 0)
	.if (:2 & $ff == 0)
		lda #>[:1]
		ldx #>[:2]
		jsr fill_memory.fill_page_ax
	.else
		lda #>[:1]
		ldx #>[:2]
		ldy #<[:2]
		jsr fill_memory.fill_page_axy
	.endif
	.else
		.error "fill page not even ", :1, " ", :2
	.endif
	.endm

	.local fill_memory	;IN: <A>=address high byte, <X>=count high byte, <Y>=count low byte 
fill_page_ax
	ldy #0
fill_page_axy
	sta fill_page_axy_adr+2
	sty fill_page_axy_low+1
	txa
	beq fill_page_axy_low
value = *+1 
	lda #0
	ldy #0
fill_page_axy_adr
	sta $ff00,y
	iny
	bne fill_page_axy_adr
	inc fill_page_axy_adr+2
	dex
	bne fill_page_axy_adr

fill_page_axy_low
	ldx #0
	bne fill_low
	rts

fill_low
	lda fill_page_axy_adr+2
	sta fill_low_adr+2
	lda value
	tay
fill_low_adr
	sta $ff00,y
	iny
	dex
	bne fill_low_adr
return	rts
	.endl

;===============================================================

	.macro m_copy_memory
	mwa #:1 copy_memory.source_adr
	mwa #:2 copy_memory.destination_adr
	mva #<:3 copy_memory.bytes
	mva #>:3 copy_memory.pages
	jsr copy_memory
	.endm

	.local copy_memory
	ldx #0
	stx bytes_count
	ldy #$00
pages = *-1
	beq no_pages
	jsr copy_loop
no_pages
	lda #$00
bytes = *-1
	beq no_bytes
	sta bytes_count
	ldy #1
copy_loop
	lda $ffff,x
source_adr = *-2
	sta $ffff,x
destination_adr = *-2
	inx
	cpx #$00
bytes_count = *-1
	bne copy_loop
	inc source_adr+1
	inc destination_adr+1
	dey
	bne copy_loop
no_bytes
	rts
	.endl

;===============================================================

;	.proc sync.vcount
;sync1	lda :vcount
;	bne sync1
;sync2	lda :vcount
;	beq sync2 
;	rts
;	.endp

	.proc sync.cnt
	lda :cnt
loop	cmp :cnt
	beq loop
	rts
	.endp

;===============================================================

	.proc system

	.proc off
	sei
	lda #0
	sta dmactl
	sta irqen
	sta nmien
	sta colbk 	
	mwa #empty_dl dlptr
	mva #$fe portb
	jsr init_pokey
	rts
	
	.local empty_dl
	.byte $41,a(empty_dl)
	.endl

	m_assert_same_1k empty_dl
	.endp

	.proc on
	jsr off
	lda #$ff
	sta portb
	lda #$c0
	sta ramsiz
	sta ramtop
	lda #$40
	sta nmien
	lda pokmsk
	sta irqen
	cli
	rts
	.endp

	.proc open_editor
	jsr $e40c
	lda $e401
	pha
	lda $e400
	pha
	rts
	.endp

	.proc init_pokey
	ldx #8
	lda #0
clear_pokey
	sta pokey,x
	sta pokey+$10,x
	dex
	bpl clear_pokey
	lda #3
	sta skctl
	sta skctl+$10
	rts
	.endp

;===============================================================

	.proc init_warmstart
	mva #$00 coldst		;Pressing reset when an entry is loaded brings back the menu
	mva #$ff warmst		;This is not the first RESET
	lda #1
	sta boot		;Call DOSINI vector
	rts
	.endp

	.proc init_coldstart
	mva #$ff coldst		;Pressing RESET in the main menu reboots
	mva #$00 warmst		;This is the first RESET
	mva #0 boot		;Do not call CASINI/DOSINI vectors
	rts
	.endp

	.endp			;End of system

;===============================================================
;
;	.proc dummy	;Wait 5 seconds and return
;	ldx cnt
;	dex
;wait	cpx cnt
;	bne wait
;	rts
;	.endp

