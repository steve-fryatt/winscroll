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



workspace_target%=&500
workspace_size%=0 : REM This is updated.

WS_Flags=FNworkspace(workspace_size%,4)
icon_def%=FNworkspace(workspace_size%,36)
sprite_name%=FNworkspace(workspace_size%,12)
scroll_window%=FNworkspace(workspace_size%,4)
scroll_x%=FNworkspace(workspace_size%,4)
scroll_y%=FNworkspace(workspace_size%,4)
configure_speed%=FNworkspace(workspace_size%,4)
configure_button%=FNworkspace(workspace_size%,4)
configure_key%=FNworkspace(workspace_size%,4)
sprite_area%=FNworkspace(workspace_size%,4)
task_handle%=FNworkspace(workspace_size%,4)
quit%=FNworkspace(workspace_size%,4)
win_handle%=FNworkspace(workspace_size%,4)
WS_Block=FNworkspace(workspace_size%,256)

PRINT'"Stack size: ";workspace_target%-workspace_size%
stack%=FNworkspace(workspace_size%,workspace_target%-workspace_size%)

REM --------------------------------------------------------------------------------------------------------------------

DIM time% 5, date% 256
?time%=3
SYS "OS_Word",14,time%
SYS "Territory_ConvertDateAndTime",-1,time%,date%,255,"(%dy %m3 %ce%yr)" TO ,date_end%
?date_end%=13

REM --------------------------------------------------------------------------------------------------------------------

code_space%=20000
DIM code% code_space%

pass_flags%=%11100

IF debug% THEN PROCReportInit(200)


