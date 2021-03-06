; routines for printing text

; global variables
posx: resb 1
posy: resb 1

temp_msg db "\nChar rom dump:\n\n"

mem_p_dst: resb 2
mem_p_src: resb 2

print_ascii_char_inverse:
    ; convert ascii to c64 char rom offsets

    ; 96-127: offset 12
    lt r0, #96
    bzf .lt_96
    gt r0, #127
    bzf .done
    sub r0, #64
    mov r1, #12
    b .print_char
.lt_96:
    ; 64-95: offset 4
    lt r0, #64
    bzf .lt_64
    gt r0, #95
    bzf .done
    sub r0, #64
    mov r1, #4
    b .print_char
.lt_64:
    ; 32-63: offset 5
    lt r0, #32
    bzf .newline
    gt r0, #63
    bzf .done
    sub r0, #32
    mov r1, #5
    b .print_char
.newline:
    ; newline: #10
    mov r1, #16
    eq r0, #10
    bzf .print_char
    b .done
.print_char:
    push pch
    push pcl
    b print_char
.done:
    pop pcl
    pop pch

print_ascii_char:
    ; convert ascii to c64 char rom offsets

    ; 96-127: offset 7
    lt r0, #96
    bzf .lt_96
    gt r0, #127
    bzf .done
    sub r0, #64
    mov r1, #7
    b .print_char
.lt_96:
    ; 64-95: offset 0
    lt r0, #64
    bzf .lt_64
    gt r0, #95
    bzf .done
    sub r0, #64
    xor r1, r1
    b .print_char
.lt_64:
    ; 32-63: offset 1
    lt r0, #32
    bzf .newline
    gt r0, #63
    bzf .done
    sub r0, #32
    mov r1, #1
    b .print_char
.newline:
    ; newline: #10,#13
    mov r1, #16
    eq r0, #10
    bzf .print_char
    eq r0, #13
    bzf .print_char
    b .done
.print_char:
    push pch
    push pcl
    b print_char
.done:
    pop pcl
    pop pch

g_echo_char: resb 1
set_echo_char:
	st [g_echo_char], r0
    pop pcl
    pop pch

rs_msg_addr: resb 2
rs_i: resb 1
read_string:
	; r0 - high address of string
	; r1 = low address of string
;
;	; first store string address in memory
	st [rs_msg_addr], r1
	st [rs_msg_addr+1], r0

	; loop through string until <enter>
    xor r1, r1
    st [rs_i], r1
.loop:
	push pch
	push pcl
	b keyb_read_char
	eq r0, #10
	bzf .done
	eq r0, #13
	bzf .done
  ld r1, [rs_i]
  std [rs_msg_addr]+r1, r0
	; check if echo
	ld r1, [g_echo_char]
	eq r1, #1
	bzf .echo
	b .cont
.echo:
    push pch
    push pcl
    b print_ascii_char
.cont:
    ld r1, [rs_i]
    add r1, #1
    st [rs_i], r1
    b .loop
.done:
    ld r1, [rs_i]
  mov r0, #13
  std [rs_msg_addr]+r1, r0
  add r1, #1
  xor r0, r0
  std [rs_msg_addr]+r1, r0
    pop pcl
    pop pch

dcr_cur: resb 1
dcr_i: resb 1
dump_char_rom:
    xor r0, r0
    st [dcr_i], r0
.loop:
    ld r1, [dcr_i]
    push pch
    push pcl
    b print_char
    ld r0, [dcr_cur]
    add r0, #1
    st [dcr_cur], r0
    lt r0, #32
    bzf .loop
    xor r0, r0
    st [dcr_cur], r0
    ld r1, [dcr_i]
    lt r1, #15
    add r1, #1
    st [dcr_i], r1
    bzf .loop
    pop pcl
    pop pch

str_uint_rem: resb 1
str_uint_buf: resb 5
str_printuint8:
	xor r1, r1
	gt r0, #0
	bzf .gt0
	mov r1, #48
	st [str_uint_buf], r1
	b .done

