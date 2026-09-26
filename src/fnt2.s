FNT2_S:
; CHR $00-$1F BLANK
; CHR $20
 .byte %00000000
 .byte %00100100
 .byte %01101110
 .byte %01111110
 .byte %01001000
 .byte %00111110
 .byte %00101100
 .byte %00000000
; CHR $21
; SET.FONTS copies from FNT2 to character $21.
FNT2:
 .byte %01010101
 .byte %01100101
 .byte %01100101
 .byte %10011001
 .byte %10011001
 .byte %10101001
 .byte %10011001
 .byte %01010101
; CHR $22
 .byte %01010101
 .byte %10100101
 .byte %10011001
 .byte %10100101
 .byte %10011001
 .byte %10011001
 .byte %10100101
 .byte %01010101
; CHR $23
 .byte %01010101
 .byte %01100101
 .byte %10011001
 .byte %10010101
 .byte %10010101
 .byte %10011001
 .byte %01100101
 .byte %01010101
; CHR $24
 .byte %01010101
 .byte %10100101
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10100101
 .byte %01010101
; CHR $25
 .byte %01010101
 .byte %10101001
 .byte %10010101
 .byte %10100101
 .byte %10010101
 .byte %10010101
 .byte %10101001
 .byte %01010101
; CHR $26
 .byte %01010101
 .byte %10101001
 .byte %10010101
 .byte %10100101
 .byte %10010101
 .byte %10010101
 .byte %10010101
 .byte %01010101
; CHR $27
 .byte %01010101
 .byte %01101001
 .byte %10010101
 .byte %10010101
 .byte %10011001
 .byte %10011001
 .byte %01101001
 .byte %01010101
; CHR $28
 .byte %01010101
 .byte %10011001
 .byte %10011001
 .byte %10101001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %01010101
; CHR $29
 .byte %01010101
 .byte %10101001
 .byte %01100101
 .byte %01100101
 .byte %01100101
 .byte %01100101
 .byte %10101001
 .byte %01010101
; CHR $2A
 .byte %01010101
 .byte %01011001
 .byte %01011001
 .byte %01011001
 .byte %01011001
 .byte %10011001
 .byte %01100101
 .byte %01010101
; CHR $2B
 .byte %01010101
 .byte %10011001
 .byte %10011001
 .byte %10100101
 .byte %10100101
 .byte %10011001
 .byte %10011001
 .byte %01010101
; CHR $2C
 .byte %01010101
 .byte %10010101
 .byte %10010101
 .byte %10010101
 .byte %10010101
 .byte %10010101
 .byte %10101001
 .byte %01010101
; CHR $2D
 .byte %01010101
 .byte %10010110
 .byte %10011010
 .byte %10101010
 .byte %10100110
 .byte %10010110
 .byte %10010110
 .byte %01010101
; CHR $2E
 .byte %01010101
 .byte %10010110
 .byte %10100110
 .byte %10100110
 .byte %10011010
 .byte %10011010
 .byte %10010110
 .byte %01010101
; CHR $2F
 .byte %01010101
 .byte %01100101
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %01100101
 .byte %01010101
; CHR $30
 .byte %01010101
 .byte %10100101
 .byte %10011001
 .byte %10011001
 .byte %10100101
 .byte %10010101
 .byte %10010101
 .byte %01010101
; CHR $31
 .byte %01010101
 .byte %01100101
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %01100110
 .byte %01010101
; CHR $32
 .byte %01010101
 .byte %10100101
 .byte %10011001
 .byte %10011001
 .byte %10100101
 .byte %10011001
 .byte %10011001
 .byte %01010101
; CHR $33
 .byte %01010101
 .byte %01101001
 .byte %10010101
 .byte %01100101
 .byte %01011001
 .byte %01011001
 .byte %10100101
 .byte %01010101
; CHR $34
 .byte %01010101
 .byte %10101001
 .byte %01100101
 .byte %01100101
 .byte %01100101
 .byte %01100101
 .byte %01100101
 .byte %01010101
; CHR $35
 .byte %01010101
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10101001
 .byte %01010101
; CHR $36
 .byte %01010101
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %10011001
 .byte %01100101
 .byte %01010101
; CHR $37
 .byte %01010101
 .byte %10010110
 .byte %10010110
 .byte %10011010
 .byte %10101010
 .byte %10100110
 .byte %10010110
 .byte %01010101
; CHR $38
 .byte %01010101
 .byte %10011001
 .byte %10011001
 .byte %01100101
 .byte %01100101
 .byte %10011001
 .byte %10011001
 .byte %01010101
