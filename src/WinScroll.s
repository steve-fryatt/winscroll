; Copyright 2002-2013, Stephen Fryatt (info@stevefryatt.org.uk)
;
; This file is part of WinScroll:
;
;   http://www.stevefryatt.org.uk/software/
;
; Licensed under the EUPL, Version 1.1 only (the "Licence");
; You may not use this work except in compliance with the
; Licence.
;
; You may obtain a copy of the Licence at:
;
;   http://joinup.ec.europa.eu/software/page/eupl
;
; Unless required by applicable law or agreed to in
; writing, software distributed under the Licence is
; distributed on an "AS IS" basis, WITHOUT WARRANTIES
; OR CONDITIONS OF ANY KIND, either express or implied.
;
; See the Licence for the specific language governing
; permissions and limitations under the Licence.

; WinScroll.s
;
; WinScroll Module Source
;
; 32 bit neutral

;version$="0.51"
;save_as$="^.WinScroll"

XOS_Byte				EQU	&020006
XOS_CallEvery				EQU	&02003C
XOS_Claim				EQU	&02001F
XOS_ConvertCardinal4			EQU	&0200D8
XOS_ConvertHex4				EQU	&0200D2
XOS_File				EQU	&020008
XOS_Module				EQU	&02001E
XOS_NewLine				EQU	&020003
XOS_PrettyPrint				EQU	&020044
XOS_ReadArgs				EQU	&020049
XOS_ReadUnsigned			EQU	&020021
XOS_ReadVarVal				EQU	&020023
XOS_Release				EQU	&020020
XOS_RemoveTickerEvent			EQU	&02003D
XOS_SpriteOp				EQU	&02002E
XOS_Write0				EQU	&020002
XOS_WriteC				EQU	&020000
XOS_WriteS				EQU	&020001
XFilter_DeRegisterPostFilter		EQU	&062643
XFilter_RegisterPostFilter		EQU	&062641
XTaskManager_EnumerateTasks		EQU	&062681
XTerritory_UpperCaseTable		EQU	&063058
XWimp_CloseDown				EQU	&0600DD
XWimp_GetCaretPosition			EQU	&0600D3
XWimp_GetWindowInfo			EQU	&0600CC
XWimp_Initialise			EQU	&0600C0
XWimp_Poll				EQU	&0600C7
XWimp_ReadSysInfo			EQU	&0600F2

OS_Exit					EQU	&000011
OS_GenerateError			EQU	&00002B

OS_Byte					EQU	&000006
OS_Claim				EQU	&00001F
OS_ReadArgs				EQU	&000049
OS_ReadMonotonicTime			EQU	&000042
OS_Release				EQU	&000020
OS_SpriteOp				EQU	&00002E
Wimp_CloseWindow			EQU	&0400C6
Wimp_CreateIcon				EQU	&0400C2
Wimp_CreateMenu				EQU	&0400D4
Wimp_CreateWindow			EQU	&0400C1
Wimp_GetPointerInfo			EQU	&0400CF
Wimp_GetWindowInfo			EQU	&0400CC
Wimp_GetWindowState			EQU	&0400CB
Wimp_OpenWindow				EQU	&0400C5
Wimp_PollIdle				EQU	&0400E1
Wimp_ReadSysInfo			EQU	&0400F2
Wimp_SendMessage			EQU	&0400E7
Wimp_SpriteOp				EQU	&0400E9

; ---------------------------------------------------------------------------------------------------------------------
; Set up the Module Workspace

WS_BlockSize		*	256
WS_TargetSize		*	&500

			^	0
WS_Flags		#	4
WS_IconDef		#	36
WS_SpriteName		#	12
WS_ScrollWindow		#	4
WS_ScrollX		#	4
WS_ScrollY		#	4
WS_ConfigureSpeed	#	4
WS_ConfigureButton	#	4
WS_ConfigureKey		#	4
WS_SpriteArea		#	4
WS_TaskHandle		#	4
WS_Quit			#	4
WS_WindowHandle		#	4
WS_Block		#	WS_BlockSize
WS_Stack		#	WS_TargetSize - @

WS_Size			*	@

; ---------------------------------------------------------------------------------------------------------------------
; Set up the Module Flags

Flag_StartReq		EQU	&001	; Request to start scrolling
Flag_HScrolling		EQU	&002	; Horizontal scrolling in progress
Flag_VScrolling		EQU	&004	; Vertical scrolling in progress
Flag_StopReq		EQU	&008	; Request to stop scrolling
Flag_SquareMode		EQU	&100	; Use square-mode scrolling


; ======================================================================================================================
; Module Header

	AREA	Module,CODE,READONLY
	ENTRY

