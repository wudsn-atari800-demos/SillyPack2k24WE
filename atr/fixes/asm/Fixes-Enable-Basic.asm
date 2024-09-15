;
;	>>> Enable BASIC and Re-open screen <<<
;

	.macro m_enable_basic
	.echo "Fixed: Now starts with BASIC disabled"

	opt h+
	org $2000

	.proc enable_basic
	lda #$a0	;Check if RAMTOP is already OK
	cmp ramtop	;This prevent flickering if BASIC is already off
	beq ramok
	sta ramtop	;Set RAMTOP to end of BASIC

	lda #$00	;Set BASICF for OS, so BASIC remains ON after RESET
	sta basicf
	sta sdmctl	;Disable screen in case the current DL is in the $A000-$BFFF area
	lda rtclok+2
wait	cmp rtclok+2
	beq wait

	lda portb	;Enable BASIC bit in PORTB for MMU
	and #$fd
	sta portb

	lda editrv+1	;Open "E:" to ensure screen is not at $9C00
	pha		;This prevents garbage when loading up to $bc00
	lda editrv
	pha
ramok	rts
	.endp

	ini enable_basic  ;Make sure the loader is execute before main program is loaded

	.endm
