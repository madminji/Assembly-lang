; ####################################################
;       William F. Cravener 10/15/2008
; ####################################################
    
        .486
        .model flat,stdcall
        option casemap:none   ; case sensitive
    
; ####################################################
    
        include \masm32\include\windows.inc
        include \masm32\include\user32.inc
        include \masm32\include\kernel32.inc
        include \masm32\include\comctl32.inc
        include \masm32\include\winmm.inc
          include \masm32\include\gdi32.inc
            include \masm32\include\masm32rt.inc
          include msvcrt.inc
           includelib msvcrt.lib
        includelib \masm32\lib\user32.lib
        includelib \masm32\lib\kernel32.lib
        includelib \masm32\lib\comctl32.lib
        includelib \masm32\lib\winmm.lib
        includelib \masm32\lib\gdi32.lib

        includelib VolCtrl.lib
    
; ####################################################

        ID_LIST1 equ 101
        ID_LISTTRANS equ 102
        ID_BUTTON1 equ 201
        ID_BUTTON2 equ 202
        ID_BUTTON3 equ 203
        ID_REPEAT equ 204
        ID_SONGTITLE equ 903
        ID_SHOWPATH equ 1000
        ID_SLIDER1 equ 1001
        ID_TIMER  equ  1002
        IDT_TIMER equ  2000
         IDC_SLIDER1 equ 1003
         ID_LYRIC equ 910
         ID_LYRICneg equ 909
         ID_LYRICpos equ 911
         MIXER_ERROR equ 0FFFFFFFFh 
        SPEAKEROUTLINEID equ 0FFFF0000h

         Lyric STRUCT
       value DWORD 0
        
        LyricBuffer byte 128 DUP(0)

       Lyric ENDS
; --------------------------------------------------------
    
        Multimedia PROTO :DWORD,:DWORD,:DWORD,:DWORD
        PlayMp3File PROTO :DWORD,:DWORD

         GetMasterVolume PROTO
        SetMasterVolume PROTO :DWORD
        CloseMasterVolume PROTO
        ClearString PROTO:DWORD ,:DWORD
; --------------------------------------------------------
CR_BACKGROUND equ 00b2f5ffh
CR_FOREGROUND equ 00333399h

.data
        hIcon dd ?
        lyricLen DWORD 0
        lyricFileName BYTE 128 DUP(0)
        openmode BYTE "r",0
        sscanfFz db '[%2s:%2s.%2s]',0
        lymi db 10 dup(0)
        lyse db 10 dup(0)
        lymise     db 10 dup(0)
        zero db "0",0
        outputFz db "%s",0
        hfile    DWORD 0
        lyricCount = 200
        LyricArray Lyric lyricCount DUP(<>)
        outputbuffer byte 128 DUP(0)
        strbuffer2 byte 128 DUP(0)

debugText db "%x",0
lyricNotFoundText db "Lyric File Not Found",0
        hVolbar dd ?

        hTrackbar   dd ?

        hProgress      dd ?

        hLyric         dd ?
        hLyricneg         dd ?
        hLyricpos         dd ?
        hSongTitle     dd ?
        hRepeat        dd ?
        hInstance   dd ?

        hBgColor   HBRUSH    ?
        hFgColor   HBRUSH    ?
        hInColor   HBRUSH    ?
        hIn2Color  HBRUSH    ?
        hEdge      HPEN      ?

        Mp3DeviceID dd 0

        PlayFlag    dd 0

        LyricFlag   dd 0

        LyricFileFlag dd 0

        endFlag dd 0

        Mp3Files    db "*.mp3",125 dup (0)

        wavFiles    db "*.wav",125 dup(0)

        ClickADDR   db 128 dup(0)
        tempStr     db 128 dup(0)
        Mp3Device   db "MPEGVideo",0

        FileName    db 128 dup (0)

        dlgname     db "MAINSCREEN",0

        getPosText  db "status sound position",0

        getLenText db "status sound length",0

        progressText   db 128 dup(0)
        mi          word 0
        se          word 0
       
        sPos        db  100 dup(0)
        lPos        dword 0
        lPosw      word    0
        sPosLe     db  100 dup(0)
        lPosLe     dword 0
        lPosLew     word 0
        miLe        word 0
        seLe        word 0
        userPos     dword 0
        progressFormat db "%02d:%02d/%02d:%02d ",0
        openText db 128 dup(0)
        openFormat db "open %s alias sound",0
        playText db "play sound",0
        dragText db 128 dup(0)
        dragFormat db "play sound from %d",0
        repeatText db "play sound from 0",0
        pauseText db "pause sound",0
        closeText db "close sound",0 
        EmptyText db " ",0
         MixerError  db "Error occured accessing Mixer",0
        SongTitleFz db "Playing ",0
        SongTitleText db 50 DUP(0)

        MixerHandle    dd 0
        VolCtlIDMtr    dd 0

        mxc MIXERCONTROL <?>
        mxcd MIXERCONTROLDETAILS <?>
        mxcdVol MIXERCONTROLDETAILS_UNSIGNED <?>
        mxlc MIXERLINECONTROLS <?>