.gt0:
.loop:
	eq r0, #0
	bzf .done
	push r1		; idx

	mov r1, r0	; num
	push r1
	mov r1, #10
	push pch
	push pcl
	b math_div
	mov r0, r1
	pop r1		; num
	st [str_uint_rem], r0
	mov r0, r1

	ld r1, [str_uint_rem]
	gt r1, #9
	bzf .gt9
	add r1, #48
	b .after_gt9
.gt9:
	sub r1, #10
	add r1, #97
.after_gt9:
	st [str_uint_rem], r1
	pop r1		; idx
	push r0		; num
	ld r0, [str_uint_rem]
	st [str_uint_buf]+r1, r0
	pop r0		; num
	push r1
	mov r1, #10
	push pch
	push pcl
	b math_div
	pop r1
	add r1, #1
	b .loop

.done:
	xor r0, r0
	st [str_uint_buf]+r1, r0
	mov r0, #>[str_uint_buf]
	mov r1, #<[str_uint_buf]
	push pch
	push pcl
	b str_reverse
	mov r0, #>[str_uint_buf]
	mov r1, #<[str_uint_buf]
	push pch
	push pcl
	b str_printstr
	pop pcl
	pop pch

str_printuint16:
	pop pcl
	pop pch

str_printstr:
	push pch
	push pcl
	b print_string
	pop pcl
	pop pch

ps_msg_addr: resb 2
ps_i: resb 1
print_string:
	; r0 - high address of string
	; r1 = low address of string
;
;	; first store string address in memory
	st [ps_msg_addr], r1
	st [ps_msg_addr+1], r0

	; loop through string until null terminator
    xor r1, r1
;    st [posx], r1
;    st [posy], r1
    st [ps_i], r1
.loop:
    ldd r0, [ps_msg_addr]+r1
    eq r0, #0
    bzf .done
    push pch
    push pcl
    b print_ascii_char
    ld r1, [ps_i]
    add r1, #1
    st [ps_i], r1
    b .loop
.done:
    pop pcl
    pop pch

pm_i: resb 1
print_msg:
	mov r0, #>[temp_msg]
	mov r1, #<[temp_msg]
    push pch
    push pcl
	b print_string
.done:
    pop pcl
    pop pch

i0: resb 1
j0: resb 1
char0: resb 1
offset0: resb 1
pc_offset: resb 1
mask0: resb 1
xpos_start: resb 1
xpos_atend: resb 1
ypos_current: resb 1
first_after_draw: resb 1
print_char:
    ; arg
    ; - ascii value in r0
    ; - charset offset r1

    st [pc_offset], r1

	push r0
	mov r0, #1
	st [first_after_draw], r0
	pop r0

    ; newline
    eq r0, #10
    bzf .newline
	eq r0, #13
	bzf .newline
    b .cont
.newline:
    eq r1, #16
    bzf .newline2
    b .cont
.newline2:
    ld r0, [posy]
    add r0, #8
    st [posy], r0
    xor r0, r0
    st [posx], r0
    b .done
.cont:
    mov r1, #8
    push pch
    push pcl
    b math_mul
    st [offset0], r0

    xor r0, r0
    st [i0], r0 ; i=0
    st [j0], r0 ; j=0
.loop:
    ld r1, [i0]
    mov r0, #128
    shr r0, r1

    ld r1, [j0]
    push r0
    ld r0, [offset0]
    add r1, r0
    ld r0, [pc_offset]
    eq r0, #1
    bzf .offset1
    eq r0, #2
    bzf .offset2
    eq r0, #3
    bzf .offset3
    eq r0, #4
    bzf .offset4
    eq r0, #5
    bzf .offset5
    eq r0, #6
    bzf .offset6
    eq r0, #7
    bzf .offset8
    eq r0, #9
    bzf .offset9
    eq r0, #10
    bzf .offset10
    eq r0, #11
    bzf .offset11
    eq r0, #12
    bzf .offset12
    eq r0, #13
    bzf .offset13
    eq r0, #14
    bzf .offset14
    eq r0, #15
    bzf .offset15
.offset0:
    ld r1, [charset_c64]+r1
    b .after_offset
