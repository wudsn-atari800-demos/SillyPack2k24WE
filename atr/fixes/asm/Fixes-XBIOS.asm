;
;	>>> SillyPack XBIOS Loader by JAC! <<<
;
;	Thanks to xxl for his support regarding xBIOS.
;
;	Usage: m_fix_xbios_com 'EXAMPLE XEX'
;
;	This macro creates a patched XBIOS.XEX based on XBIOS.COM.
;	It will load the specified 'EXAMPLE CFG' from the root folder instead of the "XBIOS   CFG" file.
;	In the 'EXAMPLE CFG' you have to change the name of the autorun file to 'EXAMPLE XEX'.
	.macro m_fix_xbios
	opt h-
	?len = .filesize "XBIOS-Original.COM"
	.get "XBIOS-Original.COM"
	.put[$23]=:1
	.sav ?len
	.endm


;	Usage: m_fix_xbios_com 'EXAMPLE XEX'
;
;	This macros creates the loader for the root folder.

	.macro m_fix_xautorun
xBIOS			= $800
xBIOS_LOAD_FILE 	= xBIOS+$06
xBIOS_CHANGE_DIR	= xBIOS+$2d

	opt h+
	org  $580

	.proc loader

	ldy #<dir1
	ldx #>dir1
	jsr xBIOS_CHANGE_DIR
	bcs error

	ldy #<dir2
	ldx #>dir2
	jsr xBIOS_CHANGE_DIR
	bcs error

	ldy #<xexfile
	ldx #>xexfile
	jsr xBIOS_LOAD_FILE
	bcs error
error	.byte 2
	mva #$34 712
	lda 764
	cmp #$ff
	beq error
	jmp $e477

dir1	.byte c:1
dir2	.byte c:2
xexfile .byte c'XAUTORUN   '
	.endp

	.print *

	run loader
	.endm
