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



; *** set up VDP registers ***
;
ld hl,VdpData
ld b,VdpDataEnd-VdpData
ld c,$bf
otir


    ;==============================================================
    ; Clear VRAM
    ;==============================================================
    ; 1. Set VRAM write address to 0 by outputting $4000 ORed with $0000
    ld a,$00
    out ($bf),a
    ld a,$40
    out ($bf),a
    ; 2. Output 16KB of zeroes
    ld bc, $4000    ; Counter for 16KB of VRAM
    ClearVRAMLoop:
        ld a,$00    ; Value to write
        out ($be),a ; Output to VRAM address, which is auto-incremented after each write
        dec bc
        ld a,b
        or c
        jp nz,ClearVRAMLoop


; *** load color palette ***

; set VRAM write address to CRAM (palette) address 0 (for palette index 0)
ld hl, $c000
call prepareVram

; output palette data
ld hl,PaletteData ; source of data
ld bc,PaletteDataEnd-PaletteData  ; counter for number of bytes to write
call writeToVram

    ;==============================================================
    ; Load tiles (font)
    ;==============================================================
    ; 1. Set VRAM write address to tile index 0
    ; by outputting $4000 ORed with $0000
    ld a,$00
    out ($bf),a
    ld a,$40
    out ($bf),a
    ; 2. Output tile data
    ld hl,FontData              ; Location of tile data
    ld bc,FontDataEnd-FontData  ; Counter for number of bytes to write
    WriteTilesLoop:
        ; Output data byte then three zeroes, because our tile data is 1 bit
        ; and must be increased to 4 bit
        ld a,(hl)        ; Get data byte
        out ($be),a
        inc hl           ; Add one to hl so it points to the next data byte

        ld a, 0
        out ($be),a
        out ($be),a
        out ($be),a

        dec bc
        ld a,b
        or c
        jp nz,WriteTilesLoop

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
    WriteTextLoop:
        ld a,(hl)    ; Get data byte
        out ($be),a
        inc hl       ; Point to next letter
        dec bc
        ld a,b
        or c
        jp nz,WriteTextLoop

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

; Color Palette Data:
PaletteData:
;    GGGGRRRR   ----BBBB (Format Game Gear, G=Green, R=Red, B=Blue)
.db %00000000, %00001111 ; Color 0: Blue
.db %00001111, %00000000 ; Color 1: Red
PaletteDataEnd:

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

.db $ff       ; reg. 2, name table address.
              ; $ff = name table at $3800.

.db $ff       ; reg. 3, n.a.
              ; always set it to $ff.

.db $ff       ; reg. 4, n.a.
              ; always set it to $ff.

.db $ff       ; reg. 5, sprite attribute table.
              ; $ff = sprite attrib. table at $3F00.

.db $ff       ; reg. 6, sprite tile address.
              ; $ff = sprite tiles in bank 2.

.db %11110011 ; reg. 7, border color.
              ; set to color 3 in bank 2.

.db $00       ; reg. 8, horizontal scroll value = 0.
.db $00       ; reg. 9, vertical scroll value = 0.
.db $ff       ; reg. 10, raster line interrupt.
              ; turn off line int. requests.

VdpDataEnd:

FontData:
; $00 -- " "
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000

; $01 -- "!"
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00000000
.db %00011000
.db %00000000