ModuleHeader
	DCD	TaskCode			; Offset to task code
	DCD	InitCode			; Offset to initialisation code
	DCD	FinalCode			; Offset to finalisation code
	DCD	ServiceCode			; Offset to service-call handler
	DCD	TitleString			; Offset to title string
	DCD	HelpString			; Offset to help string
	DCD	CommandTable			; Offset to command table
	DCD	0				; SWI Chunk number
	DCD	0				; Offset to SWI handler code
	DCD	0				; Offset to SWI decoding table
	DCD	0				; Offset to SWI decoding code
	DCD	0				; MessageTrans file
	DCD	ModuleFlags			; Offset to module flags

; ======================================================================================================================

ModuleFlags
	DCD	1				; 32-bit compatible

; ======================================================================================================================

TitleString
	DCB	"WinScroll",0
	ALIGN

HelpString
	DCB	"Windows Scroll",9,$BuildVersion," (",$BuildDate,") ",169," Stephen Fryatt, 2002",0	;-",$BuildDate:RIGHT:4,0
	ALIGN

; ======================================================================================================================

CommandTable
	DCB	"Desktop_WinScroll",0
	ALIGN
	DCD	CommandDesktop
	DCD	&00000000
	DCD	0
	DCD	0

	DCB	"WinScrollConfigure",0
	ALIGN
	DCD	CommandConfigure
	DCD	&00060000
	DCD	CommandConfigureSyntax
	DCD	CommandConfigureHelp

	DCD	0

; ----------------------------------------------------------------------------------------------------------------------

CommandConfigureHelp
	DCB	"*"
	DCB	27
	DCB	0
	DCB	" "
	DCB	"configures the window scroll module or displays the current configuration."
	DCB	13

CommandConfigureSyntax
	DCB	27
	DCB	30
	DCB	"<-Button <button number>] [-Modifier <key number>]"
	DCB	13
	DCB	9
	DCB	"[-Speed <speed>] [-Linear|Square]"
	DCB	0

	ALIGN
; ----------------------------------------------------------------------------------------------------------------------

CommandDesktop
	STMFD	R13!,{R14}

	MOV	R2,R0
	ADR	R1,TitleString
	MOV	R0,#2
	SWI	XOS_Module

	LDMFD	R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

ConfigureString
	DCB	"button/K/E,modifier/K/E,speed/K/E,linear/S,square/S",0
	ALIGN

CommandConfigure
	STMFD	R13!,{R14}

	LDR	R12,[R12]

	TEQ	R1,#0
	BEQ	ConfigureShow

ConfigureSet
	SUB	R13,R13,#64				; Claim 64 bytes of space from the stack.

	MOV	R1,R0
	ADR	R0,ConfigureString
	MOV	R2,R13
	MOV	R3,#64
	SWI	OS_ReadArgs

