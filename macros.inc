; ---------------------------------------------------------------------------
; FILE: macros.inc
; DATE: 22.01.2025
; ---------------------------------------------------------------------------

macro setBytes from, n, val
{
        a = 0
        while a < n
              mov BYTE [from + a], val
              a = a + 1
        end while
}

macro cloneBytes from, to, n
{
        a = 0
        while a < n
            movzx rax, BYTE [from + a]
            mov BYTE [to + a], al
            a = a + 1
        end while
}

macro cloneQWord from, to, n
{
        a = 0
        while a < n
            mov rax, QWORD [from + 8*a]
            mov QWORD [to + 8*a], rax
            a = a + 1
        end while
}

; ------------------------------------------------------------------------

macro pushMany r64, times
{
        val = 0
        while val < times
              push r64
              val = val + 1
        end while
}

macro pushByte r8bit {
        sub rsp, 1
        mov BYTE [rsp], r8bit
}
macro popByte r64 {
        movzx r64, BYTE [rsp]
        add rsp, 1
}

macro pushRegisters [r64] {
forward
        push r64
}

macro popRegisters [r64] {
reverse
        pop r64
}

; ---------------------------------------------------------------------------

macro coordsToBoard_X r64
{
    local coords_invalid, coords_end 
        mov rbx, tileSize
        shl rbx, 3
        
        cmp r64, startX
        jl  coords_invalid

        sub r64, startX
        cmp r64, rbx
        jg  coords_invalid

        mov rax, r64
        mov rbx, tileSize
        xor rdx,rdx 
        div rbx
        and rax, 0FFFFh
        mov r64, rax

        jmp coords_end
    coords_invalid:
        mov r64, 0FFh
    coords_end:
}
macro coordsToBoard_Y r64
{
    local coords_invalid, coords_end 
        cmp r64, startY
        jl  coords_invalid

        mov rbx, tileSize
        shl rbx, 3

        sub r64, startY
        cmp r64, rbx
        jg  coords_invalid

        mov rax, r64
        mov rbx, tileSize
        div rbx
        and rax, 0FFFFh
        mov r64, 7
        sub r64, rax

        jmp coords_end
    coords_invalid:
        mov r64, 0FFh
    coords_end:
}
macro coordsToBoard xreg, yreg
{
        coordsToBoard_X xreg
        coordsToBoard_Y yreg
}


macro boardToCoords_X r64
{
    local boards_invalid, boards_end 
        mov rax, r64

        cmp rax, 8
        jg boards_invalid

        mov rbx, tileSize
        mul rbx

        mov r64, rax
        add r64, startX
        jmp boards_end
    boards_invalid:
        mov r64, 0FFh
    boards_end:

}

macro boardToCoords_Y r64
{
    local boards_invalid, boards_end 
        mov rax, r64
        cmp rax, 8
        jg boards_invalid

        mov rax, 7
        sub rax, r64

        mov rbx, tileSize
        mul rbx
        mov r64, rax
        add r64, startY
        jmp boards_end
    boards_invalid:
        mov r64, 0FFh
    boards_end:

}


macro boardToCoords xreg, yreg
{
        boardToCoords_X xreg
        boardToCoords_Y yreg
}

; ---------------------------------------------------------------------------

macro initPieceVals loc, piece_id, type, pos, owner
{
        mov BYTE [loc + pos], piece_id
        mov BYTE [loc + boardSize + piece_id + PIECE.type], type
        mov BYTE [loc + boardSize + piece_id + PIECE.moved], 0
        mov BYTE [loc + boardSize + piece_id + PIECE.owner], owner
}

; ---------------------------------------------------------------------------

macro getBoardTile x, y
{
    local get_endt, get_invalid
        cmp x, 8
        jge get_invalid
        cmp y, 8
        jge get_invalid

        mov rcx, [board]
        mov rax, 8
        mov rbx, y
        mul rbx
        add rax, x
        movzx rax, BYTE [rcx + rax]
        jmp get_end
    get_invalid:
        xor rax, rax
    get_end:
}

; ---------------------------------------------------------------------------

macro convertToOffset x, y 
{
        mov rax, 8
        mov rbx, y
        mul rbx
        add rax, x
}


