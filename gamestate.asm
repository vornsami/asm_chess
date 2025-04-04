;
align 16
initGamestate:
        ;if there is already memory allocated, free that memory and reallocate
        cmp [board], 0
        je initGamestate_allocMem
    
    initGamestate_freeMem:

        invoke HeapFree, [glb_hAllocator], HEAP_NO_SERIALIZE, [board]
        mov [board], 0

    initGamestate_allocMem:
        ;allocate memory for the board and pieces
        mov rax, dataSize

        invoke HeapAlloc, [glb_hAllocator], HEAP_NO_SERIALIZE, rax
        mov [board], rax
        setBytes rax, dataSize, 0

        mov rcx, [board]
        
        initPieceVals rcx,    sizeof.PIECE, TypePawn,   8, whitePiece
        initPieceVals rcx,  2*sizeof.PIECE, TypePawn,   9, whitePiece
        initPieceVals rcx,  3*sizeof.PIECE, TypePawn,   10, whitePiece
        initPieceVals rcx,  4*sizeof.PIECE, TypePawn,   11, whitePiece
        initPieceVals rcx,  5*sizeof.PIECE, TypePawn,   12, whitePiece
        initPieceVals rcx,  6*sizeof.PIECE, TypePawn,   13, whitePiece
        initPieceVals rcx,  7*sizeof.PIECE, TypePawn,   14, whitePiece
        initPieceVals rcx,  8*sizeof.PIECE, TypePawn,   15, whitePiece

        initPieceVals rcx,  9*sizeof.PIECE, TypeRook,   0, whitePiece
        initPieceVals rcx, 10*sizeof.PIECE, TypeKnight, 1, whitePiece
        initPieceVals rcx, 11*sizeof.PIECE, TypeBishop, 2, whitePiece
        initPieceVals rcx, 12*sizeof.PIECE, TypeQueen,  3, whitePiece
        initPieceVals rcx, 13*sizeof.PIECE, TypeKing,   4, whitePiece
        initPieceVals rcx, 14*sizeof.PIECE, TypeBishop, 5, whitePiece
        initPieceVals rcx, 15*sizeof.PIECE, TypeKnight, 6, whitePiece
        initPieceVals rcx, 16*sizeof.PIECE, TypeRook,   7, whitePiece

        initPieceVals rcx, 17*sizeof.PIECE, TypePawn,   48, blackPiece
        initPieceVals rcx, 18*sizeof.PIECE, TypePawn,   49, blackPiece
        initPieceVals rcx, 19*sizeof.PIECE, TypePawn,   50, blackPiece
        initPieceVals rcx, 20*sizeof.PIECE, TypePawn,   51, blackPiece
        initPieceVals rcx, 21*sizeof.PIECE, TypePawn,   52, blackPiece
        initPieceVals rcx, 22*sizeof.PIECE, TypePawn,   53, blackPiece
        initPieceVals rcx, 23*sizeof.PIECE, TypePawn,   54, blackPiece
        initPieceVals rcx, 24*sizeof.PIECE, TypePawn,   55, blackPiece

        initPieceVals rcx, 25*sizeof.PIECE, TypeRook,   56, blackPiece
        initPieceVals rcx, 26*sizeof.PIECE, TypeKnight, 57, blackPiece
        initPieceVals rcx, 27*sizeof.PIECE, TypeBishop, 58, blackPiece
        initPieceVals rcx, 28*sizeof.PIECE, TypeQueen,  59, blackPiece
        initPieceVals rcx, 29*sizeof.PIECE, TypeKing,   60, blackPiece
        initPieceVals rcx, 30*sizeof.PIECE, TypeBishop, 61, blackPiece
        initPieceVals rcx, 31*sizeof.PIECE, TypeKnight, 62, blackPiece
        initPieceVals rcx, 32*sizeof.PIECE, TypeRook,   63, blackPiece

        mov BYTE [rcx + boardSize + pieceData + blackPiece], 60
        mov BYTE [rcx + boardSize + pieceData + whitePiece], 4

        call createVirtualBoard
        mov [moveBoard], rax

        ret

;rcx=start_tile, rdx=x, r8=y
align 16 
movePiece:  ;makes a move on the real board, and makes the checks related to that.
    ;uses:rax,rbx,r12,r13,r14
        ;Set the value of the target tile to be the id of the piece
        mov r14, rcx                                       ;start_tile
        mov r12, rdx                ;due to mul using rdx  ;x
        mov r13, r8                                        ;y

        mov rdx, rcx
        mov rcx, [board]
        
        ;PUT THE MOVES ON STACK HERE
        call putPiecePossibleMovesOnStack ;would be better if the turn was checked first, but this is more convinient in terms of registers

        ;check that it is currently the player's turn
        mov r9, [board]
        movzx r11, BYTE [r9 + r14]                          ;r11 piece_id
        mov r10, [currentTurn]
        movzx rcx, BYTE [r9+boardSize +r11+PIECE.owner]
        
        cmp r10, rcx
        jne skipMove
        
        convertToOffset r12, r13
        mov r8, rax                                         ;r8 end_tile
        ;Check that the move is possible (exists on stack)

        mov [stackStorage], rsp
        mov rsp, [moves]
        popByte rax
        cmp rax, r11
        jne movecheckLoop_restorePointer_skipmove
    movecheckLoop:
        popByte r15
        cmp r15, 0FFh
        je movecheckLoop_restorePointer_skipmove
        cmp r15, r8
        je movecheckLoop_restorePointer
        jmp movecheckLoop
    movecheckLoop_restorePointer_skipmove:
        mov rsp, [stackStorage]
        jmp skipMove
    movecheckLoop_restorePointer:
        mov rsp, [stackStorage]
        

        mov rcx, [board]
        mov rdx, r14
        ;r8 already has correct value
        call makeMoveOnBoard

        mov rax, [currentTurn]
        xor rax, 1
        mov [currentTurn], rax

        call checkGameState
    skipMove:
        ret

;rcx board_handle, rdx start_offset, r8 end_offset
align 16
makeMoveOnBoard:
        ;Check what is in the target tile
        mov r11, rcx
        movzx rbx, BYTE [r11 + rdx]     ;rbx  start tile value
        movzx rax, BYTE [r11 + r8]      ;rax target tile value

        cmp rbx, 0
        je skipMakeMove

        movzx r9, BYTE [r11+boardSize +rbx+PIECE.owner] 
        cmp rax, 0 ;skip checking target square if space is empty
        je finishMove

        ;Check if owners are the same, skip if are
        movzx r10, BYTE [r11+boardSize +rax+PIECE.owner]
        cmp r9, r10
        je skipMakeMove

        mov BYTE [r11+boardSize +rax+PIECE.type], 0 ;Mark the opponent's piece as taken by removing its type

    finishMove:
        movzx r10, BYTE [r11+boardSize +rbx+PIECE.type]
        ; if king, do special checks
        cmp r10, TypeKing
        je makemove_castle_check
        
        ; if pawn, check for upgrades
        cmp r10, TypePawn
        je makemove_pawn_upgrade_check

        jmp continueFinishMove

        makemove_castle_check:
            ; if king, write the position up
            mov BYTE [r11 + boardSize + pieceData + r9], r8b
            cmp rdx, r8
            jl makemove_castle_check_right
            makemove_castle_check_left:
                mov r12, rdx
                sub r12, r8

                cmp r12, 2
                jne continueFinishMove

                pushRegisters rax, rbx, rcx, rdx, r8, r9, r10, r11, r12
                mov rdx, r8
                sub rdx, 2
                add r8, 1
                call makeMoveOnBoard
                popRegisters rax, rbx, rcx, rdx, r8, r9, r10, r11, r12

                jmp continueFinishMove
            makemove_castle_check_right:
                mov r12, r8
                sub r12, rdx

                cmp r12, 2
                jne continueFinishMove

                pushRegisters rax, rbx, rcx, rdx, r8, r9, r10, r11, r12
                mov rdx, r8
                add rdx, 1
                sub r8, 1
                call makeMoveOnBoard
                popRegisters rax, rbx, rcx, rdx, r8, r9, r10, r11, r12
                jmp continueFinishMove
        makemove_pawn_upgrade_check:

            cmp r9, whitePiece
            jne makemove_pawn_upgrade_check_black
            makemove_pawn_upgrade_check_white:
                cmp r8, 56
                jl continueFinishMove
                mov BYTE [r11+boardSize +rbx+PIECE.type], TypeQueen
                jmp continueFinishMove
            makemove_pawn_upgrade_check_black:
                cmp r8, 8
                jge continueFinishMove
                mov BYTE [r11+boardSize +rbx+PIECE.type], TypeQueen
                jmp continueFinishMove

    continueFinishMove:
        ;Set the target tile to have the piece id
        mov BYTE [r11 + r8], bl
        ;Set the piece to have moved
        mov BYTE [r11+boardSize +rbx+PIECE.moved], 1
        ;Set the value of the original tile to be zero
        mov BYTE [r11 + rdx], 0
    skipMakeMove:
        ret

;rcx board_handle, rdx tile_offset
align 16
putPiecePossibleMovesOnStack:
        ;do not use r12, r13 or r14, they are reserved for other functions
        mov r9, rcx                           ;r9 board handle
        movzx r10, BYTE [r9 + rdx]            ;r10 piece_id
        mov r11, rdx                          ;r11 tile_offset
        movzx r15, BYTE [r9+boardSize +r10+PIECE.type]    ;r15 type
        

        mov rax, rdx
        mov r8, 8
        xor rdx, rdx
        div r8

        mov r8, rdx                           ;r8  x

        mov [stackStorage], rsp
        pushByte 0FFh

        cmp r15, 0
        je piecemoves_end

        cmp r15, TypePawn
        je piecemoves_pawn
        cmp r15, TypeKnight
        je piecemoves_knight
        cmp r15, TypeBishop
        je piecemoves_bishop
        cmp r15, TypeRook
        je piecemoves_rook
        cmp r15, TypeQueen
        je piecemoves_queen
        cmp r15, TypeKing
        je piecemoves_king

        jmp piecemoves_end
    piecemoves_pawn:
        movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner
        cmp r15, 0
        je piecemoves_pawn_black

        piecemoves_pawn_white:

                ;first move
                mov rdx, r11
                add rdx, 8
                cmp rdx, 64
                jge piecemoves_pawntakes_white

                movzx rax, BYTE [r9+rdx]
                cmp rax, 0
                jne piecemoves_pawntakes_white

                pushToStackIfNotCheck dl, r11, rdx, r15

                movzx r15, BYTE [r9+boardSize +r10+PIECE.moved] ;r15 moved
                cmp r15, 0
                jne piecemoves_pawntakes_white

                movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner
                ;second move
                mov rdx, r11
                add rdx, 16
                cmp rdx, 64
                jge piecemoves_pawntakes_white

                movzx rax, BYTE [r9+rdx]
                cmp rax, 0
                jne piecemoves_pawntakes_white

                pushToStackIfNotCheck dl, r11, rdx, r15

            piecemoves_pawntakes_white:
                movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner

                ;Pawn takes move
                piecemoves_pawntakes_white_right:
                    cmp r8, 7
                    je piecemoves_pawntakes_white_left

                    mov rdx, r11
                    add rdx, 9
                    cmp rdx, 64
                    jge piecemoves_end

                    movzx rax, BYTE [r9+rdx]

                    cmp rax, 0
                    je piecemoves_pawntakes_white_left

                    movzx rcx, BYTE [r9+boardSize +rax+PIECE.owner]
                    cmp rcx, r15
                    je piecemoves_pawntakes_white_left

                    pushToStackIfNotCheck dl, r11, rdx, r15

                piecemoves_pawntakes_white_left:
                    cmp r8, 0
                    je piecemoves_end

                    mov rdx, r11
                    add rdx, 7
                    cmp rdx, 64
                    jge piecemoves_end

                    movzx rax, BYTE [r9+rdx]

                    cmp rax, 0
                    je piecemoves_end

                    movzx rcx, BYTE [r9+boardSize +rax+PIECE.owner]
                    cmp rcx, r15
                    je piecemoves_end

                    pushToStackIfNotCheck dl, r11, rdx, r15

            jmp piecemoves_end
        piecemoves_pawn_black:

                ;first move
                cmp r11, 8
                jl piecemoves_pawntakes_black
                mov rdx, r11
                sub rdx, 8

                movzx rax, BYTE [r9+rdx]
                cmp rax, 0
                jne piecemoves_pawntakes_black

                pushToStackIfNotCheck dl, r11, rdx, r15

                movzx r15, BYTE [r9+boardSize +r10+PIECE.moved] ;r15 moved
                cmp r15, 0
                jne piecemoves_pawntakes_black

                movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner
                ;second move
                cmp r11, 16
                jl piecemoves_pawntakes_black
                mov rdx, r11
                sub rdx, 16

                movzx rax, BYTE [r9+rdx]
                cmp rax, 0
                jne piecemoves_pawntakes_white

                pushToStackIfNotCheck dl, r11, rdx, r15


            piecemoves_pawntakes_black:
                movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner

                ;Pawn takes move
                piecemoves_pawntakes_black_right:
                    cmp r8, 7
                    je piecemoves_pawntakes_black_left

                    cmp r11, 8
                    jl piecemoves_end
                    mov rdx, r11
                    sub rdx, 7

                    movzx rax, BYTE [r9+rdx]

                    cmp rax, 0
                    je piecemoves_pawntakes_black_left

                    movzx rcx, BYTE [r9+boardSize +rax+PIECE.owner]
                    cmp rcx, r15
                    je piecemoves_pawntakes_black_left

                    pushToStackIfNotCheck dl, r11, rdx, r15

                piecemoves_pawntakes_black_left:
                    cmp r8, 0
                    je piecemoves_end

                    cmp r11, 9
                    jl piecemoves_end
                    mov rdx, r11
                    sub rdx, 9

                    movzx rax, BYTE [r9+rdx]

                    cmp rax, 0
                    je piecemoves_end

                    movzx rcx, BYTE [r9+boardSize +rax+PIECE.owner]
                    cmp rcx, r15
                    je piecemoves_end

                    pushToStackIfNotCheck dl, r11, rdx, r15

            jmp piecemoves_end
    piecemoves_knight:
        movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner

        piecemoves_knight_left:
            cmp r8, 2
            jl piecemoves_knight_right

            piecemoves_knight_left_up:
                cmp r11, 56
                jge piecemoves_knight_left_down

                mov rbx, r11
                add rbx, 6
                movzx rax, BYTE [r9 + rbx]

                cmp rax, 0
                je piecemoves_knight_left_up_push
                
                movzx rdx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rdx, r15
                je piecemoves_knight_left_down
            piecemoves_knight_left_up_push:
                pushToStackIfNotCheck  bl, r11, rbx, r15

            piecemoves_knight_left_down:
                cmp r11, 8
                jl piecemoves_knight_right

                mov rbx, r11
                sub rbx, 10
                movzx rax, BYTE [r9 + rbx]

                cmp rax, 0
                je piecemoves_knight_left_down_push

                movzx rdx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rdx, r15
                je piecemoves_knight_right
            piecemoves_knight_left_down_push:
                pushToStackIfNotCheck  bl, r11, rbx, r15

        piecemoves_knight_right:
            cmp r8, 6
            jge piecemoves_knight_up

            piecemoves_knight_right_up:
                cmp r11, 56
                jge piecemoves_knight_right_down

                mov rbx, r11
                add rbx, 10
                movzx rax, BYTE [r9 + rbx]

                cmp rax, 0
                je piecemoves_knight_right_up_push

                movzx rdx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rdx, r15
                je piecemoves_knight_right_down
            piecemoves_knight_right_up_push:
                pushToStackIfNotCheck  bl, r11, rbx, r15

            piecemoves_knight_right_down:
                cmp r11, 8
                jl piecemoves_knight_up

                mov rbx, r11
                sub rbx, 6
                movzx rax, BYTE [r9 + rbx]

                cmp rax, 0
                je piecemoves_knight_right_down_push

                movzx rdx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rdx, r15
                je piecemoves_knight_up
            piecemoves_knight_right_down_push:
                pushToStackIfNotCheck  bl, r11, rbx, r15

        piecemoves_knight_up:
            cmp r11, 48
            jge piecemoves_knight_down

            piecemoves_knight_up_left:
                cmp r8, 0
                je piecemoves_knight_up_right

                mov rdx, r11
                add rdx, 15
                movzx rax, BYTE [r9 + rdx]

                cmp rax, 0
                je piecemoves_knight_up_left_push

                movzx rbx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rbx, r15
                je piecemoves_knight_up_right
            piecemoves_knight_up_left_push:
                pushToStackIfNotCheck  dl, r11, rdx, r15

            piecemoves_knight_up_right:
                cmp r8, 7
                je piecemoves_knight_down

                mov rdx, r11
                add rdx, 17
                movzx rax, BYTE [r9 + rdx]

                cmp rax, 0
                je piecemoves_knight_up_right_push

                movzx rbx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rbx, r15
                je piecemoves_knight_down
            piecemoves_knight_up_right_push:
                pushToStackIfNotCheck  dl, r11, rdx, r15

        piecemoves_knight_down:
            cmp r11, 16
            jl piecemoves_end

            piecemoves_knight_down_left:
                cmp r8, 0
                je piecemoves_knight_down_right

                mov rbx, r11
                sub rbx, 17
                movzx rax, BYTE [r9 + rbx]

                cmp rax, 0
                je piecemoves_knight_down_left_push

                movzx rdx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rdx, r15
                je piecemoves_knight_down_right
            piecemoves_knight_down_left_push:
                pushToStackIfNotCheck  bl, r11, rbx, r15


            piecemoves_knight_down_right:
                cmp r8, 7
                je piecemoves_end

                mov rbx, r11
                sub rbx, 15
                movzx rax, BYTE [r9 + rbx]

                cmp rax, 0
                je piecemoves_knight_down_right_push

                movzx rdx, BYTE [r9 + boardSize + rax + PIECE.owner]
                cmp rdx, r15
                je piecemoves_end
            piecemoves_knight_down_right_push:
                pushToStackIfNotCheck  bl, r11, rbx, r15
        jmp piecemoves_end
    piecemoves_bishop:
        movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner

        movForwardLeft r9, r11, r8, 7, r15
        movForwardRight r9, r11, r8, 7, r15
        movBackLeft r9, r11, r8, 7, r15
        movBackRight r9, r11, r8, 7, r15

        jmp piecemoves_end
    piecemoves_rook:
        movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner
        movForward r9, r11, 7, r15
        movBackward r9, r11, 7, r15
        movLeft r9, r11, r8, 7, r15
        movRight r9, r11, r8, 7, r15

        jmp piecemoves_end
    piecemoves_queen:
        movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner
        movForward r9, r11, 7, r15
        movBackward r9, r11, 7, r15
        movLeft r9, r11, r8, 7, r15
        movRight r9, r11, r8, 7, r15

        movForwardLeft r9, r11, r8, 7, r15
        movForwardRight r9, r11, r8, 7, r15
        movBackLeft r9, r11, r8, 7, r15
        movBackRight r9, r11, r8, 7, r15

        jmp piecemoves_end
    piecemoves_king:
        movzx r15, BYTE [r9+boardSize +r10+PIECE.moved] ;r15 moved

        cmp r15, 0
        jne piecemoves_nocastle

        movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner

            ;castling here
            
        pushRegisters rbx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
        mov rcx, r9
        mov rdx, r11
        mov r8, r15
        call isTileAttacked
        popRegisters rbx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
        cmp rax, 0
        jne piecemoves_nocastle

        piecemoves_castle_left:
            mov rbx, r11
            mov rdx, r8

            piecemoves_castle_left_loop:
                sub rbx, 1
                sub rdx, 1

                pushRegisters rbx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
                mov rcx, r9
                mov rdx, rbx
                mov r8, r15
                call isTileAttacked
                popRegisters rbx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
                cmp rax, 0
                jne piecemoves_castle_right

                movzx rcx, BYTE [r9+rbx]
                cmp rcx, 0
                jne piecemoves_castle_left_pieceCheck

                cmp rdx, 0
                jg piecemoves_castle_left_loop
                jmp piecemoves_castle_right

            piecemoves_castle_left_pieceCheck:

            movzx rdx, BYTE [r9+boardSize +rcx+PIECE.type] 
            cmp rdx, TypeRook
            jne piecemoves_castle_right

            movzx rdx, BYTE [r9+boardSize +rcx+PIECE.moved]
            cmp rdx, 0
            jne piecemoves_castle_right

            movzx rdx, BYTE [r9+boardSize +rcx+PIECE.owner]
            cmp r15, rdx
            jne piecemoves_castle_right

            mov rbx, r11
            sub rbx, 2
            pushByte bl

        piecemoves_castle_right:
            mov rbx, r11
            mov rdx, r8

            piecemoves_castle_right_loop:
                add rbx, 1
                add rdx, 1

                pushRegisters rbx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
                mov rcx, r9
                mov rdx, rbx
                mov r8, r15
                call isTileAttacked
                popRegisters rbx, rdx, r8, r9, r10, r11, r12, r13, r14, r15
                cmp rax, 0
                jne piecemoves_nocastle

                movzx rcx, BYTE [r9+rbx]
                cmp rcx, 0
                jne piecemoves_castle_right_pieceCheck

                cmp rdx, 7
                jl piecemoves_castle_right_loop
                jmp piecemoves_nocastle

            piecemoves_castle_right_pieceCheck:

            movzx rdx, BYTE [r9+boardSize +rcx+PIECE.type] 
            cmp rdx, TypeRook
            jne piecemoves_nocastle

            movzx rdx, BYTE [r9+boardSize +rcx+PIECE.moved]
            cmp rdx, 0
            jne piecemoves_nocastle

            movzx rdx, BYTE [r9+boardSize +rcx+PIECE.owner]
            cmp r15, rdx
            jne piecemoves_nocastle

            mov rbx, r11
            add rbx, 2
            pushByte bl

        piecemoves_nocastle:
            movzx r15, BYTE [r9+boardSize +r10+PIECE.owner] ;r15 owner
            movForward r9, r11, 1, r15
            movBackward r9, r11, 1, r15
            movLeft r9, r11, r8, 1, r15
            movRight r9, r11, r8, 1, r15

            movForwardLeft r9, r11, r8, 1, r15
            movForwardRight r9, r11, r8, 1, r15
            movBackLeft r9, r11, r8, 1, r15
            movBackRight r9, r11, r8, 1, r15

    piecemoves_end:
        pushByte r10b
        mov [moves], rsp
        mov rsp, [stackStorage]

        ret




;rcx board_handle, rdx tile_offset, r8 owner
align 16
isTileAttacked:

        mov r9, rdx         ;r9 starting offset
        mov rbx, 8        ;rbx offset
        mov rax, r9
        xor rdx, rdx
        div rbx

        mov r10, rdx         ;r10 x

    attacked_knight:
        attacked_knight_left:
            cmp r10, 2
            jl attacked_knight_right

            attacked_knight_left_up:
                cmp r9, 56
                jge attacked_knight_left_down

                mov rbx, r9
                add rbx, 6
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_knight_left_down
                
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_knight_left_down

                ret ;returns the id of an attacking piece in rax

            attacked_knight_left_down:
                cmp r9, 8
                jl attacked_knight_right

                mov rbx, r9
                sub rbx, 10
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_knight_right

                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_knight_right

                ret ;returns the id of an attacking piece in rax

        attacked_knight_right:
            cmp r10, 6
            jge attacked_knight_up

            attacked_knight_right_up:
                cmp r9, 56
                jge attacked_knight_right_down

                mov rbx, r9
                add rbx, 10
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_knight_right_down

                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_knight_right_down

                ret ;returns the id of an attacking piece in rax

            attacked_knight_right_down:
                cmp r9, 8
                jl attacked_knight_up

                mov rbx, r9
                sub rbx, 6
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_knight_up

                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_knight_up

                ret ;returns the id of an attacking piece in rax

        attacked_knight_up:
            cmp r9, 48
            jge attacked_knight_down

            attacked_knight_up_left:
                cmp r10, 0
                je attacked_knight_up_right

                mov rbx, r9
                add rbx, 15
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_knight_up_right

                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_knight_up_right

                ret ;returns the id of an attacking piece in rax

            attacked_knight_up_right:
                cmp r10, 7
                je attacked_knight_down

                mov rbx, r9
                add rbx, 17
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_knight_down

                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_knight_down

                ret ;returns the id of an attacking piece in rax

        attacked_knight_down:
            cmp r9, 16
            jl attacked_left

            attacked_knight_down_left:
                cmp r10, 0
                je attacked_knight_down_right

                mov rbx, r9
                sub rbx, 17
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_knight_down_right

                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_knight_down_right

                ret ;returns the id of an attacking piece in rax

            attacked_knight_down_right:
                cmp r10, 7
                je attacked_left

                mov rbx, r9
                sub rbx, 15
                movzx rax, BYTE [rcx + rbx]
                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

                cmp rdx, TypeKnight
                jne attacked_left

                movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
                cmp rdx, r8
                je attacked_left

                ret ;returns the id of an attacking piece in rax

    attacked_left:
            mov rbx, r9
            mov rdx, r10

            cmp rdx, 0
            jng attacked_right

        attacked_left_loop:
                sub rbx, 1
                sub rdx, 1

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_left_checkPiece

                cmp rdx, 0
                jng attacked_right
                jmp attacked_left_loop
        attacked_left_checkPiece:
            ;handle piece type checks yms.
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp rdx, TypeQueen
            je attacked_left_checkAttacker
            cmp rdx, TypeRook
            je attacked_left_checkAttacker
            cmp rdx, TypeKing
            jne attacked_right

            mov r11, r9
            sub r11, rbx
            cmp r11, 1
            jg attacked_right

        attacked_left_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_right

            ret
    attacked_right:
            mov rbx, r9
            mov rdx, r10

            cmp rdx, 7
            jnl attacked_up

            attacked_right_loop:
                add rbx, 1
                add rdx, 1

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_right_checkPiece

                cmp rdx, 7
                jnl attacked_up
                jmp attacked_right_loop
        attacked_right_checkPiece:
            ;handle piece type checks yms.
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp rdx, TypeQueen
            je attacked_right_checkAttacker
            cmp rdx, TypeRook
            je attacked_right_checkAttacker
            cmp rdx, TypeKing
            jne attacked_up

            mov r11, rbx
            sub r11, r9
            cmp r11, 1
            jg attacked_up

        attacked_right_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_up

            ret
    attacked_up:
            mov rbx, r9

            cmp rbx, 56
            jge attacked_down

            attacked_up_loop:
                add rbx, 8

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_up_checkPiece

                cmp rbx, 56
                jge attacked_down
                jmp attacked_up_loop
        attacked_up_checkPiece:
            ;handle piece type checks yms.
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp rdx, TypeQueen
            je attacked_up_checkAttacker
            cmp rdx, TypeRook
            je attacked_up_checkAttacker
            cmp rdx, TypeKing
            jne attacked_down

            mov r11, rbx
            sub r11, r9
            shr r11, 3
            cmp r11, 1
            jg attacked_down

        attacked_up_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_down

            ret

    attacked_down:
            mov rbx, r9

            cmp rbx, 8
            jl attacked_downLeft

            attacked_down_loop:
                sub rbx, 8

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_down_checkPiece

                cmp rbx, 8
                jl attacked_downLeft
                jmp attacked_down_loop
        attacked_down_checkPiece:
            ;handle piece type checks yms.
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp rdx, TypeQueen
            je attacked_down_checkAttacker
            cmp rdx, TypeRook
            je attacked_down_checkAttacker
            cmp rdx, TypeKing
            jne attacked_downLeft

            mov r11, r9
            sub r11, rbx
            shr r11, 3
            cmp r11, 1
            jg attacked_downLeft

        attacked_down_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_downLeft

            ret
    attacked_downLeft:
            mov rbx, r9
            mov rdx, r10

            cmp rdx, 0
            jng attacked_downRight

            cmp rbx, 8
            jl attacked_downRight
        attacked_downLeft_loop:
                sub rbx, 9
                sub rdx, 1

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_downLeft_checkPiece

                cmp rbx, 8
                jl attacked_downRight
                cmp rdx, 0
                jng attacked_downRight
                jmp attacked_downLeft_loop
        attacked_downLeft_checkPiece:
            ;handle piece type checks yms.
            movzx r12, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp r12, TypeQueen
            je attacked_downLeft_checkAttacker
            cmp r12, TypeBishop
            je attacked_downLeft_checkAttacker
            cmp r12, TypeRook
            je attacked_downRight
            cmp r12, TypeKnight
            je attacked_downRight

            ;kings and pawns can only attack one tile
            mov r11, r10
            sub r11, rdx
            cmp r11, 1
            jg attacked_downRight

            cmp r12, TypePawn
            jne attacked_downLeft_checkAttacker
            ;if pawn, check attack direction
            cmp r8, blackPiece
            jne attacked_downRight

        attacked_downLeft_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_downRight

            ret

    attacked_downRight:
            mov rbx, r9
            mov rdx, r10

            cmp rdx, 7
            jnl attacked_upLeft

            cmp rbx, 8
            jl attacked_upLeft

        attacked_downRight_loop:
                sub rbx, 7
                add rdx, 1

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_downRight_checkPiece

                cmp rbx, 8
                jl attacked_upLeft
                cmp rdx, 7
                jnl attacked_upLeft
                jmp attacked_downRight_loop
        attacked_downRight_checkPiece:
            ;handle piece type checks yms.
            movzx r12, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp r12, TypeQueen
            je attacked_downRight_checkAttacker
            cmp r12, TypeBishop
            je attacked_downRight_checkAttacker
            cmp r12, TypeRook
            je attacked_upLeft
            cmp r12, TypeKnight
            je attacked_upLeft

            ;kings and pawns can only attack one tile
            mov r11, rdx
            sub r11, r10
            cmp r11, 1
            jg attacked_upLeft

            cmp r12, TypePawn
            jne attacked_downRight_checkAttacker
            ;if pawn, check attack direction
            cmp r8, blackPiece
            jne attacked_upLeft

        attacked_downRight_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_upLeft

            ret

    attacked_upLeft:
            mov rbx, r9
            mov rdx, r10

            cmp rdx, 0
            jng attacked_upRight

            cmp rbx, 56
            jge attacked_upRight
        attacked_upLeft_loop:
                add rbx, 7
                sub rdx, 1

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_upLeft_checkPiece

                cmp rbx, 56
                jge attacked_upRight
                cmp rdx, 0
                jng attacked_upRight
                jmp attacked_upLeft_loop
        attacked_upLeft_checkPiece:
            ;handle piece type checks yms.
            movzx r12, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp r12, TypeQueen
            je attacked_upLeft_checkAttacker
            cmp r12, TypeBishop
            je attacked_upLeft_checkAttacker
            cmp r12, TypeRook
            je attacked_upRight
            cmp r12, TypeKnight
            je attacked_upRight

            ;kings and pawns can only attack one tile
            mov r11, r10
            sub r11, rdx
            cmp r11, 1
            jg attacked_upRight

            cmp r12, TypePawn
            jne attacked_upLeft_checkAttacker
            ;if pawn, check attack direction
            cmp r8, whitePiece
            jne attacked_upRight

        attacked_upLeft_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_upRight

            ret
    attacked_upRight:
            mov rbx, r9
            mov rdx, r10

            cmp rdx, 7
            jnl attacked_end

            cmp rbx, 56
            jge attacked_end

        attacked_upRight_loop:
                add rbx, 9
                add rdx, 1

                movzx rax, BYTE [rcx + rbx]
                cmp rax, 0
                jne attacked_upRight_checkPiece

                cmp rbx, 56
                jge attacked_end
                cmp rdx, 7
                jnl attacked_end
                jmp attacked_upRight_loop
        attacked_upRight_checkPiece:
            ;handle piece type checks yms.
            movzx r12, BYTE [rcx + boardSize + rax + PIECE.type]

            cmp r12, TypeQueen
            je attacked_upRight_checkAttacker
            cmp r12, TypeBishop
            je attacked_upRight_checkAttacker
            cmp r12, TypeRook
            je attacked_end
            cmp r12, TypeKnight
            je attacked_end

            ;kings and pawns can only attack one tile
            mov r11, rdx
            sub r11, r10
            cmp r11, 1
            jg attacked_end

            cmp r12, TypePawn
            jne attacked_upRight_checkAttacker
            ;if pawn, check attack direction
            cmp r8, whitePiece
            jne attacked_end

        attacked_upRight_checkAttacker:
            movzx rdx, BYTE [rcx + boardSize + rax + PIECE.owner]
            cmp rdx, r8
            je attacked_end

            ret

    attacked_end:
        mov rax, 0
        ret

;
align 16
createVirtualBoard:
        mov rax, dataSize
        invoke HeapAlloc, [glb_hAllocator], HEAP_NO_SERIALIZE, rax
        mov rcx, rax
        mov rbx, [board]

        cloneQWord rbx, rcx, dataQwords
        mov rax, rcx
        ret

;rcx handle
align 16
deleteVirtualBoard:
        invoke HeapFree, [glb_hAllocator], HEAP_NO_SERIALIZE, rcx
        ret

;
align 16
updateMoveBoard:
        mov rcx, [moveBoard]
        mov rbx, [board]

        cloneQWord rbx, rcx, dataQwords
        ret

;
align 16
checkGameState:

        mov rcx, [board]
        mov rdx, [currentTurn]
        call checkPlayerAvailableMoves
        cmp rax, 0
        jne gameState_noChange

        mov r8, [currentTurn]
        mov rcx, [board]
        movzx rdx, BYTE [rcx + boardSize + pieceData + r8]
        call isTileAttacked

        cmp rax, 0
        je gameState_tie

        mov r8, [currentTurn]

        cmp r8, blackPiece
        je gameState_whiteWin
        jmp gameState_blackWin

    gameState_tie:
        mov [gamestate], GameTie
        jmp gameState_noChange
    gameState_blackWin:
        mov [gamestate], GameBlackWin
        jmp gameState_noChange
    gameState_whiteWin:
        mov [gamestate], GameWhiteWin
    gameState_noChange:
        ret
;rcx board_handle, rdx player
align 16
checkPlayerAvailableMoves:
        xor r8, r8
        xor rax, rax
    availableMove_loop:
        movzx rbx, BYTE [rcx + r8]
        cmp rbx, 0
        je availableMove_loop_continue

        movzx r9, BYTE [rcx + boardSize + rbx + PIECE.owner]
        cmp r9, rdx
        jne availableMove_loop_continue
        pushRegisters rax, rbx, rcx, rdx, r8
        mov rdx, r8
        call putPiecePossibleMovesOnStack
        mov [stackStorage], rsp
        mov rsp, [moves]
        xor rax, rax
        popByte rbx
        
        availableMove_moveCountLoop:
            popByte rbx
            cmp rbx, 0FFh
            je availableMove_moveCountLoop_end

            add rax, 1
            jmp availableMove_moveCountLoop
        availableMove_moveCountLoop_end:
        mov rsp, [stackStorage]

        popRegisters r9, rbx, rcx, rdx, r8
        add rax, r9

    availableMove_loop_continue:
        add r8, 1
        cmp r8, 64
        jl availableMove_loop
    availableMove_loop_end:
        ret