ConfigureSetButton
	LDR	R0,[R2,#0]
	TEQ	R0,#0
	BEQ	ConfigureSetKey

	LDRB	R1,[R0]
	TEQ	R1,#0
	BNE	ConfigureSetKey

	LDR	R1,[R0,#1]
	STR	R1,[R12,#WS_ConfigureButton]

ConfigureSetKey
	LDR	R0,[R2,#4]
	TEQ	R0,#0
	BEQ	ConfigureSetSpeed

	LDRB	R1,[R0]
	TEQ	R1,#0
	BNE	ConfigureSetSpeed

	LDR	R1,[R0,#1]
	STR	R1,[R12,#WS_ConfigureKey]

ConfigureSetSpeed
	LDR	R0,[R2,#8]
	TEQ	R0,#0
	BEQ	ConfigureSetLinear

	LDRB	R1,[R0]
	TEQ	R1,#0
	BNE	ConfigureSetLinear

	LDR	R1,[R0,#1]
	STR	R1,[R12,#WS_ConfigureSpeed]

ConfigureSetLinear
	LDR	R0,[R2,#12]
	TEQ	R0,#0
	BEQ	ConfigureSetSquare

	LDR	R0,[R12,#WS_Flags]
	BIC	R0,R0,#Flag_SquareMode
	STR	R0,[R12,#WS_Flags]

ConfigureSetSquare
	LDR	R0,[R2,#16]
	TEQ	R0,#0
	BEQ	ConfigureSetExit

	LDR	R0,[R12,#WS_Flags]
	ORR	R0,R0,#Flag_SquareMode
	STR	R0,[R12,#WS_Flags]

ConfigureSetExit
	ADD	R13,R13,#64

	LDMFD	R13!,{PC}


ConfigureShow
	SWI	XOS_WriteS
	DCB	"Mouse button: ",0
	ALIGN
	LDR	R0,[R12,#WS_ConfigureButton]
	BL	PrintValueInR0
	SWI	XOS_NewLine

	SWI	XOS_WriteS
	DCB	"Modifier key: ",0
	ALIGN
	LDR	R0,[R12,#WS_ConfigureKey]
	BL	PrintValueInR0
	SWI	XOS_NewLine

	SWI	XOS_WriteS
	DCB	"Scroll speed: ",0
	ALIGN
	LDR	R0,[R12,#WS_ConfigureSpeed]
	BL	PrintValueInR0
	SWI	XOS_NewLine

	SWI	XOS_WriteS
	DCB	"Speed control mode: ",0
	ALIGN
	LDR	R0,[R12,#WS_Flags]
	TST	R0,#Flag_SquareMode
	ADREQ	R0,ConfigureControlLinear
	ADRNE	R0,ConfigureControlSquare
	SWI	XOS_Write0
	SWI	XOS_NewLine

	LDMFD	R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

ConfigureControlLinear
	DCB	"Linear",0
ConfigureControlSquare
	DCB	"Square",0
	ALIGN

; ----------------------------------------------------------------------------------------------------------------------

PrintValueInR0
	STMFD	R13!,{R1-R2,R14}
	SUB	R13,R13,#16
	MOV	R1,R13
	MOV	R2,#16					; the size of this to the OS to
	SWI	XOS_ConvertCardinal4			; make it into a number...
	SWI	XOS_Write0				; ...ready to print on the screen.
	ADD	R13,R13,#16
	LDMFD	R13!,{R1-R2,PC}

; ======================================================================================================================

InitCode
	STMFD	R13!,{R14}

; Claim workspace for ourselves and store the pointer in our private workspace.
; This space is used for everything; both the module 'back-end' and the WIMP task.

	MOV	R0,#6
	MOV	R3,#WS_Size
	SWI	XOS_Module
	BVS	InitExit
	STR	R2,[R12]
	MOV	R12,R2

; Initialise the workspace that was just claimed.

	MOV	R0,#0
	STR	R0,[R12,#WS_TaskHandle]			; Zero the task handle.
	STR	R0,[R12,#WS_Flags]			; Zero the flag-word.
	STR	R0,[R12,#WS_SpriteArea]		; Zero the sprite area pointer (only set if claimed from RMA).

	MOV	R0,#2
	STR	R0,[R12,#WS_ConfigureSpeed]

	MOV	R0,#2
	STR	R0,[R12,#WS_ConfigureButton]

	MOV	R0,#1
	STR	R0,[R12,#WS_ConfigureKey]

; Initilise the filter

	ADR	R0,TitleString
	ADR	R1,FilterCode
	MOV	R2,R12
	MOV	R3,#0
	LDR	R4,FilterMask
	SWI	XFilter_RegisterPostFilter

; Claim EventV

	MOV	R0,#&10
	ADR	R1,EventVCode
	MOV	R2,R12
	SWI	OS_Claim

; Enable EventV

	MOV	R0,#14
	MOV	R1,#11
	SWI	OS_Byte

InitExit
          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

FinalCode
	STMFD	R13!,{R14}
	LDR	R12,[R12]

; Disable EventV

	MOV	R0,#13
	MOV	R1,#11
	SWI	OS_Byte

; De-register from EventV

	MOV	R0,#&10
	ADR	R1,EventVCode
	MOV	R2,R12
	SWI	OS_Release

; De-register the filter

	ADR	R0,TitleString
	ADR	R1,FilterCode
	MOV	R2,R12
	MOV	R3,#0
	LDR	R4,FilterMask
	SWI	XFilter_DeRegisterPostFilter

; Kill the wimp task if it's running.

	LDR	R0,[R12,#WS_TaskHandle]
	CMP	R0,#0
	BLE	FinalFreeWS

	LDR	R1,Task
	SWI	XWimp_CloseDown
	MOV	R1,#0
	STR	R1,[R12,#WS_TaskHandle]

; Free the sprite area if necessary

	LDR	R2,[R12,#WS_SpriteArea]
	TEQ	R2,#0
	BEQ	FinalFreeWS
	MOV	R0,#7
	SWI	XOS_Module

FinalFreeWS
	TEQ	R10,#1
	TEQEQ	R12,#0
	BEQ	FinalExit
	MOV	R0,#7
	MOV	R2,R12
	SWI	XOS_Module

FinalExit
	LDMFD	R13!,{PC}

; ======================================================================================================================

ServiceCode
	TEQ	R1,#&27
	TEQNE	R1,#&49
	TEQNE	R1,#&4A

	MOVNE	PC,R14

	STMFD	R13!,{R14}
	LDR	R12,[R12]

ServiceReset
	TEQ	R1,#&27
	BNE	ServiceStartWimp

	MOV	R14,#0
	STR	R14,[R12,#WS_TaskHandle]
	LDMFD	R13!,{PC}

ServiceStartWimp
	TEQ	R1,#46
	BNE	ServiceStartedWimp

	LDR	R14,[R12,#WS_TaskHandle]
	TEQ	R14,#0
	MVNEQ	R14,#-1					; Think this ought to be MOVEQ R14,#-1 ?
	STREQ	R14,[R12,#WS_TaskHandle]
	ADREQ	R0,CommandDesktop
	MOVEQ	R1,#0
	LDMFD	R13!,{PC}

ServiceStartedWimp
	LDR	R14,[R12,#WS_TaskHandle]
	CMN	R14,#1
	MOVEQ	R14,#0
	STREQ	R14,[R12,#WS_TaskHandle]
	LDMFD	R13!,{PC}

; ======================================================================================================================

FilterMask
	DCD	&00003FBF

; ======================================================================================================================

FilterCode
	STMFD	R13!,{R2,R3,R14}

	TEQ	R0,#6
	LDMNEFD	R13!,{R2,R3,PC}

; Test if the mouse button was Menu; if not, just quit now

	LDR	R2,[R1,#8]
	LDR	R3,[R12,#WS_ConfigureButton]
	TST	R2,R3
	LDMEQFD	R13!,{R2,R3,PC}

; Test to see if Ctrl is held down.  If not, again just quit.

	STMFD	R13!,{R0,R1}
	MOV	R0,#121
	LDR	R1,[R12,#WS_ConfigureKey]
	EOR	R1,R1,#&80
	SWI	XOS_Byte
	TEQ	R1,#&FF
	LDMFD	R13!,{R0,R1}
	LDMNEFD	R13!,{R2,R3,PC}

; Set the flag to show that a scroll should start, then set up the various pieces of data and mask out the event.

	LDR	R2,[R12,#WS_Flags]
	ORR	R2,R2,#Flag_StartReq
	STR	R2,[R12,#WS_Flags]

	LDR	R2,[R1,#12]
	STR	R2,[R12,#WS_ScrollWindow]

	LDR	R2,[R1,#0]
	STR	R2,[R12,#WS_ScrollX]

	LDR	R2,[R1,#4]
	STR	R2,[R12,#WS_ScrollY]

	MOV	R0,#-1

	LDMFD	R13!,{R2,R3,PC}

; ======================================================================================================================

EventVCode

; Check that it is a key transition event and exit if not.

	TEQ	R0,#11
	MOVNE	PC,R14

; Check the key transition; if it's not a key-down, exit.

	TEQ	R1,#1
	MOVNE	PC,R14

; Test the keys to see if it's a mouse button.

	TEQ	R2,#&70
	TEQNE	R2,#&71
	TEQNE	R2,#&72
	MOVNE	PC,R14

; Lodge an end-scroll request in the flag word.

	LDR	R0,[R12,#WS_Flags]
	TST	R0,#Flag_HScrolling
	TSTEQ	R0,#Flag_VScrolling
	ORRNE	R0,R0,#Flag_StopReq
	STRNE	R0,[R12,#WS_Flags]
	MOVNE	R0,#11

	MOV	PC,R14

; ======================================================================================================================

Task
	DCB	"TASK"

WimpVersion
	DCD	310

WimpMessages
	DCD	0		; Message_Quit (null list, so all messages are accepted...)

PollMask
	DCD	&3830

TaskName
	DCB	"Windows Scroll",0

MisusedStartCommand
	;DCD	0								; \TODO -- Fix once complete.
	DCB	0, 0, 0, 0, "Use *Desktop to start WinScroll.",0		; \TODO -- Fix once complete.
	ALIGN

HiResSuffix
	DCD	&00003232 ; "22"

SpriteVariable
	DCB	"WinScroll$Sprites",0
	ALIGN

SpriteFiletype
	DCD	&FF9

WindowDefinition
	DCD	100		; Visible area min x
	DCD	100		; Visible area min y
	DCD	200		; Visible area max x
	DCD	200		; Visible area max y
	DCD	0		; X scroll offset
	DCD	0 		; Y scroll offset
	DCD	-1		; Handle to open window behind
	DCD	&80000810	; Window flags
	DCD	&01070207
	DCD	&000C0207
	DCD	0		; Work area min x
	DCD	-100		; Work area min y
	DCD	100		; Work area max x
	DCD	0		; Work area max y
	DCD	&2700003D	; Title bar icon flags
	DCD	3		; Work area flags
	DCD	1		; Sprite area pointer
	DCW	0		; Minimum width of window
	DCW	0		; Minimum height of window
	DCD	0		; Window title
	DCD	0		; Window title
	DCD	0		; Window title
	DCD	0		; Number of icons

IconDefinition
	DCD	4		; Icon bounding box
	DCD	-96
	DCD	96
	DCD	-4
	DCD	&1700311A	; Icon flags
	ALIGN

; ======================================================================================================================

TaskCode
	LDR	R12,[R12]
	ADD	R13,R12,#WS_Size	;+4		; Set the stack up.	; \TODO -- Fix once complete.
	ADD	R13,R13,#4							; \TODO -- Fix once complete.

; Check that we aren't in the desktop.

	SWI	XWimp_ReadSysInfo
	TEQ	R0,#0
	ADREQ	R0,MisusedStartCommand
	SWIEQ	OS_GenerateError

; Kill any previous version of our task which may be running.

	LDR	R0,[R12,#WS_TaskHandle]
	TEQ	R0,#0
	LDRGT	R1,Task
	SWIGT	XWimp_CloseDown
	MOV	R0,#0
	STRGT	R0,[R12,#WS_TaskHandle]

; Set the Quit flag to zero

	STR	R0,[R12,#WS_Quit]

; (Re) initialise the module as a Wimp task.

	LDR	R0,WimpVersion
	LDR	R1,Task
	ADR	R2,TaskName
	ADR	R3,WimpMessages
	SWI	XWimp_Initialise
	SWIVS	OS_Exit
	STR	R1,[R12,#WS_TaskHandle]

; Create the window.

	ADR	R1,WindowDefinition
	STR	R0,[R1,#108]
	SWI	Wimp_CreateWindow
	STR	R0,[R12,#WS_WindowHandle]

; Copy the icon definition into the workspace, filling in the bits we know.

	ADD	R1,R12,#WS_IconDef
	STR	R0,[R1,#0]			; Store the window handle

	ADR	R2,IconDefinition		; Copy the data from the icon def block into a writable area
	LDR	R0,[R2,#0]			; in the workspace.
	STR	R0,[R1,#4]
	LDR	R0,[R2,#4]
	STR	R0,[R1,#8]
	LDR	R0,[R2,#8]
	STR	R0,[R1,#12]
	LDR	R0,[R2,#12]
	STR	R0,[R1,#16]
	LDR	R0,[R2,#16]
	STR	R0,[R1,#20]

	ADD	R0,R12,#WS_SpriteName		; Point the sprite name to the workspace.
	STR	R0,[R1,#24]

; Load a sprite file or choose a suitable default internal area.

	ADR	R0,SpriteVariable		; First, identify if the system variable <WinScroll$Sprites> is set.
	ADD	R1,R12,#WS_Block			; If not, we must use the default sprite areas from inside the module.
	MOV	R2,#255
	MOV	R3,#0
	MOV	R4,#0
	SWI	XOS_ReadVarVal
	BVS	InitSpritesInternal

InitSpritesExternal
	MOV	R0,#2
	SWI	Wimp_ReadSysInfo

	ADD	R2,R2,R1			; R2 points to the character after the end of the filename.  Copy it
	MOV	R7,R2				; to R7 so that after the '22' suffix is added we can get back.

InitSpritesCopySuffix
	LDRB	R3,[R0],#1			; Put the sprites suffix on to the name.
	STRB	R3,[R2],#1
	CMP	R3,#32
	BGE	InitSpritesCopySuffix

	MOV	R0,#23				; Try to find the file using the suffix name...
	SWI	XOS_File
	TEQ	R0,#1
	BEQ	InitSpritesLoadFile

	MOV	R0,#0				; ...and, if that fails, try without the suffix.
	STRB	R0,[R7]
	MOV	R0,#23
	SWI	XOS_File
	TEQ	R0,#1
	BNE	InitSpritesInternal

InitSpritesLoadFile
	LDR	R0,SpriteFiletype		; Check that the file found is a sprite file.  If not, use the
	TEQ	R0,R6				; internal sprite areas.
	BNE	InitSpritesInternal

	MOV	R0,#6				; Claim memory from the RMA for the area.  If it fails, use the
	ADD	R3,R4,#4			; internal sprites; otherwise store the pointer so we know to
	SWI	XOS_Module			; free the memory afterwards.
	BVS	InitSpritesInternal
	STR	R2,[R12,#WS_SpriteArea]

	STR	R3,[R2]				; Initialise the area.
	MOV	R3,#16
	STR	R3,[R2,#8]

	EOR	R1,R1,R2			; SWAP R1,R2
	EOR	R2,R1,R2			; Load the sprite file into memory.
	EOR	R1,R1,R2
	MOV	R0,#&0A
	ORR	R0,R0,#&100
	SWI	XOS_SpriteOp

	BVS	InitSpritesInternal

	MOV	R0,R1

	B	InitSpritesNameBuffer

InitSpritesInternal
	MOV	R0,#2				; Determine if we need hi or lo res sprites and set the area pointer
	SWI	Wimp_ReadSysInfo		; appropriately.
	LDR	R0,[R0]
	BIC	R0,R0,#&FF000000
	LDR	R2,HiResSuffix
	TEQ	R0,R2
	ADREQL	R0,sprite_area_hi
	ADRNEL	R0,sprite_area_lo

InitSpritesNameBuffer
	ADD	R1,R12,#WS_IconDef		; Store the sprite area pointer, from the last block of code,
	STR	R0,[R1,#28]			; into the icon definition.

	MOV	R0,#12				; Set the length of the sprite name buffer.
	STR	R0,[R1,#32]

	SWI	Wimp_CreateIcon

; Set R1 up to be the block pointer.

	ADD	R1,R12,#WS_Block

; ----------------------------------------------------------------------------------------------------------------------

PollLoop
	SWI	OS_ReadMonotonicTime
	ADD	R2,R0,#15
	LDR	R0,PollMask
	SWI	Wimp_PollIdle

PollEventNull
	TEQ	R0,#0
	BNE	PollEventOpenWindow

	LDR	R2,[R12,#WS_Flags]

PollNullStartScroll
	TST	R2,#Flag_StartReq
	BEQ	PollNullEndScroll

	BL	StartScroll
	B	PollLoopEnd

PollNullEndScroll
	TST	R2,#Flag_StopReq
	BEQ	PollNullDoScroll

	BL	EndScroll
	B	PollLoopEnd

PollNullDoScroll
	TST	R2,#(Flag_HScrolling :OR: Flag_VScrolling)
	BEQ	PollLoopEnd

	BL	DoScroll
	B	PollLoopEnd

PollEventOpenWindow
	TEQ	R0,#2
	BNE	PollEventCloseWindow

	SWI	Wimp_OpenWindow
	B	PollLoopEnd

PollEventCloseWindow
	TEQ	R0,#3
	BNE	PollEventMouseClick

	SWI	Wimp_CloseWindow
	B	PollLoopEnd

PollEventMouseClick
	TEQ	R0,#6
	BNE	PollEventWimpMessage

	LDR	R0,[R12,#WS_Flags]
	ORR	R0,R0,#Flag_StopReq
	STR	R0,[R12,#WS_Flags]
;	BL	EndScroll
	B	PollLoopEnd

PollEventWimpMessage
	TEQ	R0,#17
	TEQNE	R0,#18
	BNE	PollLoopEnd

	LDR	R0,[R1,#16]

PollMessageQuit
	TEQ	R0,#0
	MOVEQ	R0,#1
	STREQ	R0,[R12,#WS_Quit]

PollLoopEnd
	LDR	R0,[R12,#WS_Quit]
	TEQ	R0,#0
	BEQ	PollLoop

; ----------------------------------------------------------------------------------------------------------------------

CloseDown
	LDR	R0,[R12,#WS_TaskHandle]
	LDR	R1,Task
	SWI	XWimp_CloseDown

; Set the task handle to zero and die.

	MOV	R0,#0
	STR	R0,[R12,#WS_TaskHandle]

	SWI	OS_Exit

; ======================================================================================================================

SpriteNameHorizontal
	DCB	"ws_horiz",0

SpriteNameVertical
	DCB	"ws_vert",0

SpriteNameBoth
	DCB	"ws_both",0

SpriteNamePtrDefault
	DCB	"ptr_default",0

SpriteNamePtrScroll
	DCB	"ptr_def",0
	ALIGN

; ======================================================================================================================

StartScroll
	STMFD	R13!,{R0-R7,R14}

; Clear the start-flag.

	LDR	R2,[R12,#WS_Flags]
	BIC	R2,R2,#Flag_StartReq
	STR	R2,[R12,#WS_Flags]

; Check for the presence of the scroll-bars

	LDR	R0,[R12,#WS_ScrollWindow]
	STR	R0,[R1,#0]
	ORR	R1,R1,#1
	SWI	Wimp_GetWindowInfo
	BIC	R1,R1,#1

	LDR	R2,[R1,#32]
	ADD	R1,R12,#WS_IconDef

StartScrollBoth
	TST	R2,#&10000000
	TSTNE	R2,#&40000000
	BEQ	StartScrollHoriz

	ADRL	R0,SpriteNameBoth
	BL	CopySpriteName

	LDR	R2,[R12,#WS_Flags]
	ORR	R2,R2,#(Flag_HScrolling :OR: Flag_VScrolling)
	STR	R2,[R12,#WS_Flags]

	B	StartCreate

StartScrollHoriz
	TST	R2,#&40000000
	BEQ	StartScrollVert

	ADRL	R0,SpriteNameHorizontal
	BL	CopySpriteName

	LDR	R2,[R12,#WS_Flags]
	ORR	R2,R2,#Flag_VScrolling
	STR	R2,[R12,#WS_Flags]

	B	StartCreate

StartScrollVert
	TST	R2,#&10000000
	BEQ	StartScrollNone

	ADRL	R0,SpriteNameVertical
	BL	CopySpriteName

	LDR	R2,[R12,#WS_Flags]
	ORR	R2,R2,#Flag_HScrolling
	STR	R2,[R12,#WS_Flags]

	B	StartCreate

StartScrollNone
	B	StartScrollExit				; Just return, having done nothing.

StartCreate
; Get the details about the window below the pointer.

	ADD	R1,R12,#WS_Block

	LDR	R0,[R12,#WS_WindowHandle]
	STR	R0,[R1,#0]
	SWI	Wimp_GetWindowState

; Set the window to be centred on the mouse-click.

	LDR	R2,[R12,#WS_ScrollX]
	SUB	R3,R2,#50
	STR	R3,[R1,#4]
	ADD	R3,R2,#50
	STR	R3,[R1,#12]
	LDR	R2,[R12,#WS_ScrollY]
	SUB	R3,R2,#50
	STR	R3,[R1,#8]
	ADD	R3,R2,#50
	STR	R3,[R1,#16]

	MOV	R0,#-1
	STR	R0,[R1,#28]
	SWI	Wimp_OpenWindow

; Set the mouse pointer.

	MOV	R0,#36
	ORR	R0,R0,#&100
	ADD	R1,R12,#WS_IconDef
	LDR	R1,[R1,#28]
	ADRL	R2,SpriteNamePtrScroll
	MOV	R3,#2_0100010
	MOV	R4,#6
	MOV	R5,#6
	MOV	R6,#0
	MOV	R7,#0					; No pixel translation table
	SWI	OS_SpriteOp


; Just for Toolbox apps, close the menu again...

	MOV	R1,#-1
	SWI	Wimp_CreateMenu

StartScrollExit
	LDMFD	R13!,{R0-R7,PC}

; ----------------------------------------------------------------------------------------------------------------------

; Perform scrolling on a Null event.

DoScroll
	STMFD	R13!,{R0-R5,R14}

	SWI	Wimp_GetPointerInfo

	LDR	R0,[R12,#WS_Flags]

; Initialise the scroll values.

	MOV	R2,#0
	MOV	R3,#0

DoScrollX
	TST	R0,#Flag_VScrolling
	BEQ	DoScrollY

	LDR	R4,[R1,#0]
	LDR	R5,[R12,#WS_ScrollX]
	BL	CalculateOffset
	MOV	R2,R3

DoScrollY
	TST	R0,#Flag_HScrolling
	BEQ	DoScrollAdd

	LDR	R4,[R1,#4]
	LDR	R5,[R12,#WS_ScrollY]
	BL	CalculateOffset

DoScrollAdd

	LDR	R0,[R12,#WS_ScrollWindow]
	STR	R0,[R1,#0]
	ORR	R1,R1,#1
	SWI	XWimp_GetWindowInfo
	BIC	R1,R1,#1
	BVC	DoScrollWindowOK

; An error occurred, so end the scroll right now.

	BL	EndScroll
	B	DoScrollExit

DoScrollWindowOK

; Add in the X scroll offset

	LDR	R0,[R1,#20]
	ADD	R0,R0,R2
	STR	R0,[R1,#20]

; Add in the Y scroll offset

	LDR	R0,[R1,#24]
	ADD	R0,R0,R3
	STR	R0,[R1,#24]

; Send a Window Open Event to the task.

	MOV	R0,#2
	LDR	R2,[R12,#WS_ScrollWindow]
	SWI	Wimp_SendMessage

; Re-open the arrow window on top, just to be safe.

	LDR	R0,[R12,#WS_WindowHandle]
	STR	R0,[R1,#0]
	SWI	Wimp_GetWindowState
	MOV	R0,#-1
	STR	R0,[R1,#28]
	SWI	Wimp_OpenWindow

DoScrollExit
	LDMFD	R13!,{R0-R5,PC}

; ----------------------------------------------------------------------------------------------------------------------

; Calculate window scroll offset based on mouse position (relative to scroll origin).
;
; => R0 = Flags
;    R4 = Mouse position
;    R5 = Origin position
;    R12 => Workspace

; <= R3 = Scroll offset

CalculateOffset
	STMFD	R13!,{R0-R2,R6,R14}

	SUB	R2,R4,R5

	TST	R0,#&100
	BEQ	CalculateLinearOffset

CalculateSquareOffset
	AND	R4,R2,#&80000000
	TEQ	R4,#&80000000
	BNE	CalculateDoSquare

	MOV	R5,#-1
	EOR	R2,R2,R5
	ADD	R2,R2,#1

CalculateDoSquare
	MUL	R0,R2,R2

	TEQ	R4,#&80000000
	BNE	CalculateOffsetContinue

	SUB	R0,R0,#1
	EOR	R0,R0,R5

	B	CalculateOffsetContinue

CalculateLinearOffset
	MOV	R0,R2

CalculateOffsetContinue
	LDR	R1,[R12,#WS_ConfigureSpeed]

	BL	Divide

	LDMFD	R13!,{R0-R2,R6,PC}

; ----------------------------------------------------------------------------------------------------------------------

; End a scroll operation.

EndScroll
	STMFD	R13!,{R0-R7,R14}

; Close the arrow window.

	LDR	R0,[R12,#WS_WindowHandle]
	STR	R0,[R1,#0]
	SWI	Wimp_CloseWindow

; Reset the mouse pointer.

	MOV	R0,#36
	ADRL	R2,SpriteNamePtrDefault
	MOV	R3,#2_0100001
	MOV	R4,#0
	MOV	R5,#0
	MOV	R6,#0
	MOV	R7,#0					; No pixel translation table
	SWI	Wimp_SpriteOp

; Clear out the scroll and end-scroll flags.

	LDR	R2,[R12,#WS_Flags]
	BIC	R2,R2,#(Flag_StopReq :OR: Flag_HScrolling :OR: Flag_VScrolling)
	STR	R2,[R12,#WS_Flags]

	LDMFD	R13!,{R0-R7,PC}

; ======================================================================================================================

; Copy the name of a sprite into the icon sprite name buffer.
;
; => R0 -> Sprite name
;    R1 -> Icon block

CopySpriteName
	STMFD	R13!,{R0,R2-R3,R14}

	LDR	R2,[R1,#24]

CopySpriteLoop
	LDRB	R3,[R0],#1
	STRB	R3,[R2],#1

	TEQ	R3,#0
	BNE	CopySpriteLoop

	LDMFD	R13!,{R0,R2-R3,PC}

; ======================================================================================================================

; Divide two numbers.
;
; => R0 = Dividend
;    R1 = Divisor
;
; <= R3 = Quotient
;   (R1 = Remainder)

Divide
	STMFD	R13!,{R0-R2,R4-R5,R14}

	MOV	R3,#1

	AND	R4,R0,#&80000000			; Get the sign bit and if negative, invert the number.
	TEQ	R4,#&80000000
	BNE	Div1

	MOV	R5,#-1
	EOR	R0,R0,R5
	ADD	R0,R0,#1

Div1
	CMP	R0,R1,ASL #1
	MOVGE	R1,R1,ASL #1
	MOVGE	R3,R3,ASL #1
	BGE	Div1
	MOV	R2,#0

Div2
	CMP	R0,R1
	SUBGE	R0,R0,R1
	ADDGE	R2,R2,R3
	MOV	R1,R1,ASR #1
	MOVS	R3,R3,ASR #1
	BNE	Div2

	TEQ	R4,#&80000000				; Make the result negative if required.
	BNE	DivExit

	SUB	R2,R2,#1
	EOR	R2,R2,R5
DivExit
;	MOV	R1,R0
	MOV	R3,R2

	LDMFD	R13!,{R0-R2,R4-R5,PC}


; ======================================================================================================================

; .sprite_area_lo
;           FNload_sprites("<BASIC$Dir>.Sprites")

; .sprite_area_hi
;          FNload_sprites("<BASIC$Dir>.Sprites22")


	END



;DEF FNload_sprites(file$)
;:
;LOCAL type%,size%,file%
;:
;SYS "OS_File",17,file$ TO type%,,,,size%
;!O%=size%+4
;O%+=4 : P%+=4
;:
;file%=OPENIN(file$)
;WHILE NOT EOF#file%
; ?O%=BGET#file%
; O%+=1 : P%+=1
;ENDWHILE
;CLOSE#file%
;:
;=0
