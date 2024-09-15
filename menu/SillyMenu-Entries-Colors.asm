;
;	>>> SillyMenu by JAC! <<<
;
;	@com.wudsn.ide.lng.mainsourcefile=..\asm\SillyMenu.asm
;
;	Lengths specifies the number of line with same color.
;	Length 0 terminates the sequence.
;	Chromas specified the PAL color values with luma zero.

;              LO, LO, BO, PO, GT, GF, 25, 16, DE, G2, GA, WI, TI.
lengths	.byte  15,  4 , 5, 11,  5, 12,  9,  7, 13, 11,  7, 16, 11,0
chromas	.byte $30,$10,$e0,$d0,$b0,$90,$70,$50,$40,$20,$f0,$c0,$00,$00
;chroma .byte $30,$10,$e0,$d0,$b0,$90,$70,$50,$40,$20,$f0,$c0,$a0,$00

