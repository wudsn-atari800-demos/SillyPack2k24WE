;
;	>>> SillyMenu by JAC! <<<
;
;	@com.wudsn.ide.lng.mainsourcefile=SillyMenu.asm
;

.def alignment_mode

; Zero page
cnt	= $14

p1	= $80
p2	= $82
p3	= $84

x1	= $90
x2	= $91
x3	= $92
x4	= $94


loader_org		= $2000		;Preface origin, used by SillyMenu-Loader.asm

resident_org		= $400		;Do not use $100/$600 because it is used by unpacker
speeder_org		= $500		;Free page, Can be used by speeders
main_org		= $2000		;Start above DOS
ram_end			= $bc00		;Maximum usable RAM end before the editor starts

lo_base			= $c000
text_lo			= lo_base+$000	;max_cursor_line bytes, page aligned
text_hi			= lo_base+$100	;max_cursor_line bytes, page aligned
text_colors		= lo_base+$200	;max_cursor_line bytes, page aligned
text_file_numbers	= lo_base+$300	;max_cursor_line bytes
charset_right		= lo_base+$400	;$400 bytes
status_sm		= lo_base+$800	;$140 bytes

main_rom		= $d800		;$d800-$feff, used by SillyMenu-Loader.asm

hi_base			= $ff00

main_check_value	= hi_base+$00	;$1 byte, preserved beyond cold start, used by SillyMenu-Loader.asm
powerup_mode		= hi_base+$01	;$1 byte, preserved beyond cold start
cursor_line		= hi_base+$02	;$1 byte, preserved beyond cold start
status_id		= hi_base+$03	;$1 byte, preserved beyond cold start
status_error_code	= hi_base+$04	;$1 byte, preserved beyond cold start
status_file_name_length	= hi_base+$05	;$1 bytes, preserved beyond cold start
status_file_name	= hi_base+$06	;$40 bytes, preserved beyond cold start


