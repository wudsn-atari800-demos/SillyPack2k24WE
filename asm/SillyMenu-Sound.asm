;
;	>>> SillyMenu by JAC! <<<
;
;	@com.wudsn.ide.lng.mainsourcefile=SillyMenu.asm

	.proc sound

	.proc init
	ldx #<module
	ldy #>module
	lda #$70		;Init code
	jsr player.init
	lda #$00		;Set song code
	tax			;First song
	jmp player.init
	.endp

	icl "SillyMenu-CMC-Relocator.asm"
	icl "SillyMenu-CMC-Player.asm"
	icl "../menu/SillyMenu-CMC-Module.asm"

module	cmc_relocator '../menu/SillyMenu-CMC-Module.cmc', module
	.endp