.offset1:
    ld r1, [charset_c64+256]+r1
    b .after_offset
.offset2:
    ld r1, [charset_c64+512]+r1
    b .after_offset
.offset3:
    ld r1, [charset_c64+768]+r1
    b .after_offset
.offset4:
    ld r1, [charset_c64+1024]+r1
    b .after_offset
.offset5:
    ld r1, [charset_c64+1280]+r1
    b .after_offset
.offset6:
    ld r1, [charset_c64+1536]+r1
    b .after_offset
.offset7:
    ld r1, [charset_c64+1792]+r1
    b .after_offset
.offset8:
    ld r1, [charset_c64+2048]+r1
    b .after_offset
.offset9:
    ld r1, [charset_c64+2304]+r1
    b .after_offset
.offset10:
    ld r1, [charset_c64+2560]+r1
    b .after_offset
.offset11:
    ld r1, [charset_c64+2816]+r1
    b .after_offset
.offset12:
    ld r1, [charset_c64+3072]+r1
    b .after_offset
.offset13:
    ld r1, [charset_c64+3328]+r1
    b .after_offset
.offset14:
    ld r1, [charset_c64+3584]+r1
    b .after_offset
.offset15:
    ld r1, [charset_c64+3840]+r1
    b .after_offset
.after_offset:
	xor r0, r0
	st [xpos_atend], r0
    pop r0
    and r0, r1
    eq r0, #0
	; if r0 == 0, end of block so draw!
    bzf .draw
	; check if end of line so draw!
	ld r1, [i0]
	eq r1, #7
	and r0, #1
	st [xpos_atend], r0
	bzf .draw
	; check if first encounter after draw
	ld r1, [first_after_draw]
	eq r1, #0
	bzf .draw_done
	mov r0, #0
	st [first_after_draw], r0
	; record x pos
    ld r1, [i0]
	st [xpos_start], r1
	b .draw_done
.draw:
	ld r1, [first_after_draw]
	ld r0, [xpos_atend]
	eq r0, #1
	bzf .isatend
	b .cont2
.isatend:
	eq r1, #1
	bzf .isfirstafterdraw
	b .cont2
.isfirstafterdraw:
	mov r0, #7
	st [xpos_start], r0
	b .skip
.cont2:
	eq r1, #1
	bzf .draw_done
.skip:
	mov r0, #1
	st [first_after_draw], r0

    push #255   ; colour

	push #1

	ld r0, [xpos_start]
	ld r1, [i0]
	eq r1, #7
	sub r1, r0

; hack to deal with whole row
	gt r1, #8
	bzf .hack
	b .after_hack
.hack:
	mov r1, #0
	mov r0, #0
	st [xpos_start], r0
	b .sub
.after_hack:
	ld r0, [xpos_atend]
	add r1, r0
.sub:
	push r1

    ld r0, [j0]
    ld r1, [posy]
    add r1, r0
    push r1     ; y

    ld r0, [xpos_start]
    ld r1, [posx]
    add r1, r0
    push r1     ; x

    push pch
    push pcl
    ;b st7735_fill_rect
    b ili9340_fill_rect
.draw_done:
    ld r0, [i0]
    add r0, #1  ; i++
    st [i0], r0

    lt r0, #8   ; ? i < 8
    bzf .loop

    xor r0, r0  ; reset i
    st [i0], r0

    ld r1, [j0]
    add r1, #1  ; j++
    st [j0], r1

    lt r1, #8   ; ? j < 8
    bzf .loop

    ld r0, [posx]
    add r0, #8
    eq r0, #0
    bzf .inc_posy
    st [posx], r0
    b .done
.inc_posy:
    ld r0, [posy]
    add r0, #8
    st [posy], r0
    xor r0, r0
    st [posx], r0
.done:
    pop pcl
    pop pch

