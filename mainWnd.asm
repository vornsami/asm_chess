align 16
MainWnd_Run:

        ; Register WNDCLASS by pushing windowclass to stack, and moving the pointer to rcx
        xor rbx, rbx
        push 10027h                ;hIconSm
        push str_WndClass          ;lpszClassName
        push rbx                   ;lpszMenuName
        push COLOR_WINDOW          ;hbrBackground
        push 10005h                ;hCursor
        push 10027h                ;hIcon
        push [glb_hInstance]       ;hInstance
        push rbx                   ;cbClsExtra & cbWndExtra
        push WindowProc            ;lpfnWndProc
        push sizeof.WNDCLASSEX     ;cbSize & style
        mov rcx, rsp               ;addr WNDCLASSEX
        call [RegisterClassEx]

        ; Create window
        invoke CreateWindowExW, 0, \
                str_WndClass, str_WndTitle, WS_OVERLAPPEDWINDOW+WS_VISIBLE, \ 
                128, 128,  tileSize*8+startX*2+50,  tileSize*8+startY*2+50, \
                NULL, NULL, glb_hInstance, NULL
        mov [glb_hwnd], rax ;CreateWindowExW returns hwnd

        invoke ShowWindow, glb_hwnd, SW_SHOW
        invoke UpdateWindow, glb_hwnd

;Message handling
@@:
        invoke GetMessageW, msg, NULL, 0, 0
        invoke TranslateMessage, msg
        invoke DispatchMessage, msg
        jmp @b

align 16
WindowProc:
        enter sizeof.PAINTSTRUCT+98h,0
                cmp rdx,WM_DESTROY
                je wmDESTROY
                cmp rdx,WM_LBUTTONDOWN
                je wmLBUTTONDOWN
                cmp rdx,WM_RBUTTONDOWN
                je wmRBUTTONDOWN
                cmp rdx,WM_PAINT
                je wmPAINT
                leave

        jmp [DefWindowProc]

wmDESTROY:
        invoke ExitProcess, 0
wmPAINT:
        invoke BeginPaint, [glb_hwnd], ps
        mov [glb_hdc], rax
        
        ;Board
        call drawBoard

        call drawSelected

        ;Pieces
        call drawAllPieces

        call drawGamestate

        invoke EndPaint, [glb_hwnd], ps
        jmp wmBYE
wmLBUTTONDOWN: ;x coord in lower 16 bits, y in upper 16 bits of the lower 32 bits

        mov rax, r9
        and rax, 0FFFFh
        mov r10, rax            ;r10 real_x

        mov rax, r9
        shr rax, 16
        mov r11, rax            ;r11 real_y

        xor rdx,rdx 
        coordsToBoard r10, r11  ;r10 x, r11 y

        cmp r10, 8
        jge LButton_End
        cmp r11, 8
        jge LButton_End

        ;calculate which tile is selected

        cmp [selectedTile], 0FFh
        je LButton_Select

        mov rax, 8
        mul r11
        add rax, r10
        cmp [selectedTile], rax
        je LButton_Deselect

        cmp [gamestate], GameRun
        jne LButton_Select

        mov rcx, [selectedTile]        
        mov rdx, r10
        mov r8, r11
        pushRegisters r10, r11, r12, r13, r14, r15
        call movePiece
        ;doesn't play a sound for some reason, the resource is not loading
        invoke PlaySound, 101, [glb_hInstance], SND_RESOURCE or SND_SYNC

        popRegisters r10, r11, r12, r13, r14, r15

    LButton_Deselect:
        mov [selectedTile], 0FFh
        mov [selectedPiece], 0
        jmp LButton_End
    LButton_Select:
        mov rax, 8
        mul r11
        add rax, r10
        mov [selectedTile], rax

        mov rcx, [board]
        movzx r15, BYTE [rcx + rax]

        cmp r15, 0
        je LButton_End

        mov [selectedPiece], r15
    LButton_End:
        invoke InvalidateRect, [glb_hwnd], 0, TRUE
        jmp wmBYE
wmRBUTTONDOWN:
        mov [selectedTile], 0FFh
        mov [selectedPiece], 0
        invoke InvalidateRect, [glb_hwnd], 0, TRUE
        jmp wmBYE
wmERROR:
        invoke ExitProcess, 0
wmBYE:
        leave
        retn