.data?
        icex INITCOMMONCONTROLSEX <> ;structure for Controls
    
; ###############################################################
    
.code
    
start:
    
        invoke GetModuleHandle,NULL
        mov hInstance,eax
        mov hIcon, FUNC(LoadIcon,hInstance,500)
        mov icex.dwSize,sizeof INITCOMMONCONTROLSEX
        invoke InitCommonControlsEx,ADDR icex
    INVOKE CreateSolidBrush, CR_BACKGROUND
mov hBgColor, eax
INVOKE CreateSolidBrush, CR_FOREGROUND
mov hFgColor, eax

        ; ---------------------------------------------
        ; Call the dialog box stored in resource file
        ; ---------------------------------------------
        invoke DialogBoxParam,hInstance,ADDR dlgname,0,ADDR Multimedia,0
          mov icex.dwSize,sizeof INITCOMMONCONTROLSEX
        mov icex.dwICC,0FFFFh
        invoke InitCommonControlsEx,ADDR icex
        invoke ExitProcess,eax
    
; ###############################################################
    
Multimedia proc hWin:DWORD,uMsg:DWORD,aParam:DWORD,bParam:DWORD
 
        .if uMsg == WM_CTLCOLORDLG
             mov eax, hBgColor
             ret
        .elseif uMsg == WM_CTLCOLORSTATIC
             invoke GetDlgCtrlID, bParam

        .elseif uMsg == WM_INITDIALOG
                    invoke SendMessage,hWin,WM_SETICON,1,
                         FUNC(LoadIcon,hInstance,500)
                    invoke DlgDirList,hWin,ADDR Mp3Files ,ID_LIST1,ID_SHOWPATH,DDL_DIRECTORY or DDL_DRIVES
                   
                    invoke SendDlgItemMessage,hWin,ID_LIST1,LB_ADDFILE,0,ADDR wavFiles
                  
                    invoke SendDlgItemMessage,hWin,ID_LIST1,LB_SETCURSEL,0,0
                    invoke SendDlgItemMessage,hWin,ID_LIST1,LB_GETTEXT,eax,ADDR FileName
                    invoke SetTimer,hWin,IDT_TIMER,50,NULL
                  
                    invoke GetDlgItem,hWin,ID_TIMER
                     
                    mov hProgress,eax

                     invoke GetDlgItem,hWin,ID_LYRIC  
                    mov hLyric,eax
                     invoke GetDlgItem,hWin,ID_LYRICneg  
                    mov hLyricneg,eax
                     invoke GetDlgItem,hWin,ID_LYRICpos  
                    mov hLyricpos,eax
                     invoke GetDlgItem,hWin,ID_SONGTITLE
                    mov hSongTitle,eax
                     invoke GetDlgItem,hWin,ID_REPEAT
                    mov hRepeat,eax

                     invoke GetDlgItem,hWin,ID_SLIDER1
                    mov hTrackbar,eax

                    invoke GetDlgItem,hWin,IDC_SLIDER1
                    mov hVolbar,eax
                    invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_SETRANGEMIN,FALSE,0
                    invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_SETRANGEMAX,FALSE,65535
                    invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_SETLINESIZE,FALSE,65
                   

                    invoke GetMasterVolume

                    .if eax == MIXER_ERROR
                        invoke MessageBox,0,ADDR MixerError,0,MB_OK
                        invoke SendMessage,hWin,WM_CLOSE,0,0
                    .else
                        invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_SETPOS,TRUE,eax
                    .endif
                    invoke SetFocus,hWin
       .elseif uMsg ==WM_CREATE
              
       .elseif uMsg == WM_COMMAND
                        mov eax,aParam
                        .if eax == ID_BUTTON1
                            
                            ;--------------------
                            ; Play button pressed
                            ;--------------------
                            .if PlayFlag == 0
                                mov PlayFlag,1  
                            .elseif PlayFlag == 1
                                invoke mciSendString,ADDR closeText,NULL,0,0
                               ; mov PlayFlag,0
                            .endif

                                invoke SendDlgItemMessage,hWin,ID_LIST1,LB_GETCURSEL,0,0
                                
                                invoke SendDlgItemMessage,hWin,ID_LIST1,LB_GETTEXT,eax,ADDR FileName
                                invoke PlayMp3File,hWin,ADDR FileName
                           

                        .elseif eax == ID_BUTTON2
                                ;-------------------------------
                                ; Pause music
                                ;-------------------------------
                                invoke mciSendString,ADDR pauseText,NULL,0,0
                                mov PlayFlag,0

                        .elseif eax == ID_BUTTON3
                                ;------------------------
                                ; Close player dialog box
                                ;------------------------
                                invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
                        .endif

                        and eax,0FFFFh  
                        .if eax == ID_LIST1
                            mov eax,aParam
                            shr eax,16
                            .if eax == LBN_DBLCLK
                            ;-------------------------------------
                            ; We double clicked on a list box item
                            ;-------------------------------------
                                invoke DlgDirSelectEx,hWin,ADDR ClickADDR,128,ID_LIST1
                                invoke SendDlgItemMessage,hWin,ID_LIST1,LB_GETCURSEL,0,0
                                invoke SendDlgItemMessage,hWin,ID_LIST1,LB_GETTEXTLEN,eax,0
                               
                                cmp eax,5
                                jl skipc
                                 
                                mov esi,offset ClickADDR
                                mov bl,[esi+eax-4]
                             
                                cmp bl,46
                                je skip
                                skipc:
                                invoke crt_strcpy,ADDR tempStr,ADDR ClickADDR
                                invoke crt_strcat,ADDR tempStr,ADDR Mp3Files
                               
                                invoke DlgDirList,hWin,ADDR tempStr,ID_LIST1,ID_SHOWPATH,DDL_DIRECTORY or DDL_DRIVES
                               
                                invoke SendDlgItemMessage,hWin,ID_LIST1,LB_ADDFILE,0,ADDR wavFiles
                                skip:
                               
                                invoke SendDlgItemMessage,hWin,ID_LIST1,LB_SETCURSEL,0,0
                            .endif 
                        .endif
   
        .elseif uMsg == WM_CLOSE
                        invoke EndDialog,hWin,NULL
        .elseif uMsg == WM_HSCROLL
       
                mov eax,bParam
                .if eax ==hTrackbar
                    mov LyricFlag,1
                 invoke SendMessage,hTrackbar, TBM_GETPOS, 0, 0     
                     mov userPos,eax
                     mov bx,1000
                     mul bx
                     shl edx,16
                     mov dx,ax
                 invoke crt_sprintf,ADDR dragText,ADDR dragFormat,edx
                 invoke mciSendString,ADDR dragText, NULL, 0, NULL
                 .if PlayFlag ==0
                 
                 invoke mciSendString,ADDR pauseText,NULL,0,NULL
                 .endif
                 
               .elseif eax == hVolbar
                            mov eax,aParam
                            and eax,0FFFFh  
                        .if eax == TB_THUMBTRACK or TB_THUMBPOSITION
                            mov eax,aParam
                            shr eax,16
                            ;-------------------------------- 
                            ;Set the new volume control value
                            ;-------------------------------- 
                            invoke SetMasterVolume,eax
                 
                    .elseif eax == TB_LINEUP      
                            invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_GETPOS,0,0
                            ;-------------------------------- 
                            ;Set the new volume control value
                            ;-------------------------------- 
                            invoke SetMasterVolume,eax
                 
                    .elseif eax == TB_LINEDOWN
                            invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_GETPOS,0,0
                            ;-------------------------------- 
                            ;Set the new volume control value
                            ;-------------------------------- 
                            invoke SetMasterVolume,eax
                 
                    .elseif eax == TB_PAGEUP
                            invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_GETPOS,0,0
                            ;-------------------------------- 
                            ;Set the new volume control value
                            ;-------------------------------- 
                            invoke SetMasterVolume,eax
                 
                    .elseif eax == TB_PAGEDOWN
                            invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_GETPOS,0,0
                            ;-------------------------------- 
                            ;Set the new volume control value
                            ;-------------------------------- 
                            invoke SetMasterVolume,eax

                    .elseif eax == TB_TOP
                            invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_GETPOS,0,0
                            ;-------------------------------- 
                            ;Set the new volume control value
                            ;-------------------------------- 
                            invoke SetMasterVolume,eax

                    .elseif eax == TB_BOTTOM
                            invoke SendDlgItemMessage,hWin,IDC_SLIDER1,TBM_GETPOS,0,0
                            ;-------------------------------- 
                            ;Set the new volume control value
                            ;-------------------------------- 
                            invoke SetMasterVolume,eax
                    .endif


                 .endif

        .elseif uMsg ==WM_TIMER
       
        invoke mciSendString, ADDR getPosText,ADDR sPos,100,0
       
        invoke crt_atoi,ADDR sPos
        
        mov lPos,eax
        .if eax >=lPosLe
        push eax
        mov eax,1
        mov endFlag,eax
        pop eax
        .endif
        mov edx,eax
        shr edx,16
        mov eax,lPos
        mov bx,1000
        div bx
        mov lPosw,ax
        mov dx,0
        mov bx,60
        div bx
        mov mi,ax
        mov se,dx
        mov ax,lPosLew
        shl eax,16
        mov ax,0
        invoke SendMessage,hTrackbar,TBM_SETRANGE,TRUE,eax
        invoke SendMessage,hTrackbar,TBM_SETPOS, TRUE, lPosw
    
         invoke crt_sprintf,ADDR progressText,ADDR progressFormat,mi,se,miLe,seLe
       invoke SetWindowText,hProgress,ADDR progressText

        
        ;=========================================Repeatsong======================
        .if endFlag ==1
        invoke IsDlgButtonChecked,hWin,ID_REPEAT
        .if eax == BST_CHECKED
        invoke mciSendString,ADDR repeatText,NULL,0,0
         mov LyricFlag,1

        mov eax,0
        mov endFlag,eax
        .endif
        .endif
       ;==============================================lyrics=========================================
       .if LyricFlag ==1&& LyricFileFlag ==1
       invoke mciSendString, ADDR getPosText,ADDR sPos,100,0
        invoke crt_atoi,ADDR sPos
       mov edi,0
       searchCur:
       cmp (Lyric PTR LyricArray[edi]).value,eax
       jg findLyric
       add edi,TYPE Lyric
       .if edi>=lyricLen
       mov edi,lyricLen
       jmp findLyric
       .endif
       jmp searchCur
       findLyric:
       sub edi,TYPE Lyric
        invoke SetWindowText,hLyricneg,ADDR (Lyric PTR LyricArray[edi]).LyricBuffer
        add edi,TYPE Lyric
       invoke SetWindowText,hLyric,ADDR (Lyric PTR LyricArray[edi]).LyricBuffer
       add edi,TYPE Lyric
       mov eax,(Lyric PTR LyricArray[edi]).value
       .if eax !=0
        invoke SetWindowText,hLyricpos,ADDR (Lyric PTR LyricArray[edi]).LyricBuffer
        .else
       
         invoke SetWindowText,hLyricpos,ADDR EmptyText
        mov LyricFlag,0
        .endif
       .endif
        .elseif uMsg == MM_MCINOTIFY
                        ;-----------------------------------------------------
                        ; Sent when media play completes and closes mp3 device
                        ;-----------------------------------------------------
                        invoke mciSendCommand,Mp3DeviceID,MCI_CLOSE,0,0
                        mov PlayFlag,0







    
        .endif
    
        xor eax,eax
        ret
    