; CHR $39
 .byte %01010101
 .byte %10011001
 .byte %10011001
 .byte %01100101
 .byte %01100101
 .byte %01100101
 .byte %01100101
 .byte %01010101
; CHR $3A
 .byte %01010101
 .byte %10101001
 .byte %01011001
 .byte %01100101
 .byte %01100101
 .byte %10010101
 .byte %10101001
 .byte %01010101
; CHR $3B
 .byte %00101000
 .byte %00001000
 .byte %00001000
 .byte %10101000
 .byte %00001000
 .byte %00001000
 .byte %00010100
 .byte %01010101
; CHR $3C
 .byte %00101000
 .byte %00001000
 .byte %00001000
 .byte %00100010
 .byte %10000010
 .byte %00000010
 .byte %00010100
 .byte %01010101
; CHR $3D
 .byte %00101000
 .byte %00100000
 .byte %00100000
 .byte %10001000
 .byte %10000010
 .byte %10000000
 .byte %00010100
 .byte %01010101
; CHR $3E
 .byte %00101000
 .byte %00100000
 .byte %00100000
 .byte %00101010
 .byte %00100000
 .byte %00100000
 .byte %00010100
 .byte %01010101
; CHR $3F
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %11111111
 .byte %00000000
; CHR $40
 .byte %00000000
 .byte %00000000
 .byte %00001000
 .byte %00101010
 .byte %00101110
 .byte %00101010
 .byte %00001000
 .byte %00100010
; CHR $41
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
; CHR $42
 .byte %00000000
 .byte %00000000
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
; CHR $43
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
; CHR $44
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %10101010
 .byte %10101010
; CHR $45
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
; CHR $46
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
; CHR $47
 .byte %11000000
 .byte %11100000
 .byte %01110000
 .byte %00111000
 .byte %00011100
 .byte %00001110
 .byte %00000111
 .byte %00000011
; CHR $48
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00010100
 .byte %01010101
; CHR $49
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00001000
 .byte %00000000
 .byte %00101010
 .byte %00101000
; CHR $4A
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00100000
 .byte %00000000
 .byte %10101000
 .byte %00101000
; CHR $4B
 .byte %00001111
 .byte %00001111
 .byte %00001111
 .byte %00001111
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
; CHR $4C
 .byte %00111110
 .byte %00111110
 .byte %11111010
 .byte %11111010
 .byte %11101010
 .byte %11101010
 .byte %10101010
 .byte %10101010
; CHR $4D
 .byte %10111100
 .byte %10111100
 .byte %10101111
 .byte %10101111
 .byte %10101011
 .byte %10101011
 .byte %10101010
 .byte %10101010
; CHR $4E
 .byte %10101010
 .byte %10101010
 .byte %11101010
 .byte %11101010
 .byte %11111010
 .byte %11111010
 .byte %00111110
 .byte %00111110
; CHR $4F
 .byte %10101010
 .byte %10101010
 .byte %10101011
 .byte %10101011
 .byte %10101111
 .byte %10101111
 .byte %10111100
 .byte %10111100
; CHR $50
 .byte %00000000
 .byte %00111100
 .byte %00111100
 .byte %11111111
 .byte %11101011
 .byte %10101010
 .byte %10101010
 .byte %10101010
; CHR $51
 .byte %10101010
 .byte %10101010
 .byte %10101010
 .byte %11101011
 .byte %11111111
 .byte %00111100
 .byte %00111100
 .byte %00000000
; CHR $52
 .byte %10111100
 .byte %10111100
 .byte %10101111
 .byte %10101111
 .byte %10101111
 .byte %10101111
 .byte %10111100
 .byte %10111100
; CHR $53
 .byte %00111010
 .byte %00111010
 .byte %11101010
 .byte %11101010
 .byte %11101010
 .byte %11101010
 .byte %00111010
 .byte %00111010
; CHR $54
 .byte %00101000
 .byte %00101000
 .byte %00010100
 .byte %00101000
 .byte %00101000
 .byte %00010100
 .byte %00101000
 .byte %00101000
; CHR $55
 .byte %00101000
 .byte %00101000
 .byte %00010100
 .byte %00101010
 .byte %00101010
 .byte %00010100
 .byte %00101000
 .byte %00101000
; CHR $56
 .byte %00101000
 .byte %00101000
 .byte %00010100
 .byte %10101000
 .byte %10101000
 .byte %00010100
 .byte %00101000
 .byte %00101000
; CHR $57
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %10101010
 .byte %10101010
 .byte %00000000
 .byte %00000000
 .byte %00000000
