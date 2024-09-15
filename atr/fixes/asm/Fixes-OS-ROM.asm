
//      Replaces OS illegal entry points
	.macro m_fix_os
	.echo "Fixed: Now runs with standard OS"
	
	.proc fix_os
	
open	= $03
close	= $0c
put	= $0d
drawto	= $11

channel	= $60

dindex	= $57	;lower 4 bites of GRPAHICS mode

iccom	= $342
icbadr	= $344
icblen	= $348
icaux1	= $34a
icaux2	= $34b
ciov	= $e456

	.local filespec
	.byte 'S:',$9b
	.endl
	
	.proc graphics	;$ef9c
	pha
	ldx #channel
	mva #close iccom,x
	jsr ciov
	mva #open iccom,x
	mwa #filespec icbadr,x 
	mva #8 icaux1,x
	pla
	eor #16
	sta icaux2,x
	jsr ciov
	ldx dindex
	rts
	.endp

	.proc print	;$f1a4
;	ldx #channel
;	mva #put iccom,x
;	jmp ciov
	jmp plot
	.endp
	
	.proc plot	;$f1d8
	pha
	ldx #channel
	mva #put iccom,x
	lda #0
	sta icblen,x
	sta icblen+1,x
	pla
	jmp ciov
	.endp

	.proc drawto	;$f9c2
	ldx #channel
	mva #drawto iccom,x
	jsr ciov
	ldy #1
	lda $02FB
	ldx #2
	rts
	.endp
	
	.endp

	.endm