Multimedia endp
    ; ###############################################################

; ###############################################################

PlayMp3File proc hWin:DWORD,NameOfFile:DWORD
LOCAL convertTemp:DWORD
     invoke crt_sprintf,ADDR openText,ADDR openFormat,NameOfFile
     invoke mciSendString,ADDR openText,NULL,0,0
     invoke mciSendString,ADDR playText,NULL,0,0
     
        invoke mciSendString,ADDR getLenText,ADDR sPosLe,100,0

        invoke crt_atoi,ADDR sPosLe
        mov lPosLe,eax
        mov edx,eax
        shr edx,16
        mov eax,lPosLe
        mov bx,1000
        div bx
        mov lPosLew,ax
        mov dx,0
        mov bx,60
        div bx
        mov miLe,ax
        mov seLe,dx
        invoke crt_sprintf,ADDR progressText,ADDR progressFormat,mi,se,miLe,seLe
       invoke SetWindowText,hProgress,ADDR progressText
       invoke crt_strcpy,ADDR SongTitleText,ADDR SongTitleFz
        invoke crt_strcat,ADDR SongTitleText,NameOfFile
       invoke SetWindowText,hSongTitle,ADDR  SongTitleText
            ;==============================Search lyric file=========================
        invoke crt_strcpy,ADDR  lyricFileName,NameOfFile
        invoke crt_strlen,NameOfFile
        mov edi,eax

        mov lyricFileName[edi-1],'t'
        mov lyricFileName[edi-2],'x'
        mov lyricFileName[edi-3],'t'
        invoke crt_fopen,ADDR  lyricFileName,ADDR openmode
        mov hfile,eax
        .if eax ==0
            invoke SetWindowText,hLyric,ADDR lyricNotFoundText
            invoke SetWindowText,hLyricneg,ADDR EmptyText
            invoke SetWindowText,hLyricpos,ADDR EmptyText
            mov LyricFileFlag,0
            jmp qui
        .endif

