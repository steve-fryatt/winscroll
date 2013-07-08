REM >WinScrollSrc
REM
REM Windows Scroll Module
REM (c) Stephen Fryatt, 2002
REM
REM Needs ExtBasAsm to assemble.
REM 26/32 bit neutral

version$="0.51"
save_as$="^.WinScroll"

LIBRARY "<Reporter$Dir>.AsmLib"

PRINT "Assemble debug? (Y/N)"
REPEAT
 g%=GET
UNTIL (g% AND &DF)=ASC("Y") OR (g% AND &DF)=ASC("N")
debug%=((g% AND &DF)=ASC("Y"))

ON ERROR PRINT REPORT$;" at line ";ERL : END

REM --------------------------------------------------------------------------------------------------------------------
REM Set up workspace

workspace_target%=&500
workspace_size%=0 : REM This is updated.

flags%=FNworkspace(workspace_size%,4)
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
block%=FNworkspace(workspace_size%,256)

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
          STR       R1,[R12,#configure_button%]

.set_key
          LDR       R0,[R2,#4]
          TEQ       R0,#0
          BEQ       set_speed

          LDRB      R1,[R0]
          TEQ       R1,#0
          BNE       set_speed

          LDR       R1,[R0,#1]
          STR       R1,[R12,#configure_key%]

.set_speed
          LDR       R0,[R2,#8]
          TEQ       R0,#0
          BEQ       set_linear

          LDRB      R1,[R0]
          TEQ       R1,#0
          BNE       set_linear

          LDR       R1,[R0,#1]
          STR       R1,[R12,#configure_speed%]

.set_linear
          LDR       R0,[R2,#12]
          TEQ       R0,#0
          BEQ       set_square

          LDR       R0,[R12,#flags%]
          BIC       R0,R0,#&100
          STR       R0,[R12,#flags%]

.set_square
          LDR       R0,[R2,#16]
          TEQ       R0,#0
          BEQ       set_end

          LDR       R0,[R12,#flags%]
          ORR       R0,R0,#&100
          STR       R0,[R12,#flags%]

.set_end
          ADD       R13,R13,#64

          LDMFD     R13!,{PC}


.show_configure
          SWI       "XOS_WriteS"
          EQUZ      "Mouse button: "
          ALIGN
          LDR       R0,[R12,#configure_button%]
          BL        print_val_in_r0
          SWI       "XOS_NewLine"

          SWI       "XOS_WriteS"
          EQUZ      "Modifier key: "
          ALIGN
          LDR       R0,[R12,#configure_key%]
          BL        print_val_in_r0
          SWI       "XOS_NewLine"

          SWI       "XOS_WriteS"
          EQUZ      "Scroll speed: "
          ALIGN
          LDR       R0,[R12,#configure_speed%]
          BL        print_val_in_r0
          SWI       "XOS_NewLine"

          SWI       "XOS_WriteS"
          EQUZ      "Speed control mode: "
          ALIGN
          LDR       R0,[R12,#flags%]
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
          STR       R0,[R12,#task_handle%]        ; Zero the task handle.
          STR       R0,[R12,#flags%]              ; Zero the flag-word.
          STR       R0,[R12,#sprite_area%]        ; Zero the sprite area pointer (only set if claimed from RMA).

          MOV       R0,#2
          STR       R0,[R12,#configure_speed%]

          MOV       R0,#2
          STR       R0,[R12,#configure_button%]

          MOV       R0,#1
          STR       R0,[R12,#configure_key%]


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

          LDR       R0,[R12,#task_handle%]
          CMP       R0,#0
          BLE       final_free_ws

          LDR       R1,task
          SWI       "XWimp_CloseDown"
          MOV       R1,#0
          STR       R1,[R12,#task_handle%]

; Free the sprite area if necessary

          LDR       R2,[R12,#sprite_area%]
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
          STR       R14,[R12,#task_handle%]
          LDMFD     R13!,{PC}

.service_start_wimp
          TEQ       R1,#46
          BNE       service_started_wimp

          LDR       R14,[R12,#task_handle%]
          TEQ       R14,#0
          MOVEQ     R14,#NOT-1
          STREQ     R14,[R12,#task_handle%]
          ADREQ     R0,command_desktop
          MOVEQ     R1,#0
          LDMFD     R13!,{PC}

.service_started_wimp
          LDR       R14,[R12,#task_handle%]
          CMN       R14,#1
          MOVEQ     R14,#0
          STREQ     R14,[R12,#task_handle%]
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
          LDR       R3,[R12,#configure_button%]
          TST       R2,R3
          LDMEQFD   R13!,{R2,R3,PC}

; Test to see if Ctrl is held down.  If not, again just quit.

          STMFD     R13!,{R0,R1}
          MOV       R0,#121
          LDR       R1,[R12,#configure_key%]
          EOR       R1,R1,#&80
          SWI       "XOS_Byte"
          TEQ       R1,#&FF
          LDMFD     R13!,{R0,R1}
          LDMNEFD   R13!,{R2,R3,PC}

; Set the flag to show that a scroll should start, then set up the various pieces of data and mask out the event.

          LDR       R2,[R12,#flags%]
          ORR       R2,R2,#&01
          STR       R2,[R12,#flags%]

          LDR       R2,[R1,#12]
          STR       R2,[R12,#scroll_window%]

          LDR       R2,[R1,#0]
          STR       R2,[R12,#scroll_x%]

          LDR       R2,[R1,#4]
          STR       R2,[R12,#scroll_y%]

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

          LDR       R0,[R12,#flags%]
          TST       R0,#&2
          TSTEQ     R0,#&4
          ORRNE     R0,R0,#&8
          STRNE     R0,[R12,#flags%]
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

          LDR       R0,[R12,#task_handle%]
          TEQ       R0,#0
          LDRGT     R1,task
          SWIGT     "XWimp_CloseDown"
          MOV       R0,#0
          STRGT     R0,[R12,#task_handle%]

; Set the Quit flag to zero

          STR       R0,[R12,#quit%]

; (Re) initialise the module as a Wimp task.

          LDR       R0,wimp_version
          LDR       R1,task
          ADR       R2,task_name
          ADR       R3,wimp_messages
          SWI       "XWimp_Initialise"
          SWIVS     "OS_Exit"
          STR       R1,[R12,#task_handle%]

; Create the window.

          ADR       R1,window_definition
          STR       R0,[R1,#108]
          SWI       "Wimp_CreateWindow"
          STR       R0,[R12,#win_handle%]

; Copy the icon definition into the workspace, filling in the bits we know.

          ADRW      R1,icon_def%
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

          ADRW      R0,sprite_name%               ; Point the sprite name to the workspace.
          STR       R0,[R1,#24]

; Load a sprite file or choose a suitable default internal area.

          ADR       R0,sprite_variable            ; First, identify if the system variable <WinScroll$Sprites> is set.
          ADRW      R1,block%                     ; If not, we must use the default sprite areas from inside the module.
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
          STR       R2,[R12,#sprite_area%]

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
          ADRW      R1,icon_def%                  ; Store the sprite area pointer, from the last block of code,
          STR       R0,[R1,#28]                   ; into the icon definition.

          MOV       R0,#12                        ; Set the length of the sprite name buffer.
          STR       R0,[R1,#32]

          SWI       "Wimp_CreateIcon"

; Set R1 up to be the block pointer.

          ADRW      R1,block%

; ----------------------------------------------------------------------------------------------------------------------

.poll_loop
          SWI       "OS_ReadMonotonicTime"
          ADD       R2,R0,#15
          LDR       R0,poll_mask
          SWI       "Wimp_PollIdle"

.poll_event_null
          TEQ       R0,#0
          BNE       poll_event_open_window

          LDR       R2,[R12,#flags%]

.null_start_scroll
          TST       R2,#&01
          BEQ       null_end_scroll

          BL        start_scroll
          B         poll_loop_end

.null_end_scroll
          TST       R2,#&08
          BEQ       null_do_scroll

          BL        end_scroll
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

          LDR       R0,[R12,#flags%]
          ORR       R0,R0,#&8
          STR       R0,[R12,#flags%]
;          BL        end_scroll
          B         poll_loop_end

.poll_event_wimp_message
          TEQ       R0,#17
          TEQNE     R0,#18
          BNE       poll_loop_end

          LDR       R0,[R1,#16]

.message_quit
          TEQ       R0,#0
          MOVEQ     R0,#1
          STREQ     R0,[R12,#quit%]

.poll_loop_end
          LDR       R0,[R12,#quit%]
          TEQ       R0,#0
          BEQ       poll_loop

; ----------------------------------------------------------------------------------------------------------------------

.close_down
          LDR       R0,[R12,#task_handle%]
          LDR       R1,task
          SWI       "XWimp_CloseDown"

; Set the task handle to zero and die.

          MOV       R0,#0
          STR       R0,[R12,#task_handle%]

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

          LDR       R2,[R12,#flags%]
          BIC       R2,R2,#&01
          STR       R2,[R12,#flags%]

; Check for the presence of the scroll-bars

          LDR       R0,[R12,#scroll_window%]
          STR       R0,[R1,#0]
          ORR       R1,R1,#1
          SWI       "Wimp_GetWindowInfo"
          BIC       R1,R1,#1

          LDR       R2,[R1,#32]
          ADRW      R1,icon_def%

.start_scroll_both
          TST       R2,#&10000000
          TSTNE     R2,#&40000000
          BEQ       start_scroll_horiz

          ADRL      R0,sprite_both
          BL        copy_sprite_name

          LDR       R2,[R12,#flags%]
          ORR       R2,R2,#&06
          STR       R2,[R12,#flags%]

          B         start_create

.start_scroll_horiz
          TST       R2,#&40000000
          BEQ       start_scroll_vert

          ADRL      R0,sprite_horizontal
          BL        copy_sprite_name

          LDR       R2,[R12,#flags%]
          ORR       R2,R2,#&04
          STR       R2,[R12,#flags%]

          B         start_create

.start_scroll_vert
          TST       R2,#&10000000
          BEQ       start_scroll_none

          ADRL      R0,sprite_vertical
          BL        copy_sprite_name

          LDR       R2,[R12,#flags%]
          ORR       R2,R2,#&02
          STR       R2,[R12,#flags%]

          B         start_create

.start_scroll_none
          B         exit_start_scroll               ; Just return, having done nothing.

.start_create
; Get the details about the window below the pointer.

          ADRW      R1,block%

          LDR       R0,[R12,#win_handle%]
          STR       R0,[R1,#0]
          SWI       "Wimp_GetWindowState"

; Set the window to be centred on the mouse-click.

          LDR       R2,[R12,#scroll_x%]
          SUB       R3,R2,#50
          STR       R3,[R1,#4]
          ADD       R3,R2,#50
          STR       R3,[R1,#12]
          LDR       R2,[R12,#scroll_y%]
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
          ADRW      R1,icon_def%
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

          LDR       R0,[R12,#flags%]

; Initialise the scroll values.

          MOV       R2,#0
          MOV       R3,#0

.do_scroll_x
          TST       R0,#&04
          BEQ       do_scroll_y

          LDR       R4,[R1,#0]
          LDR       R5,[R12,#scroll_x%]
          BL        calculate_offset
          MOV       R2,R3

.do_scroll_y
          TST       R0,#&02
          BEQ       do_scroll_add

          LDR       R4,[R1,#4]
          LDR       R5,[R12,#scroll_y%]
          BL        calculate_offset

.do_scroll_add

          LDR       R0,[R12,#scroll_window%]
          STR       R0,[R1,#0]
          ORR       R1,R1,#1
          SWI       "XWimp_GetWindowInfo"
          BIC       R1,R1,#1
          BVC       do_scroll_window_ok

; An error occurred, so end the scroll right now.

          BL        end_scroll
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
          LDR       R2,[R12,#scroll_window%]
          SWI       "Wimp_SendMessage"

; Re-open the arrow window on top, just to be safe.

          LDR       R0,[R12,#win_handle%]
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

.calculate_offset
          STMFD     R13!,{R0-R2,R6,R14}

          SUB       R2,R4,R5

          TST       R0,#&100
          BEQ       calculate_linear_offset

.calculate_square_offset
          AND       R4,R2,#&80000000
          TEQ       R4,#&80000000
          BNE       calculate_do_square

          MOV       R5,#-1
          EOR       R2,R2,R5
          ADD       R2,R2,#1

.calculate_do_square
          MUL       R0,R2,R2

          TEQ       R4,#&80000000
          BNE       calculate_offset_continue

          SUB       R0,R0,#1
          EOR       R0,R0,R5

          B         calculate_offset_continue

.calculate_linear_offset
          MOV       R0,R2

.calculate_offset_continue
          LDR       R1,[R12,#configure_speed%]

          BL        divide

          LDMFD     R13!,{R0-R2,R6,PC}

; ----------------------------------------------------------------------------------------------------------------------


; End a scroll operation.

.end_scroll
          STMFD     R13!,{R0-R7,R14}

; Close the arrow window.

          LDR       R0,[R12,#win_handle%]
          STR       R0,[R1,#0]
          SWI       "Wimp_CloseWindow"

; Reset the mouse pointer.

          MOV       R0,#36
          ADRL      R2,sprite_ptr_default
          MOV       R3,#%0100001
          MOV       R4,#0
          MOV       R5,#0
          MOV       R6,#0
          MOV       R7,#0 ; No pixel translation table
          SWI       "Wimp_SpriteOp"

; Clear out the scroll and end-scroll flags.

          LDR       R2,[R12,#flags%]
          BIC       R2,R2,#&0E
          STR       R2,[R12,#flags%]

          LDMFD     R13!,{R0-R7,PC}

; ======================================================================================================================

; Copy the name of a sprite into the icon sprite name buffer.
;
; => R0 -> Sprite name
;    R1 -> Icon block

.copy_sprite_name
          STMFD     R13!,{R0,R2-R3,R14}

          LDR       R2,[R1,#24]

.copy_sprite_loop
          LDRB      R3,[R0],#1
          STRB      R3,[R2],#1

          TEQ       R3,#0
          BNE       copy_sprite_loop

          LDMFD     R13!,{R0,R2-R3,PC}

; ======================================================================================================================

; Divide two numbers.
;
; => R0 = Dividend
;    R1 = Divisor
;
; <= R3 = Quotient
;   (R1 = Remainder)

.divide
          STMFD     R13!,{R0-R2,R4-R5,R14}

          MOV       R3,#1

          AND       R4,R0,#&80000000    ; Get the sign bit and if negative, invert the number.
          TEQ       R4,#&80000000
          BNE       div1

          MOV       R5,#-1
          EOR       R0,R0,R5
          ADD       R0,R0,#1

.div1
          CMP       R0,R1,ASL #1
          MOVGE     R1,R1,ASL #1
          MOVGE     R3,R3,ASL #1
          BGE       div1
          MOV       R2,#0

.div2
          CMP       R0,R1
          SUBGE     R0,R0,R1
          ADDGE     R2,R2,R3
          MOV       R1,R1,ASR #1
          MOVS      R3,R3,ASR #1
          BNE       div2

          TEQ       R4,#&80000000       ; Make the result negative if required.
          BNE       div_exit

          SUB       R2,R2,#1
          EOR       R2,R2,R5
.div_exit
;         MOV       R1,R0
          MOV       R3,R2

          LDMFD     R13!,{R0-R2,R4-R5,PC}

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
