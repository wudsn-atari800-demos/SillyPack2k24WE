
	icl "..\COVOX.asm"

;	See https://github.com/epi/enotracker/wiki/Keys for NEOTRACKER keys
	.local key_strokes
	.byte load
	.byte down, down, down, down, down, down, return ;Navigate to MSX folder
	.byte down, return ;Navigate to COVOX folder
	.byte down, return ;Navigate to 1st song
	.byte return, 0 ; Play song
	.endl
