; routines for printing text

; global variables
posx: resb 1
posy: resb 1


temp_msg db "\nCUPCAKE KERNEL TEST\n\n1234567890...\n\nChar rom dump:\n\n"
;temp_msg db "\n4"

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

print_ascii_char2:
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
    ; newline: #10
    mov r1, #16
    eq r0, #10
    bzf .print_char
    b .done
.print_char:
    push pch
    push pcl
    b print_char_block
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

dcr_cur: resb 1
dcr_i: resb 1
dump_char_rom:
    xor r0, r0
    st [dcr_i], r0
.loop:
    ld r1, [dcr_i]
    push pch
    push pcl
    b print_char_block
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

pm_i: resb 1
print_msg:
    xor r1, r1
    st [posx], r1
    st [posy], r1
    st [pm_i], r1
.loop:
    ld r0, [temp_msg]+r1
;    st $f000, r0
    eq r0, #0
    bzf .done
;    xor r1, r1
    push pch
    push pcl
    b print_ascii_char
;    b .print_ascii_char_inverse
;    b .print_char
    ld r1, [pm_i]
    add r1, #1
    st [pm_i], r1
    b .loop
.done:
    pop pcl
    pop pch
    
print_msg2:
    xor r1, r1
    st [posx], r1
    st [posy], r1
    st [pm_i], r1
.loop:
    ld r0, [temp_msg]+r1
;    st $f000, r0
    eq r0, #0
    bzf .done
;    xor r1, r1
    push pch
    push pcl
    b print_ascii_char2
;    b .print_ascii_char_inverse
;    b .print_char
    ld r1, [pm_i]
    add r1, #1
    st [pm_i], r1
    b .loop
.done:
    pop pcl
    pop pch

i0: resb 1
j0: resb 1
char0: resb 1
offset0: resb 1
pc_offset: resb 1
print_char:
    ; arg
    ; - ascii value in r0
    ; - charset offset r1

    st [pc_offset], r1

    ; newline
    eq r0, #10
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
    ;st $f000, r0

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
    pop r0
    and r0, r1
    ;st $f000, r0
    eq r0, #0
    bzf .draw_done
.draw:
    push #255   ; colour

    ld r0, [j0]
    ld r1, [posy]
    add r1, r0
    push r1     ; y

    ld r0, [i0]
    ld r1, [posx]
    add r1, r0
    push r1     ; x

    push pch
    push pcl
    b st7735_draw_pixel
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

mask0: resb 1
xpos_start: resb 1
xpos_atend: resb 1
ypos_current: resb 1
first_after_draw: resb 1
print_char_block:
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
	ld r0, [first_after_draw]
	eq r0, #0
	bzf .draw_done
	mov r0, #0
	st [first_after_draw], r0
	; record x pos
    ld r1, [i0]
	st [xpos_start], r1
	b .draw_done
.draw:
	; check if first encounter after draw
	ld r0, [first_after_draw]
	eq r0, #1
	bzf .draw_done

	mov r0, #1
	st [first_after_draw], r0

    push #255   ; colour

	push #1

	ld r0, [xpos_start]
	ld r1, [i0]
	eq r1, #7
	sub r1, r0
	bzf .no_sub
	b .sub
.no_sub:
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
    b st7735_fill_rect
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

cd_end: resb 1
fill_screen_pixels:
    ; [testing routine]
    ; fill screen with pixels (slow)

    xor r1, r1
    st [posx], r1
    st [posy], r1
.draw_pixel:
    push #255

    ld r1, [posy]
    push r1     ; y

    ld r1, [posx]
    push r1     ; x

    push pch
    push pcl
    b st7735_draw_pixel

    ld r1, [posx]
    add r1, #1
    st [posx], r1
    eq r1, #0   ; 256
    bzf .next
    b .draw_pixel
.next:
    xor r1, r1
    st [posx], r1

    ld r1, [posy]
    add r1, #1
    st [posy], r1
    eq r1, #255
    bzf .done
    b .draw_pixel
.done:
    pop pcl
    pop pch

clr_screen:
    xor r0, r0
    st [posx], r0
    st [posy], r0
    push #0     ; color
    push #255
    push #255
    push #0
    push #0
    push pch
    push pcl
    b st7735_fill_rect
    pop pcl
    pop pch
