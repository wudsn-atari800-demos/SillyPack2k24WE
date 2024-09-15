
	.macro m_load_atr filename
	.echo "Fixed: Now runs from DOS 2.5"
;
;	>>> In-Memory ATR-Loader <<<
;
;	Loads ATR boot sectorsto high address and then emulates OS booting.
;	Use as follows in your own source file:
;
;	org $4000	
;	m_load_atr zp 'BOOTRIS.atr'


zp	= $80
p1	= zp
p2	= zp+2

dosini  = $0c
dflags	= $240
dbsect	= $241
bootad	= $242 ;word
coldst  = $244


	.proc main
	mva #1 coldst

	mwa #file p1
	jsr get_byte
	sta dflags	;Unused, compatibility
	jsr get_byte
	sta dbsect
	jsr get_byte
	sta bootad	;Compatibility
	sta p2
	jsr get_byte
	sta bootad+1	;Compatibility
	sta p2+1

	jsr get_byte
	sta dosini
	jsr get_byte
	sta dosini+1
	
	mwa #file p1
sectors
	ldx #0
sector_bytes
	jsr get_byte
	sta (p2),y
	inw p2
	inx
	bpl sector_bytes
	dec dbsect
	bne sectors

	adw bootad #6 init_adr
init_adr = *+1
	jsr $ffff
	jmp (dosini)

	.proc get_byte
	ldy #0
	lda (p1),y
	inw p1
	rts
	.endp
	.endp

	.local file			;Include actual ATR file without header
	ins :filename,+16
	.endl

	run main

	.endm
