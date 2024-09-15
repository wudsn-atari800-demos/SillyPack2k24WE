;
;	Wrapper around NEOTRACKER to player COVOX tunes.
;

;A7FB: A9 00             LDA #$00
;A7FD: 85 4D             STA ATRACT
;A7FF: AD DC 02          LDA HELPPG
;A802: C9 11             CMP #$11
;A804: D0 03             BNE $A809
;A806: 4C A8 B0          JMP $B0A8
;A809: AD FC 02          LDA CH
;A80C: C9 FF             CMP #$FF
;A80E: F0 EB             BEQ $A7FB
;A810: AD FC 02          LDA CH
;A813: A8                TAY
;A814: A9 FF             LDA #$FF
;A816: 8D FC 02          STA CH
;A819: B1 79             LDA (KEYDEF),Y
;A81B: 60                RTS

	icl "..\..\asm\Fixes.asm"

rtclck	= $12
;neo_key	= $a809	;NeoTracker 1.7
neo_key	= $a819	;NeoTracker 1.8

	m_disable_basic

	org coldst		;Force coldstart because $400-$4ff is overwritten later
	.byte $ff

	org $2000
	opt h-

;	ins "NEO.com"
	ins "NEO18.com"

	opt h+

	org neo_key
	jmp new_key		;Comment out for testing

	org $1f00
	.proc new_key
;	lda rtclok+2
;	adc #25
;wait	cmp rtclok+2
;	bne wait

key_index = *+1
	ldy #0
	lda key_strokes,y
	bne not_last

	mva #$ad neo_key	;Restore old code and continue in interactive mode
	mwa #ch	 neo_key+1
	jmp neo_key

not_last
	inc key_index

	ldy #0			;Find KEYCODE for ATASCII character
loop	cmp (keydef),y
	beq found
	iny
	bne loop
not_found
	jmp not_found
found	rts

	.endp			;End of new_key

	load = 'L'-64
	down = 61
	return = 155

;	See https://github.com/epi/enotracker/wiki/Keys for NEOTRACKER keys
;	.local key_strokes
;	.byte load
;	.byte down, down, down, down, down, return ;Navigate to MSX folder
;	.byte down, return ;Navigate to COVOX folder
;	.byte down, return ;Navigate to 1st song
;	.byte return, 0 ; Play song
;	.endl