FOR pass%=pass_flags% TO pass_flags% OR %10 STEP %10
L%=code%+code_space%
O%=code%
P%=0
IF debug% THEN PROCReportStart(pass%)
[OPT pass%
EXT 1
          EQUD      task_code           ; Offset to task code
          EQUD      init_code           ; Offset to initialisation code
          EQUD      final_code          ; Offset to finalisation code
          EQUD      service_code        ; Offset to service-call handler
          EQUD      title_string        ; Offset to title string
          EQUD      help_string         ; Offset to help string
          EQUD      command_table       ; Offset to command table
          EQUD      0                   ; SWI Chunk number
          EQUD      0                   ; Offset to SWI handler code
          EQUD      0                   ; Offset to SWI decoding table
          EQUD      0                   ; Offset to SWI decoding code
          EQUD      0                   ; MessageTrans file
          EQUD      module_flags        ; Offset to module flags

; ======================================================================================================================

.module_flags
          EQUD      1                   ; 32-bit compatible

; ======================================================================================================================

.title_string
          EQUZ      "WinScroll"
          ALIGN

.help_string
          EQUS      "Windows Scroll"
          EQUB      9
          EQUS      version$
          EQUS      " "
          EQUS      $date%
          EQUZ      " © Stephen Fryatt, 2002"
          ALIGN

; ======================================================================================================================

.command_table
          EQUZ      "Desktop_WinScroll"
          ALIGN
          EQUD      command_desktop
          EQUD      &00000000
          EQUD      0
          EQUD      0

          EQUZ      "WinScrollConfigure"
          ALIGN
          EQUD      command_configure
          EQUD      &00060000
          EQUD      command_configure_syntax
          EQUD      command_configure_help

          EQUD      0

; ----------------------------------------------------------------------------------------------------------------------

.command_configure_help
          EQUS      "*"
          EQUB      27
          EQUB      0
          EQUS      " "
          EQUS      "configures the window scroll module or displays the current configuration."
          EQUB      13

.command_configure_syntax
          EQUB      27
          EQUB      30
          EQUS      "<-Button <button number>] [-Modifier <key number>]"
          EQUB      13
          EQUB      9
          EQUS      "[-Speed <speed>] [-Linear|Square]"
          EQUB      0

          ALIGN
; ----------------------------------------------------------------------------------------------------------------------

.command_desktop
          STMFD     R13!,{R14}

          MOV       R2,R0
          ADR       R1,title_string
          MOV       R0,#2
          SWI       "XOS_Module"

          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

.configure_string
          EQUZ      "button/K/E,modifier/K/E,speed/K/E,linear/S,square/S"
          ALIGN

.command_configure
          STMFD     R13!,{R14}

          LDR       R12,[R12]

          TEQ       R1,#0
          BEQ       show_configure

.set_configure
          SUB       R13,R13,#64                ; Claim 64 bytes of space from the stack.

          MOV       R1,R0
          ADR       R0,configure_string
          MOV       R2,R13
          MOV       R3,#64
          SWI       "OS_ReadArgs"

.set_button
          LDR       R0,[R2,#0]
          TEQ       R0,#0
          BEQ       set_key

          LDRB      R1,[R0]
          TEQ       R1,#0
          BNE       set_key

          LDR       R1,[R0,#1]
          STR       R1,[R12,#WS_ConfigureButton]

.set_key
          LDR       R0,[R2,#4]
          TEQ       R0,#0
          BEQ       set_speed

          LDRB      R1,[R0]
          TEQ       R1,#0
          BNE       set_speed

          LDR       R1,[R0,#1]
          STR       R1,[R12,#WS_ConfigureKey]

.set_speed
          LDR       R0,[R2,#8]
          TEQ       R0,#0
          BEQ       set_linear

          LDRB      R1,[R0]
          TEQ       R1,#0
          BNE       set_linear

          LDR       R1,[R0,#1]
          STR       R1,[R12,#WS_ConfigureSpeed]

.set_linear
          LDR       R0,[R2,#12]
          TEQ       R0,#0
          BEQ       set_square

          LDR       R0,[R12,#WS_Flags]
          BIC       R0,R0,#&100
          STR       R0,[R12,#WS_Flags]

.set_square
          LDR       R0,[R2,#16]
          TEQ       R0,#0
          BEQ       set_end

          LDR       R0,[R12,#WS_Flags]
          ORR       R0,R0,#&100
          STR       R0,[R12,#WS_Flags]

.set_end
          ADD       R13,R13,#64

          LDMFD     R13!,{PC}


.show_configure
          SWI       "XOS_WriteS"
          EQUZ      "Mouse button: "
          ALIGN
          LDR       R0,[R12,#WS_ConfigureButton]
          BL        print_val_in_r0
          SWI       "XOS_NewLine"

          SWI       "XOS_WriteS"
          EQUZ      "Modifier key: "
          ALIGN
          LDR       R0,[R12,#WS_ConfigureKey]
          BL        print_val_in_r0
          SWI       "XOS_NewLine"

          SWI       "XOS_WriteS"
          EQUZ      "Scroll speed: "
          ALIGN
          LDR       R0,[R12,#WS_ConfigureSpeed]
          BL        print_val_in_r0
          SWI       "XOS_NewLine"

          SWI       "XOS_WriteS"
          EQUZ      "Speed control mode: "
          ALIGN
          LDR       R0,[R12,#WS_Flags]
          TST       R0,#&100
          ADREQ     R0,show_control_lin
          ADRNE     R0,show_control_sqr
          SWI       "XOS_Write0"
          SWI       "XOS_NewLine"

          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

.show_control_lin
          EQUZ      "Linear"
.show_control_sqr
          EQUZ      "Square"
          ALIGN

; ----------------------------------------------------------------------------------------------------------------------

.print_val_in_r0
          STMFD     R13!,{R1-R2,R14}
          SUB       R13,R13,#16
          MOV       R1,R13
          MOV       R2,#16                     ; the size of this to the OS to
          SWI       "XOS_ConvertCardinal4"     ; make it into a number...
          SWI       "XOS_Write0"               ; ...ready to print on the screen.
          ADD       R13,R13,#16
          LDMFD     R13!,{R1-R2,PC}

; ======================================================================================================================

.init_code
          STMFD     R13!,{R14}

; Claim workspace for ourselves and store the pointer in our private workspace.
; This space is used for everything; both the module 'back-end' and the WIMP task.

          MOV       R0,#6
          MOV       R3,#workspace_size%
          SWI       "XOS_Module"
          BVS       init_exit
          STR       R2,[R12]
          MOV       R12,R2

; Initialise the workspace that was just claimed.

          MOV       R0,#0
          STR       R0,[R12,#WS_TaskHandle]        ; Zero the task handle.
          STR       R0,[R12,#WS_Flags]              ; Zero the flag-word.
          STR       R0,[R12,#WS_SpriteArea]        ; Zero the sprite area pointer (only set if claimed from RMA).

          MOV       R0,#2
          STR       R0,[R12,#WS_ConfigureSpeed]

          MOV       R0,#2
          STR       R0,[R12,#WS_ConfigureButton]

          MOV       R0,#1
          STR       R0,[R12,#WS_ConfigureKey]


; Flag word; bit 0 - request to start scrolling
;            bit 1 - horizontal scrolling in progress
;            bit 2 - vertical scrolling in progress
;            bit 3 - request to stop scrolling
;            bit 8 - use square-mode scrolling

; Initilise the filter

          ADR       R0,title_string
          ADR       R1,filter_code
          MOV       R2,R12
          MOV       R3,#0
          LDR       R4,filter_mask
          SWI       "XFilter_RegisterPostFilter"

; Claim EventV

          MOV       R0,#&10
          ADR       R1,eventv_code
          MOV       R2,R12
          SWI       "OS_Claim"

; Enable EventV

          MOV       R0,#14
          MOV       R1,#11
          SWI       "OS_Byte"

.init_exit
          LDMFD     R13!,{PC}

; ----------------------------------------------------------------------------------------------------------------------

.final_code
          STMFD     R13!,{R14}
          LDR       R12,[R12]

; Disable EventV

          MOV       R0,#13
          MOV       R1,#11
          SWI       "OS_Byte"

; De-register from EventV

          MOV       R0,#&10
          ADR       R1,eventv_code
          MOV       R2,R12
          SWI       "OS_Release"

; De-register the filter

          ADR       R0,title_string
          ADR       R1,filter_code
          MOV       R2,R12
          MOV       R3,#0
          LDR       R4,filter_mask
          SWI       "XFilter_DeRegisterPostFilter"

; Kill the wimp task if it's running.

          LDR       R0,[R12,#WS_TaskHandle]
          CMP       R0,#0
          BLE       final_free_ws

          LDR       R1,task
          SWI       "XWimp_CloseDown"
          MOV       R1,#0
          STR       R1,[R12,#WS_TaskHandle]

; Free the sprite area if necessary

          LDR       R2,[R12,#WS_SpriteArea]
          TEQ       R2,#0
          BEQ       final_free_ws
          MOV       R0,#7
          SWI       "XOS_Module"

.final_free_ws
          TEQ       R10,#1
          TEQEQ     R12,#0
          BEQ       final_exit
          MOV       R0,#7
          MOV       R2,R12
          SWI       "XOS_Module"

.final_exit
          LDMFD     R13!,{PC}

; ======================================================================================================================

.service_code
          TEQ       R1,#&27
          TEQNE     R1,#&49
          TEQNE     R1,#&4A

          MOVNE     PC,R14

          STMFD     R13!,{R14}
          LDR       R12,[R12]

.service_reset
          TEQ       R1,#&27
          BNE       service_start_wimp

          MOV       R14,#0
          STR       R14,[R12,#WS_TaskHandle]
          LDMFD     R13!,{PC}

.service_start_wimp
          TEQ       R1,#46
          BNE       service_started_wimp

          LDR       R14,[R12,#WS_TaskHandle]
          TEQ       R14,#0
          MOVEQ     R14,#NOT-1
          STREQ     R14,[R12,#WS_TaskHandle]
          ADREQ     R0,command_desktop
          MOVEQ     R1,#0
          LDMFD     R13!,{PC}

.service_started_wimp
          LDR       R14,[R12,#WS_TaskHandle]
          CMN       R14,#1
          MOVEQ     R14,#0
          STREQ     R14,[R12,#WS_TaskHandle]
          LDMFD     R13!,{PC}

; ======================================================================================================================

.filter_mask
          EQUD      &00003FBF

; ======================================================================================================================

.filter_code

          STMFD     R13!,{R2,R3,R14}

          TEQ       R0,#6
          LDMNEFD   R13!,{R2,R3,PC}

; Test if the mouse button was Menu; if not, just quit now

          LDR       R2,[R1,#8]
          LDR       R3,[R12,#WS_ConfigureButton]
          TST       R2,R3
          LDMEQFD   R13!,{R2,R3,PC}

; Test to see if Ctrl is held down.  If not, again just quit.

          STMFD     R13!,{R0,R1}
          MOV       R0,#121
          LDR       R1,[R12,#WS_ConfigureKey]
          EOR       R1,R1,#&80
          SWI       "XOS_Byte"
          TEQ       R1,#&FF
          LDMFD     R13!,{R0,R1}
          LDMNEFD   R13!,{R2,R3,PC}

; Set the flag to show that a scroll should start, then set up the various pieces of data and mask out the event.

          LDR       R2,[R12,#WS_Flags]
          ORR       R2,R2,#&01
          STR       R2,[R12,#WS_Flags]

          LDR       R2,[R1,#12]
          STR       R2,[R12,#WS_ScrollWindow]

          LDR       R2,[R1,#0]
          STR       R2,[R12,#WS_ScrollX]

          LDR       R2,[R1,#4]
          STR       R2,[R12,#WS_ScrollY]

          MOV       R0,#-1

          LDMFD     R13!,{R2,R3,PC}

; ======================================================================================================================

.eventv_code

; Check that it is a key transition event and exit if not.

          TEQ       R0,#11
          MOVNE     PC,R14

; Check the key transition; if it's not a key-down, exit.

          TEQ       R1,#1
          MOVNE     PC,R14

; Test the keys to see if it's a mouse button.

          TEQ       R2,#&70
          TEQNE     R2,#&71
          TEQNE     R2,#&72
          MOVNE     PC,R14

; Lodge an end-scroll request in the flag word.

          LDR       R0,[R12,#WS_Flags]
          TST       R0,#&2
          TSTEQ     R0,#&4
          ORRNE     R0,R0,#&8
          STRNE     R0,[R12,#WS_Flags]
          MOVNE     R0,#11

          MOV       PC,R14

; ======================================================================================================================

.task
          EQUS      "TASK"

.wimp_version
          EQUD      310

.wimp_messages
          EQUD      0         ; Message_Quit (null list, so all messages are accepted...)

.poll_mask
          EQUD      &3830

.task_name
          EQUZ      "Windows Scroll"

.misused_start_command
          EQUD      0
          EQUZ      "Use *Desktop to start WinScroll."
          ALIGN

.hi_res_suffix
          EQUD      &00003232 ; "22"

.sprite_variable
          EQUZ      "WinScroll$Sprites"
          ALIGN

.sprite_file_type
          EQUD      &FF9

.window_definition
          EQUD      100       ; Visible area min x
          EQUD      100       ; Visible area min y
          EQUD      200       ; Visible area max x
          EQUD      200       ; Visible area max y
          EQUD      0         ; X scroll offset
          EQUD      0         ; Y scroll offset
          EQUD      -1        ; Handle to open window behind
          EQUD      &80000810 ; Window flags
          EQUD      &01070207
          EQUD      &000C0207
          EQUD      0         ; Work area min x
          EQUD      -100      ; Work area min y
          EQUD      100       ; Work area max x
          EQUD      0         ; Work area max y
          EQUD      &2700003D ; Title bar icon flags
          EQUD      3         ; Work area flags
          EQUD      1         ; Sprite area pointer
          EQUW      0         ; Minimum width of window
          EQUW      0         ; Minimum height of window
          EQUD      0         ; Window title
          EQUD      0         ; Window title
          EQUD      0         ; Window title
          EQUD      0         ; Number of icons

.icon_definition
          EQUD      4         ; Icon bounding box
          EQUD      -96
          EQUD      96
          EQUD      -4
          EQUD      &1700311A ; Icon flags
          ALIGN

; ======================================================================================================================

.task_code
          LDR       R12,[R12]
          ADRW      R13,workspace_size%+4         ; Set the stack up.

; Check that we aren't in the desktop.

          SWI       "XWimp_ReadSysInfo"
          TEQ       R0,#0
          ADREQ     R0,misused_start_command
          SWIEQ     "OS_GenerateError"

; Kill any previous version of our task which may be running.

          LDR       R0,[R12,#WS_TaskHandle]
          TEQ       R0,#0
          LDRGT     R1,task
          SWIGT     "XWimp_CloseDown"
          MOV       R0,#0
          STRGT     R0,[R12,#WS_TaskHandle]

; Set the Quit flag to zero

          STR       R0,[R12,#WS_Quit]

; (Re) initialise the module as a Wimp task.

          LDR       R0,wimp_version
          LDR       R1,task
          ADR       R2,task_name
          ADR       R3,wimp_messages
          SWI       "XWimp_Initialise"
          SWIVS     "OS_Exit"
          STR       R1,[R12,#WS_TaskHandle]

; Create the window.

          ADR       R1,window_definition
          STR       R0,[R1,#108]
          SWI       "Wimp_CreateWindow"
          STR       R0,[R12,#WS_WindowHandle]

; Copy the icon definition into the workspace, filling in the bits we know.

          ADRW      R1,WS_IconDef
          STR       R0,[R1,#0]                    ; Store the window handle

          ADR       R2,icon_definition            ; Copy the data from the icon def block into a writable area
          LDR       R0,[R2,#0]                    ; in the workspace.
          STR       R0,[R1,#4]
          LDR       R0,[R2,#4]
          STR       R0,[R1,#8]
          LDR       R0,[R2,#8]
          STR       R0,[R1,#12]
          LDR       R0,[R2,#12]
          STR       R0,[R1,#16]
          LDR       R0,[R2,#16]
          STR       R0,[R1,#20]

          ADRW      R0,WS_SpriteName               ; Point the sprite name to the workspace.
          STR       R0,[R1,#24]

; Load a sprite file or choose a suitable default internal area.

          ADR       R0,sprite_variable            ; First, identify if the system variable <WinScroll$Sprites> is set.
          ADRW      R1,WS_Block                     ; If not, we must use the default sprite areas from inside the module.
          MOV       R2,#255
          MOV       R3,#0
          MOV       R4,#0
          SWI       "XOS_ReadVarVal"
          BVS       init_sprites_internal

.init_sprites_external
          MOV       R0,#2
          SWI       "Wimp_ReadSysInfo"

          ADD       R2,R2,R1                      ; R2 points to the character after the end of the filename.  Copy it
          MOV       R7,R2                         ; to R7 so that after the '22' suffix is added we can get back.

.init_sprites_copy_suffix
          LDRB      R3,[R0],#1                    ; Put the sprites suffix on to the name.
          STRB      R3,[R2],#1
          CMP       R3,#32
          BGE       init_sprites_copy_suffix

          MOV       R0,#23                        ; Try to find the file using the suffix name...
          SWI       "XOS_File"
          TEQ       R0,#1
          BEQ       init_sprites_load_file

          MOV       R0,#0                         ; ...and, if that fails, try without the suffix.
          STRB      R0,[R7]
          MOV       R0,#23
          SWI       "XOS_File"
          TEQ       R0,#1
          BNE       init_sprites_internal

.init_sprites_load_file
          LDR       R0,sprite_file_type           ; Check that the file found is a sprite file.  If not, use the
          TEQ       R0,R6                         ; internal sprite areas.
          BNE       init_sprites_internal

          MOV       R0,#6                         ; Claim memory from the RMA for the area.  If it fails, use the
          ADD       R3,R4,#4                      ; internal sprites; otherwise store the pointer so we know to
          SWI       "XOS_Module"                  ; free the memory afterwards.
          BVS       init_sprites_internal
          STR       R2,[R12,#WS_SpriteArea]

          STR       R3,[R2]                       ; Initialise the area.
          MOV       R3,#16
          STR       R3,[R2,#8]

          SWAP      R1,R2                         ; Load the sprite file into memory.
          MOV       R0,#&0A
          ORR       R0,R0,#&100
          SWI       "XOS_SpriteOp"

          BVS       init_sprites_internal

          MOV       R0,R1

          B         init_sprites_name_buffer

.init_sprites_internal
          MOV       R0,#2                         ; Determine if we need hi or lo res sprites and set the area pointer
          SWI       "Wimp_ReadSysInfo"            ; appropriately.
          LDR       R0,[R0]
          BIC       R0,R0,#&FF000000
          LDR       R2,hi_res_suffix
          TEQ       R0,R2
          ADREQL    R0,sprite_area_hi
          ADRNEL    R0,sprite_area_lo

.init_sprites_name_buffer
          ADRW      R1,WS_IconDef                  ; Store the sprite area pointer, from the last block of code,
          STR       R0,[R1,#28]                   ; into the icon definition.

          MOV       R0,#12                        ; Set the length of the sprite name buffer.
          STR       R0,[R1,#32]

          SWI       "Wimp_CreateIcon"

; Set R1 up to be the block pointer.

          ADRW      R1,WS_Block

; ----------------------------------------------------------------------------------------------------------------------

.poll_loop
          SWI       "OS_ReadMonotonicTime"
          ADD       R2,R0,#15
          LDR       R0,poll_mask
          SWI       "Wimp_PollIdle"

.poll_event_null
          TEQ       R0,#0
          BNE       poll_event_open_window

          LDR       R2,[R12,#WS_Flags]

.null_start_scroll
          TST       R2,#&01
          BEQ       null_end_scroll

          BL        start_scroll
          B         poll_loop_end

.null_end_scroll
          TST       R2,#&08
          BEQ       null_do_scroll

          BL        EndScroll
          B         poll_loop_end

.null_do_scroll
          TST       R2,#&06
          BEQ       poll_loop_end

          BL        do_scroll
          B         poll_loop_end

.poll_event_open_window
          TEQ       R0,#2
          BNE       poll_event_close_window

          SWI       "Wimp_OpenWindow"
          B         poll_loop_end

.poll_event_close_window
          TEQ       R0,#3
          BNE       poll_event_mouse_click

          SWI       "Wimp_CloseWindow"
          B         poll_loop_end

.poll_event_mouse_click
          TEQ       R0,#6
          BNE       poll_event_wimp_message

          LDR       R0,[R12,#WS_Flags]
          ORR       R0,R0,#&8
          STR       R0,[R12,#WS_Flags]
;          BL        EndScroll
          B         poll_loop_end

.poll_event_wimp_message
          TEQ       R0,#17
          TEQNE     R0,#18
          BNE       poll_loop_end

          LDR       R0,[R1,#16]

.message_quit
          TEQ       R0,#0
          MOVEQ     R0,#1
          STREQ     R0,[R12,#WS_Quit]

.poll_loop_end
          LDR       R0,[R12,#WS_Quit]
          TEQ       R0,#0
          BEQ       poll_loop

; ----------------------------------------------------------------------------------------------------------------------

.close_down
          LDR       R0,[R12,#WS_TaskHandle]
          LDR       R1,task
          SWI       "XWimp_CloseDown"

; Set the task handle to zero and die.

          MOV       R0,#0
          STR       R0,[R12,#WS_TaskHandle]

          SWI       "OS_Exit"

; ======================================================================================================================

.sprite_horizontal
          EQUZ      "ws_horiz"

.sprite_vertical
          EQUZ      "ws_vert"

.sprite_both
          EQUZ      "ws_both"

.sprite_ptr_default
          EQUZ      "ptr_default"

.sprite_ptr_scroll
          EQUZ      "ptr_def"
          ALIGN

; ======================================================================================================================

.start_scroll
          STMFD     R13!,{R0-R7,R14}

; Clear the start-flag.

          LDR       R2,[R12,#WS_Flags]
          BIC       R2,R2,#&01
          STR       R2,[R12,#WS_Flags]

; Check for the presence of the scroll-bars

          LDR       R0,[R12,#WS_ScrollWindow]
          STR       R0,[R1,#0]
          ORR       R1,R1,#1
          SWI       "Wimp_GetWindowInfo"
          BIC       R1,R1,#1

          LDR       R2,[R1,#32]
          ADRW      R1,WS_IconDef

.start_scroll_both
          TST       R2,#&10000000
          TSTNE     R2,#&40000000
          BEQ       start_scroll_horiz

          ADRL      R0,sprite_both
          BL        CopySpriteName

          LDR       R2,[R12,#WS_Flags]
          ORR       R2,R2,#&06
          STR       R2,[R12,#WS_Flags]

          B         start_create

.start_scroll_horiz
          TST       R2,#&40000000
          BEQ       start_scroll_vert

          ADRL      R0,sprite_horizontal
          BL        CopySpriteName

          LDR       R2,[R12,#WS_Flags]
          ORR       R2,R2,#&04
          STR       R2,[R12,#WS_Flags]

          B         start_create

.start_scroll_vert
          TST       R2,#&10000000
          BEQ       start_scroll_none

          ADRL      R0,sprite_vertical
          BL        CopySpriteName

          LDR       R2,[R12,#WS_Flags]
          ORR       R2,R2,#&02
          STR       R2,[R12,#WS_Flags]

          B         start_create

.start_scroll_none
          B         exit_start_scroll               ; Just return, having done nothing.

.start_create
; Get the details about the window below the pointer.

          ADRW      R1,WS_Block

          LDR       R0,[R12,#WS_WindowHandle]
          STR       R0,[R1,#0]
          SWI       "Wimp_GetWindowState"

; Set the window to be centred on the mouse-click.

          LDR       R2,[R12,#WS_ScrollX]
          SUB       R3,R2,#50
          STR       R3,[R1,#4]
          ADD       R3,R2,#50
          STR       R3,[R1,#12]
          LDR       R2,[R12,#WS_ScrollY]
          SUB       R3,R2,#50
          STR       R3,[R1,#8]
          ADD       R3,R2,#50
          STR       R3,[R1,#16]

          MOV       R0,#-1
          STR       R0,[R1,#24]
          SWI       "Wimp_OpenWindow"

; Set the mouse pointer.

          MOV       R0,#36
          ORR       R0,R0,#&100
          ADRW      R1,WS_IconDef
          LDR       R1,[R1,#28]
          ADRL      R2,sprite_ptr_scroll
          MOV       R3,#%0100010
          MOV       R4,#6
          MOV       R5,#6
          MOV       R6,#0
          MOV       R7,#0 ; No pixel translation table
          SWI       "OS_SpriteOp"


; Just for Toolbox apps, close the menu again...

          MOV       R1,#-1
          SWI       "Wimp_CreateMenu"

.exit_start_scroll
          LDMFD     R13!,{R0-R7,PC}

; ----------------------------------------------------------------------------------------------------------------------

; Perform scrolling on a Null event.

.do_scroll
          STMFD     R13!,{R0-R5,R14}

          SWI       "Wimp_GetPointerInfo"

          LDR       R0,[R12,#WS_Flags]

; Initialise the scroll values.

          MOV       R2,#0
          MOV       R3,#0

.do_scroll_x
          TST       R0,#&04
          BEQ       do_scroll_y

          LDR       R4,[R1,#0]
          LDR       R5,[R12,#WS_ScrollX]
          BL        CalculateOffset
          MOV       R2,R3

.do_scroll_y
          TST       R0,#&02
          BEQ       do_scroll_add

          LDR       R4,[R1,#4]
          LDR       R5,[R12,#WS_ScrollY]
          BL        CalculateOffset

.do_scroll_add

          LDR       R0,[R12,#WS_ScrollWindow]
          STR       R0,[R1,#0]
          ORR       R1,R1,#1
          SWI       "XWimp_GetWindowInfo"
          BIC       R1,R1,#1
          BVC       do_scroll_window_ok

; An error occurred, so end the scroll right now.

          BL        EndScroll
          B         exit_do_scroll

.do_scroll_window_ok

; Add in the X scroll offset

          LDR       R0,[R1,#20]
          ADD       R0,R0,R2
          STR       R0,[R1,#20]

; Add in the Y scroll offset

          LDR       R0,[R1,#24]
          ADD       R0,R0,R3
          STR       R0,[R1,#24]

; Send a Window Open Event to the task.

          MOV       R0,#2
          LDR       R2,[R12,#WS_ScrollWindow]
          SWI       "Wimp_SendMessage"

; Re-open the arrow window on top, just to be safe.

          LDR       R0,[R12,#WS_WindowHandle]
          STR       R0,[R1,#0]
          SWI       "Wimp_GetWindowState"
          MOV       R0,#-1
          STR       R0,[R1,#28]
          SWI       "Wimp_OpenWindow"

.exit_do_scroll
          LDMFD     R13!,{R0-R5,PC}

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
	SWI	"Wimp_CloseWindow"

; Reset the mouse pointer.

	MOV	R0,#36
	ADRL	R2,sprite_ptr_default
	MOV	R3,#%0100001
	MOV	R4,#0
	MOV	R5,#0
	MOV	R6,#0
	MOV	R7,#0					; No pixel translation table
	SWI	"Wimp_SpriteOp"

; Clear out the scroll and end-scroll flags.

	LDR	R2,[R12,#WS_Flags]
	BIC	R2,R2,#&0E
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
.DivExit
;	MOV	R1,R0
	MOV	R3,R2

	LDMFD	R13!,{R0-R2,R4-R5,PC}

; ======================================================================================================================

.sprite_area_lo
          FNload_sprites("<BASIC$Dir>.Sprites")

.sprite_area_hi
          FNload_sprites("<BASIC$Dir>.Sprites22")
]
IF debug% THEN
[OPT pass%
          FNReportGen
]
ENDIF
NEXT pass%

SYS "OS_File",10,"<Basic$Dir>."+save_as$,&FFA,,code%,code%+P%

END



DEF FNworkspace(RETURN size%,dim%)
LOCAL ptr%
ptr%=size%
size%+=dim%
=ptr%



DEF FNload_sprites(file$)
:
LOCAL type%,size%,file%
:
SYS "OS_File",17,file$ TO type%,,,,size%
!O%=size%+4
O%+=4 : P%+=4
:
file%=OPENIN(file$)
WHILE NOT EOF#file%
 ?O%=BGET#file%
 O%+=1 : P%+=1
ENDWHILE
CLOSE#file%
:
=0
