; ---------------------------------------------------------------------------
; FILE: gamestate.inc
; DATE: 31.01.2025
; ---------------------------------------------------------------------------

TypePawn        equ 1
TypeKnight      equ 2
TypeBishop      equ 3
TypeRook        equ 4
TypeQueen       equ 5
TypeKing        equ 6


blackPiece      equ 0
whitePiece      equ 1


boardSize       equ 64
pieceData       equ 33 * sizeof.PIECE
dataSize        equ boardSize + pieceData + 16 - sizeof.PIECE
dataQwords      equ 8 + sizeof.PIECE * 4 + 2


GameRun         equ 0
GameWhiteWin    equ 1
GameBlackWin    equ 2
GameTie         equ 3
GameMenu        equ 10h
GameSelect      equ 11h
GameError       equ 0FFh


; ---------------------------------------------------------------------------

struct PIECE
    type       db      ?
    owner      db      ?
    moved      db      ?
ends

struct MOVE
    piece_id   db      ?
    start      db      ?
    end        db      ?
    takes      db      ?
    check      db      ?
    mate       db      ?
ends

; ---------------------------------------------------------------------------

board           dq      0
moveBoard       dq      0

gamestate       dq      GameRun
currentTurn     dq      1

moves           dq      0
stackStorage    dq      0