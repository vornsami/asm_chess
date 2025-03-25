; ---------------------------------------------------------------------------
; FILE: boardDraw.inc
; DATE: 30.01.2025
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------

startX = 50
startY = 20
tileSize = 64
imgSize = 64
boardDrawSize = tileSize * 8 
infoSquareSize = 20

; ---------------------------------------------------------------------------

darkBrush           dq      0
darkBrushCol        dq      536387h
lightBrush          dq      0
lightBrushCol       dq      0D2D2DAh

selectedBrush       dq      0
selectedBrushCol    dq      0000E1h
secSelectedBrush    dq      0
secSelectedBrushCol dq      0FF1F61h


blackBrush          dq      0
blackBrushCol       dq      474747h
whiteBrush          dq      0
whiteBrushCol       dq      0FAFAFAh

; ---------------------------------------------------------------------------

hdcMem              dq      0
bmdrawX             dq      0
bmdrawY             dq      0

movesound           dq      0