;cd_end: resb 1
;fill_screen_pixels:
;    ; [testing routine]
;    ; fill screen with pixels (slow)
;
;    xor r1, r1
;    st [posx], r1
;    st [posy], r1
;.draw_pixel:
;    push #255
;
;    ld r1, [posy]
;    push r1     ; y
;
;    ld r1, [posx]
;    push r1     ; x
;
;    push pch
;    push pcl
;    b st7735_draw_pixel
;
;    ld r1, [posx]
;    add r1, #1
;    st [posx], r1
;    eq r1, #0   ; 256
;    bzf .next
;    b .draw_pixel
;.next:
;    xor r1, r1
;    st [posx], r1
;
;    ld r1, [posy]
;    add r1, #1
;    st [posy], r1
;    eq r1, #255
;    bzf .done
;    b .draw_pixel
;.done:
;    pop pcl
;    pop pch
;
clr_screen:
    xor r0, r0
    st [posx], r0
    st [posy], r0
    push #0
    push #255
    push #255
    push #0
    push #0
    push pch
    push pcl
    ;b st7735_fill_rect
    b ili9340_fill_rect
    pop pcl
    pop pch

str_int_res: resb 1
str_int_addr: resb 2
str_atoi:
	st [str_int_addr], r1
	st [str_int_addr+1], r0

	xor r1, r1
	st [str_int_res], r1

.loop:
	ldd r0, [str_int_addr]+r1
	eq r0, #0
	bzf .done
	lt r0, #48
	bzf .done
	gt r0, #57
	bzf .done
	push r1
	sub r0, #48
	push r0
	mov r0, #10
	ld r1, [str_int_res]
	push pch
	push pcl
	b math_mul
	pop r1
	add r0, r1
	st [str_int_res], r0
	pop r1
	add r1, #1
	b .loop

.done:
	ld r0, [str_int_res]
	pop pcl
	pop pch

str_len_ptr: resb 2
str_len:
	st [str_len_ptr], r1
	st [str_len_ptr+1], r0

	xor r0, r0
.loop:
	ldd r1, [str_len_ptr]+r0
	eq r1, #0
	bzf .done
	add r0, #1
	b .loop

.done:
	pop pcl
	pop pch

str_cmp_ptr0: resb 2
str_cmp_set:
	st [str_cmp_ptr0], r1
	st [str_cmp_ptr0+1], r0

	pop pcl
	pop pch

str_cmp_mismatch: resb 1
str_cmp_pos: resb 1
str_cmp_ptr1: resb 2
str_cmp:
	st [str_cmp_ptr1], r1
	st [str_cmp_ptr1+1], r0

	xor r1, r1
	st [str_cmp_pos], r1
.loop:
	ld r1, [str_cmp_pos]
	ldd r0, [str_cmp_ptr0]+r1
	ldd r1, [str_cmp_ptr1]+r1
  sub r1, r0
  st [str_cmp_mismatch], r1
  gt r1, #0
  bzf .done
	eq r0, #0
	bzf .done

	ld r1, [str_cmp_pos]
  add r1, #1
  st [str_cmp_pos], r1
  b .loop

.done:
	ld r0, [str_cmp_mismatch]
	pop pcl
	pop pch

str_cpy_pc: resb 2
str_cpy_len: resb 1
str_cpy:
	; args on stack:
	;  src >> 8
    ;  src
	;  dst >> 8
	;  dst
	pop r0
	pop r1
	st [str_cpy_pc], r0
	st [str_cpy_pc+1], r1

	pop r0
	st [mem_p_src+1], r0
	pop r1
	st [mem_p_src], r1
	pop r0
	st [mem_p_dst+1], r0
	pop r1
	st [mem_p_dst], r1

	ld r1, [mem_p_dst]
	push r1
	ld r0, [mem_p_dst+1]
	push r0

	ld r1, [mem_p_src]
	push r1
	ld r0, [mem_p_src+1]
	push r0

	push pch
	push pcl
	b str_len
	st [str_cpy_len], r0

	push pch
	push pcl
	b mem_cpy

  xor r0, r0
	ld r1, [str_cpy_len]
  std [mem_p_dst]+r1, r0
.done:
	ld r0, [str_cpy_pc]
	ld r1, [str_cpy_pc+1]
	push r1
	push r0
	ld r0, [str_cpy_len]	; return length of string copied
	pop pcl
	pop pch

