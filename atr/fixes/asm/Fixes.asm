
	icl "Kernel-Equates.asm"
	icl "Fixes-Boot-ATR.asm"
	icl "Fixes-Disable-Basic.asm"
	icl "Fixes-Enable-Basic.asm"
	icl "Fixes-Load-High.asm"
	icl "Fixes-OS-ROM.asm"
	icl "Fixes-VU-Player-2.0.asm"
	icl "Fixes-XBIOS.asm"

	.macro m_force_coldstart
	.echo "Fixed: Now performs cold start upon RESET. No more of crash upon RESET."
	
	opt h+

	org coldst
	.byte $ff
	.endm

	.macro m_fade_screen_out

	.proc fade_screen_out
	ldy #16			;Fade out colors registers
fade_loop
	ldx #8
color_loop
	lda $2c0,x
	and #$0f
	bne not_black
	sta $2c0,x
	beq next_color
not_black
	dec $2c0,x
next_color
	dex
	bne color_loop
	lda $14
	clc
	adc #3
wait	cmp $14
	bne wait
	dey
	bne fade_loop
	sty sdmctl	;Disable screen DMA
	lda $14
wait2	cmp $14		;Wait for screen to be disabled before writing to $BCxx
	beq wait2
	rts
	.endp
	
	ini fade_screen_out
	.endm

	.macro m_turn_screen_off

	.echo "Fixed: Now turns screen off while loading."

	opt h+

	org $2000
turn_screen_off
	mva #0 sdmctl
	lda $14
wait	cmp $14
	beq wait
	rts
	
	ini turn_screen_off
	.endm

	.macro m_add_runadr filename
	opt h-
	.def length = .filesize ":filename"
	.get ":filename"
	.sav length

	.echo "Fixed: Now runs from DOS 2.5. RUNADR segment added. New length is ",length+6," bytes."
	opt h-
	.word $2e0
	.word $2e1
	.byte .get[2],.get[3]

	.endm