;======================================INIT LYRIC BUFFER===================================
        mov edi,0
        mov LyricFileFlag,1
        mov LyricFlag,1
        mov lyricLen,0
        read:
        
        invoke crt_fgets,ADDR strbuffer2,128,hfile
        .if eax==0

        jmp qui
       .endif
        invoke crt_sscanf,ADDR strbuffer2,ADDR sscanfFz,ADDR lymi,ADDR lyse,ADDR lymise
       
       invoke crt_strcat,ADDR lyse,ADDR lymise
       invoke crt_strcat,ADDR lyse,ADDR zero
       invoke crt_atoi,ADDR lyse
       push eax
       invoke crt_atoi,ADDR lymi
       mov ecx,eax
       pop eax
       keepadd:
       cmp ecx,0
       je quitadd
       add eax,60000
       dec ecx
       jmp keepadd
       quitadd:
        mov (Lyric PTR LyricArray[edi]).value,eax
        
        mov eax,offset strbuffer2
        add eax,10
        invoke crt_strcpy,ADDR (Lyric PTR LyricArray[edi]).LyricBuffer,eax
       
        add edi,TYPE Lyric
        mov lyricLen,edi
        jmp read
        qui:


            ret  
PlayMp3File endp


GetMasterVolume proc

        invoke mixerOpen,ADDR MixerHandle,0,0,0,0
        .if eax == MMSYSERR_NOERROR 
            mov mxlc.cbStruct,SIZEOF mxlc
            mov mxlc.dwLineID,SPEAKEROUTLINEID
            mov mxlc.dwControlType,MIXERCONTROL_CONTROLTYPE_VOLUME
            mov mxlc.cControls,1
            mov mxlc.cbmxctrl,SIZEOF mxc
            mov mxlc.pamxctrl,OFFSET mxc
            invoke mixerGetLineControls,MixerHandle,ADDR mxlc,MIXER_GETLINECONTROLSF_ONEBYTYPE
            mov eax,mxc.dwControlID
            mov VolCtlIDMtr,eax
            mov mxcdVol.dwValue,1
            mov mxcd.cbStruct,SIZEOF mxcd
            mov eax,VolCtlIDMtr  
            mov mxcd.dwControlID,eax
            mov mxcd.cChannels,1
            mov mxcd.cMultipleItems,0
            mov mxcd.cbDetails,SIZEOF mxcdVol
            mov mxcd.paDetails,OFFSET mxcdVol
            invoke mixerGetControlDetails,MixerHandle,ADDR mxcd,MIXER_GETCONTROLDETAILSF_VALUE
            mov eax,mxcdVol[0].dwValue
        .else
            mov eax,MIXER_ERROR
        .endif
        ret

GetMasterVolume endp
    
; ###############################################################

SetMasterVolume proc VolValue:DWORD
        
        mov eax,VolValue
     
        mov mxcdVol[0].dwValue,eax
        mov mxcd.cbStruct,SIZEOF mxcd
        mov eax,VolCtlIDMtr
        mov mxcd.dwControlID,eax
        mov mxcd.cChannels,1
        mov mxcd.cMultipleItems,0
        mov mxcd.cbDetails,SIZEOF mxcdVol
        mov mxcd.paDetails,OFFSET mxcdVol
        invoke mixerSetControlDetails,MixerHandle,ADDR mxcd,MIXER_GETCONTROLDETAILSF_VALUE
        .if eax == MMSYSERR_NOERROR
            mov eax,0
        .else
            mov eax,MIXER_ERROR
        .endif            
        ret

SetMasterVolume endp
; ###############################################################


ClearString PROC   stringADDR :DWORD,stringLen:DWORD
push edx
push ecx
push eax

lea di,stringADDR
mov ecx,stringLen
xor ax,ax
rep stosw

pop eax
pop ecx
pop edx
ret
ClearString endp
end start