; ---------------------------------------------------------------------------

macro pushToStackIfNotCheck r8bit, start, end, owner
{
    local stackAdd_end, stackAdd_restoreRegisters
        sub rsp, 10h

        pushRegisters rax, rbx, rcx, rdx, r8
        call updateMoveBoard
        popRegisters rax, rbx, rcx, rdx, r8
        pushRegisters rax, rbx, rcx, rdx, r8, r9,r10,r11,r12,r13,r14
        mov rcx, [moveBoard]
        mov r8, end
        mov rdx, start
        
        call makeMoveOnBoard

        popRegisters r9,r10,r11,r12,r13,r14 ;maybe only pop the necessary ones
        movzx rdx, BYTE [rcx + boardSize + pieceData + owner]
        mov r8, owner
        pushRegisters r9,r10,r11,r12,r13,r14

        call isTileAttacked
        
        cmp rax, 0
        jne stackAdd_restoreRegisters

        popRegisters rax, rbx, rcx, rdx, r8, r9, r10, r11, r12, r13, r14
        add rsp, 10h
        pushByte r8bit
        jmp stackAdd_end

    stackAdd_restoreRegisters:
        popRegisters rax, rbx, rcx, rdx, r8, r9, r10, r11, r12, r13, r14
        add rsp, 10h
    stackAdd_end:
}


; ---------------------------------------------------------------------------

macro movForward usedboard, boardOffset, number, owner
{
    local forwardLoop, forwardLoop_end, forwardLoop_continue
        mov rdx, boardOffset
        mov rbx, number

    forwardLoop:
        add rdx, 8
        cmp rdx, 64
        jge forwardLoop_end
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je forwardLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je forwardLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp forwardLoop_end
    forwardLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rbx, 1
        cmp rbx, 0
        je forwardLoop_end
        jmp forwardLoop
    forwardLoop_end:
        mov rax, number
        sub rax, rbx
}

;replace with custom code for the pawns
macro movForwardNoTakes usedboard, boardOffset, number
{
    local forwardLoop, forwardLoop_end
        mov rdx, boardOffset
        mov rcx, number

    forwardLoop:
        add rdx, 8
        cmp rdx, 64
        jge forwardLoop_end
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        jne forwardLoop_end
        pushByte dl
        sub rcx, 1
        cmp rcx, 0
        je forwardLoop_end
        jmp forwardLoop
    forwardLoop_end:
}

macro movBackward usedboard, boardOffset, number, owner
{
    local backwardLoop, backwardLoop_end, backwardLoop_continue
        mov rdx, boardOffset
        mov rcx, number

    backwardLoop:
        cmp rdx, 8
        jl backwardLoop_end
        sub rdx, 8
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je backwardLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je backwardLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp backwardLoop_end
    backwardLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rcx, 1
        cmp rcx, 0
        je backwardLoop_end
        jmp backwardLoop
    backwardLoop_end:
        mov rax, number
        sub rax, rcx
}

;replace with custom code for pawns
macro movBackwardNoTakes usedboard, boardOffset, number
{
    local backwardLoop, backwardLoop_end, backwardLoop_continue
        mov rdx, boardOffset
        mov rcx, number

    backwardLoop:
        cmp rdx, 8
        jl backwardLoop_end
        sub rdx, 8
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        jne backwardLoop_end

    backwardLoop_continue:
        pushByte dl
        sub rcx, 1
        cmp rcx, 0
        je backwardLoop_end
        jmp backwardLoop
    backwardLoop_end:
        mov rax, number
        sub rax, rcx
}

macro movLeft usedboard, boardOffset, x, number, owner
{
    local leftLoop, leftLoop_end, leftLoop_continue
        mov rdx, boardOffset
        mov rcx, number

        cmp rcx, x
        jl leftLoop

        mov rcx, x

    leftLoop:
        cmp rcx, 0
        je leftLoop_end

        sub rdx, 1
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je leftLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je leftLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp leftLoop_end
    leftLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rcx, 1
        jmp leftLoop
    leftLoop_end:
        mov rax, number
        sub rax, rcx
}

