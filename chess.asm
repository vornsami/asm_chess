format PE64 NX GUI 6.0
entry start

include 'win64wx.inc'
include 'macros.inc'

stack 4000h, 4000h

section '.data' data readable writeable
        include 'globals.inc'
        include 'mainWnd.inc'
        include 'boardDraw.inc'
        include 'gamestate.inc'

section '.code' code readable executable
        include 'mainWnd.asm'
        include 'boardDraw.asm'
        include 'gamestate.asm'

align 16
start:
        invoke GetModuleHandleW, NULL
        mov [glb_hInstance], rax
        invoke HeapCreate, HEAP_NO_SERIALIZE, 1000h, 0
        mov [glb_hAllocator], rax

        call initGamestate
        call initDraw
        call MainWnd_Run
        invoke ExitProcess, 0

section '.idata' import data readable writeable

        library kernel32,'KERNEL32.DLL',user32,'USER32.DLL',gdi32,'GDI32.DLL',msimg,'MSIMG32.DLL', winmm, 'WINMM.DLL'

        include 'API\Kernel32.Inc'
        include 'API\User32.Inc'
        include 'API\Gdi32.Inc'
        
        import msimg, \
                TransparentBlt, 'TransparentBlt'

        import winmm, \
                PlaySound, 'PlaySound'

section '.rsrc' resource data readable
        directory \
                RT_BITMAP, bitmaps, \
                RT_RCDATA, sounds

        resource bitmaps, \
                1, LANG_NEUTRAL,img_pawn, \
                2, LANG_NEUTRAL,img_pawnB, \
                3, LANG_NEUTRAL,img_pawnW, \
                4, LANG_NEUTRAL,img_knightB, \
                5, LANG_NEUTRAL,img_knightW, \
                6, LANG_NEUTRAL,img_bishopB, \
                7, LANG_NEUTRAL,img_bishopW, \
                8, LANG_NEUTRAL,img_rookB, \
                9, LANG_NEUTRAL,img_rookW, \
                10, LANG_NEUTRAL,img_queenB, \
                11, LANG_NEUTRAL,img_queenW, \
                12, LANG_NEUTRAL,img_kingB, \
                13, LANG_NEUTRAL,img_kingW 

        resource sounds, \
                101, LANG_NEUTRAL, wav_plap

        bitmap img_pawn, 'res\pawn'
        bitmap img_pawnB, 'res\pawnB'
        bitmap img_pawnW, 'res\pawnW'
        bitmap img_knightB, 'res\knightB'
        bitmap img_knightW, 'res\knightW'
        bitmap img_bishopB, 'res\bishopB'
        bitmap img_bishopW, 'res\bishopW'
        bitmap img_rookB, 'res\rookB'
        bitmap img_rookW, 'res\rookW'
        bitmap img_queenB, 'res\queenB'
        bitmap img_queenW, 'res\queenW'
        bitmap img_kingB, 'res\kingB'
        bitmap img_kingW, 'res\kingW'
        
        wav_plap file 'res\plap.wav', 0