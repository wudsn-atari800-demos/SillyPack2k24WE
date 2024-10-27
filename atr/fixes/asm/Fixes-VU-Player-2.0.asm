 
;	Usage:
;
;	icl "..\..\Fixes.asm"
;	m_fix_vu_player_20 "PRICKUP-Original.xex" $8000

;	Original VU Player 1.0 Export format
;
;	1900-1EFF
;	2000-2FFF
;	02E0-02E1
;	1F40-...
;
;	Reexported VU Player 2.0 Export format
;	0CEB-1F40
;	02E0-02E1
;	1F40-...

	.macro m_fix_vu_player_20
	.echo "Fixed: Now runs from DOS 2.5. VU player 2.0 loaded to ",:2," and RESET causes a cold start."

p1	= $80
p2	= $82
p3	= $84

	opt h-
	.byte $ff,$ff
	ins ":1", +$1332
	
	opt h+
	org :2
start	mva #$ff 580
	mwa #block_0c1b p1
	mwa #$c1b p2
	mwa #[.len block_0c1b] p3
	ldy #0
loop	mva (p1),y (p2),y
	inw p1
	inw p2
	sbw p3 #1
	lda p3
	ora p3+1
	bne loop
	mva #$4c $1d14
	mwa #$e477 $1d15
	jmp $1810

	.local block_0c1b
	ins ":1", +$6, +$1320
	.endl
	
	run start
	.endm

