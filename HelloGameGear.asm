; A Z-80 assembler program writes "Hello World" to the Game Gear screen
; inspired by Maxim’s World of Stuff (SMS Tutorial)
; http://www.smspower.org/maxim/HowToProgram/Index


; WLA-DX banking setup
.memorymap
defaultslot 0
slotsize $8000
slot 0 $0000
.endme

.rombankmap
bankstotal 1
banksize $8000
banks 1
.endro

; SDSC tag and SMS rom header
.sdsctag 1.2,"Hello World","Game Gear Assembler Version","szr"

.bank 0 slot 0
.org $0000


; Boot section
;
di      ; disable interrupts
im 1    ; Interrupt mode 1
ld sp, $dff0

call setUpVdpRegisters
call clearVram
call loadColorPalette

; **** load tiles (font) ***

; set VRAM write address to tile index 0 by outputting $4000
ld hl, $4000
call prepareVram
ld hl,FontData              ; Location of tile data
ld bc,FontDataEnd-FontData  ; Counter for number of bytes to write
call writeToVram


    ;==============================================================
    ; Write text to name table
    ;==============================================================
    ; 1. Set VRAM write address to name table index $cc
    ; by outputting $4000 ORed with $3800+cc
    ;
    ; Game Gear: 102 empty cells, 3 lines with 6+20+6 tiles,  3*(6+20+6) + 6
    ;            102 words = 204 bytes = $cc
    ld a,$CC
    out ($bf),a
    ld a,$38|$40
    out ($bf),a
    ; 2. Output tilemap data
    ld hl,Message
    ld bc,MessageEnd-Message  ; Counter for number of bytes to write
    call writeToVram

    ; Turn screen on
    ld a,%11000000
;          |||| |`- Zoomed sprites -> 16x16 pixels
;          |||| `-- Doubled sprites -> 2 tiles per sprite, 8x16
;          |||`---- 30 row/240 line mode
;          ||`----- 28 row/224 line mode
;          |`------ VBlank interrupts
;          `------- Enable display
    out ($bf),a
    ld a,$81
    out ($bf),a

; Infinite loop to stop program
Loop:
    jp Loop


; --------------------------------------------------------------
; Subroutines
; --------------------------------------------------------------

; setUpVdpRegisters
;
setUpVdpRegisters:
    ld hl,VdpData
    ld b,VdpDataEnd-VdpData
    ld c,$bf
    otir
    ret

; clearVram
;
; set Video RAM to 0
;
clearVram:
    ; set VRAM write address to 0 by outputting $4000 ORed with $0000
    ld hl, $4000
    call prepareVram

    ; output 16KB of zeroes
    ld bc, $4000    ; Counter for 16KB of VRAM
    clearVramLoop:
        ld a,$00    ; Value to write
        out ($be),a ; Output to VRAM address, which is auto-incremented after each write
        dec bc
        ld a,b
        or c
        jp nz,clearVramLoop
    ret

; loadColorPalette
;
; load color palette to VRAM (two colors only).
PaletteData:
;    GGGGRRRR   ----BBBB (Format Game Gear, G=Green, R=Red, B=Blue)
.db %00000000, %00001111 ; Color 0: Blue
.db %00001111, %00000000 ; Color 1: Red
PaletteDataEnd:

loadColorPalette:
    ; set VRAM write address to CRAM (palette) address 0 (for palette index 0)
    ld hl, $c000
    call prepareVram

    ; output palette data
    ld hl,PaletteData ; source of data
    ld bc,PaletteDataEnd-PaletteData  ; counter for number of bytes to write
    call writeToVram
    ret

; Set up vdp to receive data at vram address in HL.
prepareVram:
    push af
    ld a,l
    out ($bf),a
    ld a,h
    or $40
    out ($bf),a
    pop af
    ret

; Write BC amount of bytes from data source pointed to by HL.
; Tip: Use prepareVram before calling.
writeToVram:
    ld a,(hl)
    out ($be),a
    inc hl
    dec bc
    ld a,c
    or b
    jp nz, writeToVram
    ret

;==============================================================
; Data
;==============================================================

; Text Message ("Hello, World!")
Message:
;   H   e   l   l   o   ,       W   o   r   l   d   !
.dw $28,$45,$4c,$4c,$4f,$0c,$00,$37,$4f,$52,$4c,$44,$01
MessageEnd:

; VDP initialisation data
VdpData:
.db %00000110 ; reg. 0, display and interrupt mode.
              ; bit 4 = line interrupt (disabled).
              ; 5 = blank left column (disabled).
              ; 6 = hori. scroll inhibit (disabled).
              ; 7 = vert. scroll inhibit (disabled).

.db %10100001 ; reg. 1, display and interrupt mode.
              ; bit 0 = zoomed sprites (enabled).
              ; 1 = 8 x 16 sprites (disabled).
              ; 5 = frame interrupt (enabled).
              ; 6 = display (blanked).

.db $ff       ; reg. 2, name table address. $ff = name table at $3800.
.db $ff       ; reg. 3, n.a., always set it to $ff.
.db $ff       ; reg. 4, n.a., always set it to $ff.
.db $ff       ; reg. 5, sprite attribute table.
.db $ff       ; reg. 6, sprite tile address.
.db %11110011 ; reg. 7, border color.
              ; set to color 3 in bank 2.

.db $00       ; reg. 8, horizontal scroll value = 0.
.db $00       ; reg. 9, vertical scroll value = 0.
.db $ff       ; reg. 10, raster line interrupt. Turn off line int. requests.
VdpDataEnd:

FontData:
.include "FontData.asm"
FontDataEnd:
