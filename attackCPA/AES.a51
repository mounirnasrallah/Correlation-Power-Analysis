;;; Key in EEPROM. to be personalized
masterkey   EQU 0x1000

;;; interruption vectors table
        CSEG AT 0x0000
        ljmp main
        CSEG AT 0x0003
        reti
        CSEG AT 0x000B
        reti
        CSEG AT 0x0013
        reti
        CSEG AT 0x001B
        reti
        CSEG AT 0x0023
        reti

;;; exit point for the simulator
        CSEG AT 0x002B
exit:   sjmp    $

;;; data segment
        DSEG
state:  DS  16
key:    DS  16

;;; xdata segment (buffer for input message)
        XSEG AT 0x0000
buffer:
        DS  16

;;; code segment
        CSEG AT 0x0030
main:
;;; read buffer into internal state
        mov     R0, #state
        mov     DPTR, #buffer
main_read_loop:
        movx    A, @DPTR
        mov     @R0, A
        inc     DPTR
        inc     R0
        cjne    R0, #state+16, main_read_loop
;;; process AES on internal state
        acall   InitKey
        acall   AddRoundKey
        acall   KeySchedule
        mov     R3, #9
main_rounds_loop:
        acall   SubBytes
        acall   ShiftRows
        acall   MixColumns
        acall   AddRoundKey
        acall   KeySchedule
        djnz    R3, main_rounds_loop
        acall   SubBytes
        acall   ShiftRows
        acall   AddRoundKey
;;; write internal state into buffer
        mov     R0, #state
        mov     DPTR, #buffer
main_write_loop:
        mov     A, @R0
        movx    @DPTR, A
        inc     R0
        inc     DPTR
        cjne    R0, #state+16, main_write_loop
;;; exit
        ljmp    exit

;;; Initialize key register with master key
InitKey:
        mov     R1, #key
        mov     DPTR, #masterkey
        mov     R7, #0
InitKey_copy_loop:
        mov     A, R7
        movc    A, @A+DPTR
        mov     @R1, A
        inc     R1
        inc     R7
        cjne    R7, #16, InitKey_copy_loop
        mov     R2, #0x01
        ret

;;; AddRoundKey function
AddRoundKey:
        mov     R0, #state
        mov     R1, #key
AddRoundKey_xor_loop:
        mov     A, @R0
        xrl     A, @R1
        mov     @R0, A
        inc     R0
        inc     R1
        cjne    R0, #state+16, AddRoundKey_xor_loop
        ret

;;; SubBytes function
SubBytes:
        mov     R0, #state
        mov     DPTR, #SBox
SubBytes_process_loop:
        mov     A, @R0
        movc    A, @A+DPTR
        mov     @R0, A
        inc     R0
        cjne    R0, #state+16, SubBytes_process_loop
        ret

;;; ShiftRows function
ShiftRows:
        mov     A, state+1
        mov     state+1, state+5
        mov     state+5, state+9
        mov     state+9, state+13
        mov     state+13, A
        mov     A, state+2
        mov     state+2, state+10
        mov     state+10, A
        mov     A, state+6
        mov     state+6, state+14
        mov     state+14, A
        mov     A, state+3
        mov     state+3, state+15
        mov     state+15, state+11
        mov     state+11, state+7
        mov     state+7, A
        ret

;;; MixColumns function
MixColumns:
        mov     R0, #state
        mov     R1, #state+1
MixColumns_process_loop:
        mov     A, @R0
        mov     R7, A
        xrl     A, @R1
        inc     R1
        xrl     A, @R1
        inc     R1
        xrl     A, @R1
        mov     R6, A
        dec     R1
        dec     R1
        mov     R5, #3
MixColumns_inner_loop:
        mov     A, @R0
        xrl     A, @R1
        acall   Mult2
        xrl     A, R6
        xrl     A, @R0
        mov     @R0, A
        inc     R0
        inc     R1
        djnz    R5, MixColumns_inner_loop
        mov     A, @R0
        xrl     A, R7
        acall   Mult2
        xrl     A, R6
        xrl     A, @R0
        mov     @R0, A
        inc     R0
        inc     R1
        cjne    R0, #state+16, MixColumns_process_loop
        ret

;;; multiplication by x in ext<GF(2)|x^8+x^4+x^3+x+1>
Mult2:
        clr     C
        rlc     A
        mov     R4, A
        clr     A
        subb    A, #0
        anl     A, #0x1B
        xrl     A, R4
        ret

;;; KeySchedule function
KeySchedule:
        mov     DPTR, #SBox
        mov     A, key+13
        movc    A, @A+DPTR
        xrl     A, R2
        xrl     key, A
        mov     A, key+14
        movc    A, @A+DPTR
        xrl     key+1, A
        mov     A, key+15
        movc    A, @A+DPTR
        xrl     key+2, A
        mov     A, key+12
        movc    A, @A+DPTR
        xrl     key+3, A
        mov     R0, #key
        mov     R1, #key+4
KeySchedule_xor_loop:
        mov     A, @R0
        xrl     A, @R1
        mov     @R1, A
        inc     R0
        inc     R1
        cjne    R1, #key+16, KeySchedule_xor_loop
        mov     A, R2
        acall   Mult2
        mov     R2, A
        ret

;;; AES SBox
SBox:   DB  0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5
        DB  0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76
        DB  0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0
        DB  0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0
        DB  0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC
        DB  0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15
        DB  0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A
        DB  0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75
        DB  0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0
        DB  0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84
        DB  0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B
        DB  0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF
        DB  0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85
        DB  0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8
        DB  0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5
        DB  0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2
        DB  0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17
        DB  0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73
        DB  0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88
        DB  0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB
        DB  0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C
        DB  0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79
        DB  0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9
        DB  0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08
        DB  0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6
        DB  0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A
        DB  0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E
        DB  0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E
        DB  0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94
        DB  0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF
        DB  0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68
        DB  0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16