macro movRight usedboard, boardOffset, x, number, owner
{
    local rightLoop, rightLoop_end, rightLoop_continue
        mov rdx, boardOffset
        mov rcx, number

        mov rax, 7
        sub rax, x

        cmp rcx, rax
        jl rightLoop

        mov rcx, rax

    rightLoop:
        cmp rcx, 0
        je rightLoop_end

        add rdx, 1
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je rightLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je rightLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp rightLoop_end
    rightLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rcx, 1
        jmp rightLoop
    rightLoop_end:
        mov rax, number
        sub rax, rcx
}

macro movForwardLeft usedboard, boardOffset, x, number, owner
{
    local leftLoop, leftLoop_end, leftLoop_continue
        mov rdx, boardOffset
        mov rcx, number

        cmp rcx, x
        jl leftLoop

        mov rcx, x

    leftLoop:
        cmp rcx, 0
        je leftLoop_end

        add rdx, 7
        cmp rdx, 64
        jge leftLoop_end
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je leftLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je leftLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp leftLoop_end
    leftLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rcx, 1
        jmp leftLoop
    leftLoop_end:
        mov rax, number
        sub rax, rcx
}

macro movForwardRight usedboard, boardOffset, x, number, owner
{
    local rightLoop, rightLoop_end, rightLoop_continue
        mov rdx, boardOffset
        mov rcx, number

        mov rax, 7
        sub rax, x

        cmp rcx, rax
        jl rightLoop

        mov rcx, rax

    rightLoop:
        cmp rcx, 0
        je rightLoop_end

        add rdx, 9
        cmp rdx, 64
        jge rightLoop_end
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je rightLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je rightLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp rightLoop_end
    rightLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rcx, 1
        jmp rightLoop
    rightLoop_end:
        mov rax, number
        sub rax, rcx
}


macro movBackLeft usedboard, boardOffset, x, number, owner
{
    local leftLoop, leftLoop_end, leftLoop_continue
        mov rdx, boardOffset
        mov rcx, number

        cmp rcx, x
        jl leftLoop

        mov rcx, x

    leftLoop:
        cmp rcx, 0
        je leftLoop_end
        cmp rdx, 8
        jl leftLoop_end

        sub rdx, 9
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je leftLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je leftLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp leftLoop_end
    leftLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rcx, 1
        jmp leftLoop
    leftLoop_end:
        mov rax, number
        sub rax, rcx
}

macro movBackRight usedboard, boardOffset, x, number, owner
{
    local rightLoop, rightLoop_end, rightLoop_continue
        mov rdx, boardOffset
        mov rcx, number

        mov rax, 7
        sub rax, x

        cmp rcx, rax
        jl rightLoop

        mov rcx, rax

    rightLoop:
        cmp rcx, 0
        je rightLoop_end
        cmp rdx, 8
        jl rightLoop_end

        sub rdx, 7
        movzx rax, BYTE [usedboard+rdx]

        cmp rax, 0
        je rightLoop_continue

        movzx rax, BYTE [usedboard+boardSize +rax+PIECE.owner]

        cmp rax, owner
        je rightLoop_end
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        jmp rightLoop_end
    rightLoop_continue:
        pushToStackIfNotCheck dl, boardOffset, rdx, owner
        sub rcx, 1
        jmp rightLoop
    rightLoop_end:
        mov rax, number
        sub rax, rcx
}

; ---------------------------------------------------------------------------

macro drawBoardSquare function, r64, brush
{
        ;calculate x
        mov rax, r64
        mov rcx, tileSize
        and rax, 7
        mul rcx
        add rax, startX
        mov rcx, rax

        ;calculate y
        mov rbx, r64
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
        
        invoke function, [glb_hdc], r10, [brush]
        add rsp, 10h
}


macro drawSquare startx, starty, size, brush
{
        mov rcx, startx
        mov rbx, starty

        sub rsp, 10h
        mov [rsp], rcx
        mov [rsp+4], rbx
        
        add rcx, size
        add rbx, size

        mov [rsp+8], ecx
        mov [rsp+12], ebx
        mov rax, rsp
        add rsp, 10h
        invoke FillRect, [glb_hdc], rax, [brush]
}
