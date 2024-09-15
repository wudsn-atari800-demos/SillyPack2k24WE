;
;	>>> SillyPack Noter by JAC! <<<
;
;	@com.wudsn.ide.asm.outputfile=README.xex

	.macro m_text
	.byte $0d,$0a,$0a,$0d
	ins "..\..\..\menu\Readme.txt"
	.endm

	icl "..\..\asm\Noter.asm"