mem_cmp_set0:
	st [mem_p_dst], r1
	st [mem_p_dst+1], r0
	pop pcl
	pop pch

mem_cmp_set1:
	st [mem_p_src], r1
	st [mem_p_src+1], r0
	pop pcl
	pop pch

mem_cmp_pc: resb 2
mem_cmp_val: resb 1
mem_cmp:
	; length in r0
	; args on stack:
	;  src >> 8
    ;  src
	;  dst >> 8
	;  dst

	; save pc
	pop r1
	st [mem_cmp_pc], r1
	pop r1
	st [mem_cmp_pc+1], r1

	pop r1
	st [mem_p_src+1], r1
	pop r1
	st [mem_p_src], r1

	pop r1
	st [mem_p_dst+1], r1
	pop r1
	st [mem_p_dst], r1

  xor r1, r1
.loop:
  eq r1, r0
  bzf .done
  push r0
  push r1
  ldd r0, [mem_p_src]+r1
  ldd r1, [mem_p_dst]+r1
  sub r1, r0
  st [mem_cmp_val], r1
  pop r1
  add r1, #1
  pop r0
  b .loop

.done:
	; restore pc
	ld r1, [mem_cmp_pc+1]
	push r1
	ld r1, [mem_cmp_pc]
	push r1

  ld r0, [mem_cmp_val]

  pop pcl
  pop pch

mem_cpy_pc: resb 2
mem_cpy:
	; length in r0
	; args on stack:
	;  src >> 8
    ;  src
	;  dst >> 8
	;  dst

	; save pc
	pop r1
	st [mem_cpy_pc], r1
	pop r1
	st [mem_cpy_pc+1], r1

	pop r1
	st [mem_p_src+1], r1
	pop r1
	st [mem_p_src], r1

	pop r1
	st [mem_p_dst+1], r1
	pop r1
	st [mem_p_dst], r1

	push r0
.loop:
	pop r0
	eq r0, #0
	bzf .done
	push r0
	mov r1, r0
	sub r1, #1
	ldd r0, [mem_p_src]+r1
	std [mem_p_dst]+r1, r0
	pop r0
	sub r0, #1
	push r0
	b .loop

.done:
	; restore pc
	ld r1, [mem_cpy_pc+1]
	push r1
	ld r1, [mem_cpy_pc]
	push r1

	pop pcl
	pop pch

str_chr_ptr: resb 2
str_chr_set:
	st [str_chr_ptr], r1
	st [str_chr_ptr+1], r0
	pop pcl
	pop pch

str_chr_offset: resb 1
str_chr:
	xor r1, r1
	st [str_chr_offset], r1
.loop:
	ldd r1, [str_chr_ptr]+r1
	eq r1, #0
	bzf .notfound
	eq r1, r0
	bzf .found
	ld r1, [str_chr_offset]
	add r1, #1
	st [str_chr_offset], r1
	b .loop

.notfound:
	xor r0, r0
	xor r1, r1
	b .end

.found:
	ld r1, [str_chr_ptr]
	ld r0, [str_chr_offset]
	add r0, r1
	st [str_chr_ptr], r0
	lt r1, r0
	bzf .carry
	b .end
.carry:
	ld r0, [str_chr_ptr+1]
	add r0, #1
	st [str_chr_ptr+1], r0

	ld r1, [str_chr_ptr]
	ld r0, [str_chr_ptr+1]
.end:
	pop pcl
	pop pch

str_rev_i: resb 1
str_rev_ptr: resb 2
str_reverse:
	st [str_rev_ptr], r1
	st [str_rev_ptr+1], r0

	xor r0, r0
	st [str_rev_i], r0
.loop0:
	ldd r1, [str_rev_ptr]+r0
	eq r1, #0
	bzf .loop1
	push r1
	add r0, #1
	b .loop0

.loop1:
	eq r0, #0
	bzf .done
	pop r1
	push r0
	ld r0, [str_rev_i]
	std [str_rev_ptr]+r0, r1
	add r0, #1
	st [str_rev_i], r0
	pop r0
	sub r0, #1
	b .loop1

.done:
	pop pcl
	pop pch