; CHR $58
 .byte %00111100
 .byte %11111111
 .byte %11111111
 .byte %11000011
 .byte %11000011
 .byte %11111111
 .byte %11111111
 .byte %00111100
; CHR $59
 .byte %10101010
 .byte %10100010
 .byte %10000010
 .byte %10100010
 .byte %10100010
 .byte %10100010
 .byte %10101010
 .byte %10101010
; CHR $5A
 .byte %10101010
 .byte %10000010
 .byte %10100010
 .byte %10000010
 .byte %10001010
 .byte %10000010
 .byte %10101010
 .byte %10101010
; CHR $5B
 .byte %00000000
 .byte %00000000
 .byte %00000010
 .byte %00001010
 .byte %00001010
 .byte %00001010
 .byte %00000010
 .byte %00001000
; CHR $5C
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %10000000
 .byte %11000000
 .byte %10000000
 .byte %00000000
 .byte %10000000
; CHR $5D
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000010
 .byte %00000010
 .byte %00000010
 .byte %00000000
 .byte %00000010
; CHR $5E
 .byte %00000000
 .byte %00000000
 .byte %10000000
 .byte %10100000
 .byte %10100000
 .byte %10100000
 .byte %10000000
 .byte %00100000
; CHR $5F
 .byte %00000000
 .byte %00000000
 .byte %00100000
 .byte %10101000
 .byte %11101000
 .byte %10101000
 .byte %00100000
 .byte %10001000
; CHR $60
 .byte %00000000
 .byte %00011000
 .byte %00111100
 .byte %01111110
 .byte %01111110
 .byte %00111100
 .byte %00011000
 .byte %00000000
; CHR $61
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
; CHR $62
 .byte %00000000
 .byte %00010000
 .byte %01010001
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
; CHR $63
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00010100
 .byte %01010100
 .byte %01010101
 .byte %01010101
; CHR $64
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000100
 .byte %01000101
 .byte %01010101
; CHR $65
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01000101
 .byte %00000100
 .byte %00000000
; CHR $66
 .byte %01010101
 .byte %01010101
 .byte %01010101
 .byte %01010001
 .byte %01000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
; CHR $67
 .byte %01010101
 .byte %01010001
 .byte %00010000
 .byte %00010000
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %00000000
; CHR $68
 .byte %01000000
 .byte %01000000
 .byte %01010000
 .byte %01010000
 .byte %01000000
 .byte %01010000
 .byte %01010000
 .byte %01000000
; CHR $69
 .byte %01010100
 .byte %01010000
 .byte %01010000
 .byte %01010100
 .byte %01010000
 .byte %01010100
 .byte %01010100
 .byte %01010000
; CHR $6A
 .byte %00000101
 .byte %00000001
 .byte %00000001
 .byte %00000101
 .byte %00000101
 .byte %00000001
 .byte %00000101
 .byte %00000001
; CHR $6B
 .byte %00000101
 .byte %00010101
 .byte %00010101
 .byte %00000101
 .byte %00010101
 .byte %00010101
 .byte %00010101
 .byte %00000101
; CHR $6C
 .byte %00000000
 .byte %11000000
 .byte %11110000
 .byte %11111111
 .byte %01010101
 .byte %00100010
 .byte %00101010
 .byte %00001000
; CHR $6D
 .byte %00111100
 .byte %11111111
 .byte %11111111
 .byte %11111111
 .byte %01010101
 .byte %00100010
 .byte %10101010
 .byte %10001000
; CHR $6E
 .byte %00000000
 .byte %00000000
 .byte %00000000
 .byte %11110000
 .byte %01010101
 .byte %00100010
 .byte %10101010
 .byte %10001000
; CHR $6F
 .byte %00000010
 .byte %00001010
 .byte %00001000
 .byte %00101000
 .byte %00101000
 .byte %10101100
 .byte %10111100
 .byte %00111100
; CHR $70
 .byte %10000000
 .byte %10100000
 .byte %00100000
 .byte %00101000
 .byte %00101000
 .byte %00111010
 .byte %00111110
 .byte %00111100
; CHR $71
 .byte %00000000
 .byte %00000000
 .byte %00001010
 .byte %10101111
 .byte %10101111
 .byte %00001010
 .byte %00000000
 .byte %00000000
; CHR $72
 .byte %00000000
 .byte %00000000
 .byte %10100000
 .byte %11101010
 .byte %11101010
 .byte %10100000
 .byte %00000000
 .byte %00000000
; CHR $73-$7F BLANK