; $02 -- """
.db %01101100
.db %01101100
.db %01101100
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000

; $03 -- "#"
.db %00110110
.db %00110110
.db %01111111
.db %00110110
.db %01111111
.db %00110110
.db %00110110
.db %00000000

; $04 -- "$"
.db %00001100
.db %00111111
.db %01101000
.db %00111110
.db %00001011
.db %01111110
.db %00011000
.db %00000000

; $05 -- "$"
.db %01100000
.db %01100110
.db %00001100
.db %00011000
.db %00110000
.db %01100110
.db %00000110
.db %00000000

; $06 -- "&"
.db %00111000
.db %01101100
.db %01101100
.db %00111000
.db %01101101
.db %01100110
.db %00111011
.db %00000000

; $07 -- "'"
.db %00001100
.db %00011000
.db %00110000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000

; $08 -- "("
.db %00001100
.db %00011000
.db %00110000
.db %00110000
.db %00110000
.db %00011000
.db %00001100
.db %00000000

; $09 -- ")"
.db %00110000
.db %00011000
.db %00001100
.db %00001100
.db %00001100
.db %00011000
.db %00110000
.db %00000000

; $0a -- "*"
.db %00000000
.db %00011000
.db %01111110
.db %00111100
.db %01111110
.db %00011000
.db %00000000
.db %00000000

; $0b -- "+"
.db %00000000
.db %00011000
.db %00011000
.db %01111110
.db %00011000
.db %00011000
.db %00000000
.db %00000000

; $0c -- ","
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00011000
.db %00011000
.db %00110000

; $0d -- "-"
.db %00000000
.db %00000000
.db %00000000
.db %01111110
.db %00000000
.db %00000000
.db %00000000
.db %00000000

; $0e -- "."
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00011000
.db %00011000
.db %00000000

; $0f -- "/"
.db %00000000
.db %00000110
.db %00001100
.db %00011000
.db %00110000
.db %01100000
.db %00000000
.db %00000000

; $10 -- "0"
.db %00111100
.db %01100110
.db %01101110
.db %01111110
.db %01110110
.db %01100110
.db %00111100
.db %00000000

; $11 -- "1"
.db %00011000
.db %00111000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %01111110
.db %00000000

; $12 -- "2"
.db %00111100
.db %01100110
.db %00000110
.db %00001100
.db %00011000
.db %00110000
.db %01111110
.db %00000000

; $13 -- "3"
.db %00111100
.db %01100110
.db %00000110
.db %00011100
.db %00000110
.db %01100110
.db %00111100
.db %00000000

; $14 -- "4"
.db %00001100
.db %00011100
.db %00111100
.db %01101100
.db %01111110
.db %00001100
.db %00001100
.db %00000000

; $15 -- "5"
.db %01111110
.db %01100000
.db %01111100
.db %00000110
.db %00000110
.db %01100110
.db %00111100
.db %00000000

; $16 -- "6"
.db %00011100
.db %00110000
.db %01100000
.db %01111100
.db %01100110
.db %01100110
.db %00111100
.db %00000000

; $17 -- "7"
.db %01111110
.db %00000110
.db %00001100
.db %00011000
.db %00110000
.db %00110000
.db %00110000
.db %00000000

; $18 -- "8"
.db %00111100
.db %01100110
.db %01100110
.db %00111100
.db %01100110
.db %01100110
.db %00111100
.db %00000000

; $19 -- "9"
.db %00111100
.db %01100110
.db %01100110
.db %00111110
.db %00000110
.db %00001100
.db %00111000
.db %00000000

; $1a -- ":"
.db %00000000
.db %00000000
.db %00011000
.db %00011000
.db %00000000
.db %00011000
.db %00011000
.db %00000000

; $1b -- ";"
.db %00000000
.db %00000000
.db %00011000
.db %00011000
.db %00000000
.db %00011000
.db %00011000
.db %00110000

; $1c -- "<"
.db %00001100
.db %00011000
.db %00110000
.db %01100000
.db %00110000
.db %00011000
.db %00001100
.db %00000000

; $1d -- "="
.db %00000000
.db %00000000
.db %01111110
.db %00000000
.db %01111110
.db %00000000
.db %00000000
.db %00000000

; $1e -- ">"
.db %00110000
.db %00011000
.db %00001100
.db %00000110
.db %00001100
.db %00011000
.db %00110000
.db %00000000

; $1f -- "?"
.db %00111100
.db %01100110
.db %00001100
.db %00011000
.db %00011000
.db %00000000
.db %00011000
.db %00000000

; $20 -- "@"
.db %00111100
.db %01100110
.db %01101110
.db %01101010
.db %01101110
.db %01100000
.db %00111100
.db %00000000

; $21 -- "A"
.db %00111100
.db %01100110
.db %01100110
.db %01111110
.db %01100110
.db %01100110
.db %01100110
.db %00000000

; $22 -- "B"
.db %01111100
.db %01100110
.db %01100110
.db %01111100
.db %01100110
.db %01100110
.db %01111100
.db %00000000

; $23 -- "C"
.db %00111100
.db %01100110
.db %01100000
.db %01100000
.db %01100000
.db %01100110
.db %00111100
.db %00000000

; $24 -- "D"
.db %01111000
.db %01101100
.db %01100110
.db %01100110
.db %01100110
.db %01101100
.db %01111000
.db %00000000

; $25 -- "E"
.db %01111110
.db %01100000
.db %01100000
.db %01111100
.db %01100000
.db %01100000
.db %01111110
.db %00000000

; $26 -- "F"
.db %01111110
.db %01100000
.db %01100000
.db %01111100
.db %01100000
.db %01100000
.db %01100000
.db %00000000

; $27 -- "G"
.db %00111100
.db %01100110
.db %01100000
.db %01101110
.db %01100110
.db %01100110
.db %00111100
.db %00000000

; $28 -- "H"
.db %01100110
.db %01100110
.db %01100110
.db %01111110
.db %01100110
.db %01100110
.db %01100110
.db %00000000

; $29 -- "I"
.db %01111110
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %01111110
.db %00000000

; $2a -- "J"
.db %00111110
.db %00001100
.db %00001100
.db %00001100
.db %00001100
.db %01101100
.db %00111000
.db %00000000

; $2b -- "K"
.db %01100110
.db %01101100
.db %01111000
.db %01110000
.db %01111000
.db %01101100
.db %01100110
.db %00000000

; $2c -- "L"
.db %01100000
.db %01100000
.db %01100000
.db %01100000
.db %01100000
.db %01100000
.db %01111110
.db %00000000

; $2d -- "M"
.db %01100011
.db %01110111
.db %01111111
.db %01101011
.db %01101011
.db %01100011
.db %01100011
.db %00000000

; $2e -- "N"
.db %01100110
.db %01100110
.db %01110110
.db %01111110
.db %01101110
.db %01100110
.db %01100110
.db %00000000

; $2f -- "O"
.db %00111100
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %00111100
.db %00000000

; $30 -- "P"
.db %01111100
.db %01100110
.db %01100110
.db %01111100
.db %01100000
.db %01100000
.db %01100000
.db %00000000

; $31 -- "Q"
.db %00111100
.db %01100110
.db %01100110
.db %01100110
.db %01101010
.db %01101100
.db %00110110
.db %00000000

; $32 -- "R"
.db %01111100
.db %01100110
.db %01100110
.db %01111100
.db %01101100
.db %01100110
.db %01100110
.db %00000000

; $33 -- "S"
.db %00111100
.db %01100110
.db %01100000
.db %00111100
.db %00000110
.db %01100110
.db %00111100
.db %00000000

; $34 -- "T"
.db %01111110
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00000000

; $35 -- "U"
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %00111100
.db %00000000

; $36 -- "V"
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %00111100
.db %00011000
.db %00000000

; $37 -- "W"
.db %01100011
.db %01100011
.db %01101011
.db %01101011
.db %01111111
.db %01110111
.db %01100011
.db %00000000

; $38 -- "X"
.db %01100110
.db %01100110
.db %00111100
.db %00011000
.db %00111100
.db %01100110
.db %01100110
.db %00000000

; $39 -- "Y"
.db %01100110
.db %01100110
.db %01100110
.db %00111100
.db %00011000
.db %00011000
.db %00011000
.db %00000000

; $3a -- "Z"
.db %01111110
.db %00000110
.db %00001100
.db %00011000
.db %00110000
.db %01100000
.db %01111110
.db %00000000

; $3b -- "["
.db %01111100
.db %01100000
.db %01100000
.db %01100000
.db %01100000
.db %01100000
.db %01111100
.db %00000000

; $3c -- "\"
.db %00000000
.db %01100000
.db %00110000
.db %00011000
.db %00001100
.db %00000110
.db %00000000
.db %00000000

; $3d -- "]"
.db %00111110
.db %00000110
.db %00000110
.db %00000110
.db %00000110
.db %00000110
.db %00111110
.db %00000000

; $3e -- "^"
.db %00011000
.db %00111100
.db %01100110
.db %01000010
.db %00000000
.db %00000000
.db %00000000
.db %00000000

; $3f -- "_"
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %11111111

; $40 -- "‘"
.db %00011100
.db %00110110
.db %00110000
.db %01111100
.db %00110000
.db %00110000
.db %01111110
.db %00000000

; $41 -- "a"
.db %00000000
.db %00000000
.db %00111100
.db %00000110
.db %00111110
.db %01100110
.db %00111110
.db %00000000

; $42 -- "b"
.db %01100000
.db %01100000
.db %01111100
.db %01100110
.db %01100110
.db %01100110
.db %01111100
.db %00000000

; $43 -- "c"
.db %00000000
.db %00000000
.db %00111100
.db %01100110
.db %01100000
.db %01100110
.db %00111100
.db %00000000

; $44 -- "d"
.db %00000110
.db %00000110
.db %00111110
.db %01100110
.db %01100110
.db %01100110
.db %00111110
.db %00000000

; $45 -- "e"
.db %00000000
.db %00000000
.db %00111100
.db %01100110
.db %01111110
.db %01100000
.db %00111100
.db %00000000

; $46 -- "f"
.db %00011100
.db %00110000
.db %00110000
.db %01111100
.db %00110000
.db %00110000
.db %00110000
.db %00000000

; $47 -- "g"
.db %00000000
.db %00000000
.db %00111110
.db %01100110
.db %01100110
.db %00111110
.db %00000110
.db %00111100

; $48 -- "h"
.db %01100000
.db %01100000
.db %01111100
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %00000000

; $49 -- "i"
.db %00011000
.db %00000000
.db %00111000
.db %00011000
.db %00011000
.db %00011000
.db %00111100
.db %00000000

; $4a -- "j"
.db %00011000
.db %00000000
.db %00111000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %01110000

; $4b -- "k"
.db %01100000
.db %01100000
.db %01100110
.db %01101100
.db %01111000
.db %01101100
.db %01100110
.db %00000000

; $4c -- "l"
.db %00111000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00011000
.db %00111100
.db %00000000

; $4d -- "m"
.db %00000000
.db %00000000
.db %00110110
.db %01111111
.db %01101011
.db %01101011
.db %01100011
.db %00000000

; $4e -- "n"
.db %00000000
.db %00000000
.db %01111100
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %00000000

; $4f -- "o"
.db %00000000
.db %00000000
.db %00111100
.db %01100110
.db %01100110
.db %01100110
.db %00111100
.db %00000000

; $50 -- "p"
.db %00000000
.db %00000000
.db %01111100
.db %01100110
.db %01100110
.db %01111100
.db %01100000
.db %01100000

; $51 -- "q"
.db %00000000
.db %00000000
.db %00111110
.db %01100110
.db %01100110
.db %00111110
.db %00000110
.db %00000111

; $52 -- "r"
.db %00000000
.db %00000000
.db %01101100
.db %01110110
.db %01100000
.db %01100000
.db %01100000
.db %00000000

; $53 -- "s"
.db %00000000
.db %00000000
.db %00111110
.db %01100000
.db %00111100
.db %00000110
.db %01111100
.db %00000000

; $54 -- "t"
.db %00110000
.db %00110000
.db %01111100
.db %00110000
.db %00110000
.db %00110000
.db %00011100
.db %00000000

; $55 -- "u"
.db %00000000
.db %00000000
.db %01100110
.db %01100110
.db %01100110
.db %01100110
.db %00111110
.db %00000000

; $56 -- "v"
.db %00000000
.db %00000000
.db %01100110
.db %01100110
.db %01100110
.db %00111100
.db %00011000
.db %00000000

; $57 -- "w"
.db %00000000
.db %00000000
.db %01100011
.db %01101011
.db %01101011
.db %01111111
.db %00110110
.db %00000000

; $58 -- "x"
.db %00000000
.db %00000000
.db %01100110
.db %00111100
.db %00011000
.db %00111100
.db %01100110
.db %00000000

; $59 -- "y"
.db %00000000
.db %00000000
.db %01100110
.db %01100110
.db %01100110
.db %00111110
.db %00000110
.db %00111100

; $5a -- "z"
.db %00000000
.db %00000000
.db %01111110
.db %00001100
.db %00011000
.db %00110000
.db %01111110
.db %00000000

; $5b -- "{"
.db %00001100
.db %00011000
.db %00011000
.db %01110000
.db %00011000
.db %00011000
.db %00001100
.db %00000000

; $5c -- "|"
.db %00011000
.db %00011000
.db %00011000
.db %00000000
.db %00011000
.db %00011000
.db %00011000
.db %00000000

; $5d -- "}"
.db %00110000
.db %00011000
.db %00011000
.db %00001110
.db %00011000
.db %00011000
.db %00110000
.db %00000000

; $5e -- "~"
.db %00110001
.db %01101011
.db %01000110
.db %00000000
.db %00000000
.db %00000000
.db %00000000
.db %00000000
FontDataEnd:
