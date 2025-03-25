;Board
align 16
initDraw:
        ;Board tile colour brushes
        invoke CreateSolidBrush, [lightBrushCol]
        mov [lightBrush], rax
        invoke CreateSolidBrush, [darkBrushCol]
        mov [darkBrush], rax
    
        invoke CreateSolidBrush, [selectedBrushCol]
        mov [selectedBrush], rax
        invoke CreateSolidBrush, [secSelectedBrushCol]
        mov [secSelectedBrush], rax

        invoke CreateSolidBrush, [blackBrushCol]
        mov [blackBrush], rax
        invoke CreateSolidBrush, [whiteBrushCol]
        mov [whiteBrush], rax

        ;For some reason this needs to be the last HeapAlloc, otherwise the pieces do not get drawn correctly
        invoke HeapAlloc, [glb_hAllocator], HEAP_NO_SERIALIZE, 40h
        mov [glb_bitmaps], rax
        mov r12, rax

        mov r13, 2
    bitmapLoop:
        invoke LoadBitmap, [glb_hInstance], r13
        mov [r12 + 8*r13], rax

        add r13, 1
        cmp r13, 14
        jl bitmapLoop
    bitmapLoop_end:
        ret

align 16
drawBoard:
        call drawBoard_base
        call drawBoard_letters
        ret

align 16
drawBoard_base:
        ;FillRect messes with the values stored in some registers, so I opted to use registers r11-r15
        xor r11, r11            ;even/odd row
        mov r12, 1              ;light/dark square
        xor r13, r13            ;The tile number
        mov r14, sizeof.RECT    ;The offset between tiles
    drawloop:
        ;check if row even
        mov r11, r13
        shr r11, 3
        and r11, 1

        ;calculate x
        mov rax, r13
        mov rcx, tileSize
        and rax, 7
        mul rcx
        add rax, startX
        mov rcx, rax

        ;calculate y
        mov rbx, r13
        shr rbx, 3
        mov rax, 7
        sub rax, rbx
        mov rbx, tileSize
        mul rbx
        add rax, startY
        mov rbx, rax

        ;put them to the stack 
        sub rsp, 10h
        mov [rsp], ecx
        mov [rsp+4], ebx
        
        add rcx, tileSize
        add rbx, tileSize

        mov [rsp+8], ecx
        mov [rsp+12], ebx
        mov r10, rsp

        ;check if light or dark square
        cmp r12, r11
        je fillLight
    fillDark:
        invoke FillRect, [glb_hdc], r10, [darkBrush]
        jmp afterFill
    fillLight:
        invoke FillRect, [glb_hdc], r10, [lightBrush]
    afterFill:
        ;update values and loop
        add rsp, 10h
        xor r12, 1
        add r13, 1
        cmp r13, 64
        je drawloop_end
        jmp drawloop
    drawloop_end:
        ret


align 16
drawBoard_letters:

        mov r12, startX
        mov r13, startY
        mov r14, tileSize

        sub r12, 20

        mov rbx, r14
        shr rbx, 1
        add r13, rbx

        invoke TextOut, [glb_hdc], r12, r13, '8', 1
        add r13, r14
        invoke TextOut, [glb_hdc], r12, r13, '7', 1
        add r13, r14
        invoke TextOut, [glb_hdc], r12, r13, '6', 1
        add r13, r14
        invoke TextOut, [glb_hdc], r12, r13, '5', 1
        add r13, r14
        invoke TextOut, [glb_hdc], r12, r13, '4', 1
        add r13, r14
        invoke TextOut, [glb_hdc], r12, r13, '3', 1
        add r13, r14
        invoke TextOut, [glb_hdc], r12, r13, '2', 1
        add r13, r14
        invoke TextOut, [glb_hdc], r12, r13, '1', 1

        add r13, rbx
        add r13, 10
        add r12, 20

        add r12, rbx
        invoke TextOut, [glb_hdc], r12, r13, 'a', 1
        add r12, r14
        invoke TextOut, [glb_hdc], r12, r13, 'b', 1
        add r12, r14
        invoke TextOut, [glb_hdc], r12, r13, 'c', 1
        add r12, r14
        invoke TextOut, [glb_hdc], r12, r13, 'd', 1
        add r12, r14
        invoke TextOut, [glb_hdc], r12, r13, 'e', 1
        add r12, r14
        invoke TextOut, [glb_hdc], r12, r13, 'f', 1
        add r12, r14
        invoke TextOut, [glb_hdc], r12, r13, 'g', 1
        add r12, r14
        invoke TextOut, [glb_hdc], r12, r13, 'h', 1

        ret


;Pieces
align 16
drawAllPieces:
        mov r13, [board]

        cmp r13, 0
        je draw_end

        mov r15, 0

    pieceLoop:
        movzx rcx, BYTE [r13+r15]
        cmp rcx, 0
        je pieceLoop_next

        mov rax, r15
        mov rbx, 8
        xor rdx, rdx
        div rbx
        mov r8, rax

        mov r9, rdx ;due to mul using rdx
        boardToCoords r9, r8
        mov rdx, r9

        call drawPiece
    pieceLoop_next:
        add r15, 1
        cmp r15, boardSize
        jl pieceLoop
    pieceLoop_end:

        ret

;rcx piece_id, rdx real_x, r8 real_y
align 16
drawPiece:
        ; this check is usually useless, but there may be a case in the future where this is called outside drawAllPieces
        mov rbx, [board]
        movsx rbx, BYTE [rbx+boardSize +rcx+PIECE.type]
        cmp rbx, 0
        je draw_end

        mov [bmdrawX], rdx
        mov [bmdrawY], r8

        call drawPieceBitmap
    draw_end:
        ret


;rcx piece_id
align 16
drawPieceBitmap:
        mov rbx, [board]
        movsx rdx, BYTE [rbx+boardSize +rcx+PIECE.type]
        mov r14, [glb_bitmaps]
        movsx rax, BYTE [rbx+boardSize +rcx+PIECE.owner]
        shl rax, 3
        add r14, rax
        shl rdx, 4
        mov r14, [r14 + rdx]

        invoke CreateCompatibleDC, [glb_hdc]
        mov [hdcMem], rax
        invoke SelectObject, [hdcMem], r14
        invoke TransparentBlt, [glb_hdc], [bmdrawX], [bmdrawY], tileSize, tileSize, [hdcMem], 0,0,imgSize,imgSize, 0FFFFFFh
        invoke DeleteDC, [hdcMem]

        ret

align 16
drawSelected:
        mov r13, [selectedTile]
        cmp r13, 0FFh
        je skipSelectDraw

        drawBoardSquare FrameRect, r13, selectedBrush

        mov r14, rsp
        sub rsp, 10h
        mov rcx, [board]
        mov rdx, [selectedTile]
        call putPiecePossibleMovesOnStack
        
        mov rcx, [selectedPiece]
        mov rsp, [moves]

        popByte rax

        cmp rax, rcx
        jne selectDraw_restorePointer

    possibleMoveDrawLoop:
        popByte r13
        cmp r13, 0FFh
        je selectDraw_restorePointer
        mov r12, rsp
        mov rsp, r14
        drawBoardSquare FrameRect, r13, secSelectedBrush
        mov rsp, r12
        jmp possibleMoveDrawLoop
    selectDraw_restorePointer:
        mov rsp, r14
    skipSelectDraw:
        ret

;
align 16
drawGamestate:
        mov r8, boardDrawSize + startX + 10
        mov r9, startY + 10
        
        cmp [gamestate], GameError
        je drawGamestate_end
        cmp [gamestate], GameMenu
        je drawGamestate_end

        pushRegisters r8, r9

        cmp [gamestate], GameBlackWin
        je drawGamestate_blackWin
        cmp [gamestate], GameWhiteWin
        je drawGamestate_whiteWin
        cmp [gamestate], GameTie
        je drawGamestate_tie

        ;Draw the current player's turn

        cmp [currentTurn], whitePiece
        je drawGamestate_whiteTurn

    drawGamestate_blackTurn:
        drawSquare r8, r9, infoSquareSize, blackBrush
        popRegisters r8, r9
        add r8, infoSquareSize + 5
        invoke TextOut, [glb_hdc], r8, r9, 'Black turn', 10
        ret
    drawGamestate_whiteTurn:
        drawSquare r8, r9, infoSquareSize, whiteBrush
        popRegisters r8, r9
        add r8, infoSquareSize + 5
        invoke TextOut, [glb_hdc], r8, r9, 'White turn', 10
        ret


    drawGamestate_blackWin:
        drawSquare r8, r9, infoSquareSize, blackBrush
        popRegisters r8, r9
        add r8, infoSquareSize + 5
        invoke TextOut, [glb_hdc], r8, r9, 'Black Wins!', 11
        ret
    drawGamestate_whiteWin:
        drawSquare r8, r9, infoSquareSize, whiteBrush
        popRegisters r8, r9
        add r8, infoSquareSize + 5
        invoke TextOut, [glb_hdc], r8, r9, 'White Wins!', 11
        ret
    drawGamestate_tie:
        invoke TextOut, [glb_hdc], r8, r9, 'Tie', 3
        ret
    drawGamestate_end:
        ret