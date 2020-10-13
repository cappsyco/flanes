#import "references/vic2constants.asm"
#import "references/generalconstants.asm"

// OPTIONS
.var LANE_1_Y = 78
.var LANE_2_Y = 124
.var LANE_3_Y = 170
.var LANE_4_Y = 216

BasicUpstart2(MAIN)

*= $1000 "Main Program"

// VARIABLES
mainloop_flag: .byte $00

/*
titlename1: .text "  UCCCC I     UCCCI U   U UCCCC UCCCC   "
titlename2: .text "  B     B     B   B BM  B B     B       "
titlename3: .text "  BDD   B     BDDDB B M B BDD   JCCCI   "
titlename4: .text "  B     B     B   B B  MB B         B   "
titlename5: .text "  B     JCCCC K   J K   K JCCCC CCCCK   "
*/
.encoding "petscii_mixed"
titlename1: .text "  UCCCC B     UCCCI UCI B UCCCC UCCCC   "
titlename2: .text "  B     B     B   B B B B B     B       "
titlename3: .text "  BDD   B     BDDDB B B B BDD   JCCCI   "
titlename4: .text "  B     B     B   B B B B B         B   "
titlename5: .text "  B     JCCCC B   B B JCK JCCCC CCCCK   "

.encoding "screencode_mixed"
titleinstruction: .text "         press 'space' to start         "
titlecredit: .text      "        by jonathan capps (2020)        "

lanecolors: .byte YELLOW, GREEN, CYAN, LIGHT_RED
//lane

gameover1: .text           "               game over!               "
gameover2: .text           "        press 'space' to restart        "

hud_text: .text "lives : ?                 score : 000000"

rnd_avoid: .byte 0

key_pressed: .byte $00
score_count: .byte 0,0,0
difficulty_increment: .byte 0
lives_count: .byte 4

selected_lane: .byte 0
active_lane: .byte 0
active_lane_movement: .byte 0

lane_shape_speed: .byte 2
lane_shape_x: .byte $00,$00

// MAIN PROGRAM
MAIN: {

    setup: {
        jsr SCREEN.clear
        jsr SCREEN.title_text
        jsr SCREEN.text_color.white
        jmp title
    }
    
    gameover: {
        jsr SCREEN.clear
        jsr SCREEN.gameover_text
        jsr SCREEN.text_color.black
        jsr SHAPES.clear
    }
    
    reset: {
        lda #$00
        sta mainloop_flag
        sta key_pressed
        sta score_count
        sta score_count + 1 
        sta score_count + 2
        sta selected_lane
        sta active_lane
        sta active_lane_movement
        sta lane_shape_x
        sta lane_shape_x + 1
        lda #$04
        sta lives_count
    }

    title: {
        lda PORT_REG_B
        cmp #$ef
        bne title
    }

    game: {
        // game setup
        jsr INTERRUPTS.init
        jsr SCREEN.clear
        jsr SHAPES.setup
        jsr HUD.color
        jsr HUD.draw
        jsr GAMEPLAY.update_lives
        jsr GAMEPLAY.setup
       
        // game loop
        mainloop: 
            lda mainloop_flag
            cmp #$01
            bne mainloop

            jsr SHAPES.move
            jsr SHAPES.draw
            jsr GAMEPLAY.key_check
            dec mainloop_flag
            
            jmp mainloop
    }

}

// gameplaye logic
GAMEPLAY: {
   
    setup: {
        lda #%11111111
        sta DD_REG_A
        lda #%00000000
        sta DD_REG_B
        lda #%11111110
        sta PORT_REG_A

        lda #$FF  
        sta $D40E 
        sta $D40F
        lda #$80  
        sta $D412 
        rts
    }

    generate_rnd: {

        !:
            lda $D41B
            lsr
            lsr
            lsr
            lsr
            lsr
            lsr
            clc
            adc #1
            cmp rnd_avoid
            beq !-
            rts

    }

    update_lives: {
        lda lives_count
        cmp #0
        bmi game_over

        clc
        adc #48
        sta SCREEN_RAM + 8
        rts
    }

    game_over: {
        jmp MAIN.gameover
    }
    
    key_check: {
            lda #%11111111
            sta DD_REG_A
            lda #%00000000
            sta DD_REG_B
            lda #%11111110
            sta PORT_REG_A
        f1:
            lda PORT_REG_B
            and #%00010000
            bne f3
            lda #$01
            sta selected_lane
            jmp end_withpress
        f3:
            lda PORT_REG_B
            and #%00100000
            bne f5
            lda #$02
            sta selected_lane
            jmp end_withpress
        f5:
            lda PORT_REG_B
            and #%01000000
            bne f7
            lda #$03
            sta selected_lane
            jmp end_withpress
        f7:
            lda PORT_REG_B
            and #%00001000
            bne end_nopress
            lda #$04
            sta selected_lane
        end_withpress:
            lda key_pressed
            cmp #$00
            bne end_holdpress

            lda #$01
            sta key_pressed
            lda selected_lane
            cmp active_lane
            bne lose_life
            
            jsr SCORE.increase
            rts
        end_nopress:
            lda #$00
            sta key_pressed
        end_holdpress:
            lda #$00
            sta selected_lane
            rts
        lose_life:
            lda lives_count
            sec
            sbc #1
            sta lives_count
            jsr update_lives
            rts
    }

}

// SCORE
SCORE: {

    increase: {
        sed
        clc
        lda score_count
        adc #10
        sta score_count
        lda score_count+1
        adc #0
        sta score_count+1
        lda score_count+2
        adc #0
        sta score_count+2
        cld
    }

    check_difficulty: {
        clc
        lda difficulty_increment
        adc #10
        cmp #60
        bne process
        inc lane_shape_speed
        lda #0
    }

    process: {
            sta difficulty_increment
            ldy #$27
            ldx #$00
        !:
            lda score_count,x
            pha
            and #$0f
            jsr draw

            pla
            lsr
            lsr
            lsr
            lsr
            jsr draw
            inx
            cpx #3
            bne !-
            rts
    }

    draw: {
        clc
        adc #48
        sta SCREEN_RAM,y
        dey
        rts
    }
}

// SPIKES
SHAPES: {

    clear: {
        lda #%00000000
        sta SPRITE_ENABLE
        rts
    }

    setup: {
        lda #200
        sta SPRITE_POINTER_0
        lda #201
        sta SPRITE_POINTER_1
        lda #202
        sta SPRITE_POINTER_2
        lda #203
        sta SPRITE_POINTER_3

        lda #BLACK
        sta SPRITE_COLOR_0
        sta SPRITE_COLOR_1
        sta SPRITE_COLOR_2
        sta SPRITE_COLOR_3

        lda #%00000000
        sta SPRITE_DOUBLE_X
        sta SPRITE_DOUBLE_Y
        
        lda #%00000000
        sta SPRITE_MODE

        lda #0
        sta SPRITE_0_X
        lda #45
        sta SPRITE_1_X
        lda #24
        sta SPRITE_2_X
        sta SPRITE_3_X
        lda #%00000010
        sta SPRITE_MSB_X       
               

        lda #%00001111
        sta SPRITE_ENABLE

        rts
    }

    move: {
        lda active_lane_movement
        cmp #0
        bne move_active

        set_lane:
            lda #1
            sta active_lane_movement
            lda active_lane
            sta rnd_avoid
            jsr GAMEPLAY.generate_rnd
            sta active_lane
        move_active:
            lda active_lane
            cmp #1
            beq set_y_1
            cmp #2
            beq set_y_2
            cmp #3
            beq set_y_3
            cmp #4
            beq set_y_4   
        set_y_1:
            lda #LANE_1_Y
            jmp move_x
        set_y_2:
            lda #LANE_2_Y
            jmp move_x
        set_y_3:
            lda #LANE_3_Y
            jmp move_x
        set_y_4:
            lda #LANE_4_Y
        move_x:
            sta SPRITE_0_Y 
            clc
            lda lane_shape_x
            adc lane_shape_speed
            sta lane_shape_x
            bcc move_end
            lda #$01
            sta lane_shape_x + 1
        move_end:
            rts
    }

    draw: {
        set_x:
            lda lane_shape_x
            sta SPRITE_0_X
            lda lane_shape_x + 1
            cmp #$01
            bne draw_end
        set_high_x:
            lda lane_shape_x
            clc
            cmp #100
            bcs set_low_x
            lda SPRITE_MSB_X
            ora #%00000001
            jmp store_msb_x
        set_low_x:
            lda #00
            sta lane_shape_x + 1
            sta lane_shape_x
            lda #0
            sta active_lane_movement
            lda SPRITE_MSB_X
            and #%11111110
        store_msb_x:    
            sta SPRITE_MSB_X
        draw_end:
            lda lane_shape_x
            sta SPRITE_0_X
            rts
    }

}

HUD: {

    color: {
            ldx #$27
            lda #WHITE
        !: 
            sta COLOR_RAM,x
            dex
            bpl !-
            rts
    }

    draw: {
            ldx #$27
        !: 
            lda hud_text,x
            sta SCREEN_RAM,x
            dex
            bpl !-
            rts
    }

}

// SCREEN OPERATIONS
SCREEN: {

    clear: {
            lda #BLACK
            sta BORDER_COLOR
            //lda #RED
            sta SCREEN_COLOR
            jsr CLEAR_SCREEN
            rts
    }
        
    text_color: {

        white:
            lda #WHITE
            jmp set_color
        black:
            lda #BLACK
        set_color:
                ldx #0
            !:
                sta COLOR_RAM,x
                sta COLOR_RAM + 250,x
                sta COLOR_RAM + 500,x
                sta COLOR_RAM + 750,x
                inx
                cpx #250
                bne !-
                rts
            
    }

    gameover_text: {

        gameover1_draw:
                ldx #$27
            !:
                lda gameover1,x
                sta $0568,x
                dex
                bpl !-
        gameover2_draw:
                ldx #$27
            !:
                lda gameover2,x
                sta $05b8,x
                dex
                bpl !-
                rts
    }

    title_text: {

        .label TITLE_START = SCREEN_RAM + 80

        title1_draw:
                ldx #$27
            !:
                lda titlename1,x
                sta TITLE_START,x
                dex
                bpl !-
        title2_draw:
                ldx #$27
            !:
                lda titlename2,x
                sta TITLE_START + 40,x
                dex
                bpl !-
        title3_draw:
                ldx #$27
            !:
                lda titlename3,x
                sta TITLE_START + 80,x
                dex
                bpl !-  
        title4_draw:
                ldx #$27
            !:
                lda titlename4,x
                sta TITLE_START + 120,x
                dex
                bpl !-
        title5_draw:
                ldx #$27
            !:
                lda titlename5,x
                sta TITLE_START + 160,x
                dex
                bpl !-

        instruction_draw:
                ldx #$27
            !:
                lda titleinstruction,x
                sta $0680,x
                dex
                bpl !-    
        credit_draw:
                ldx #$27
            !:
                lda titlecredit,x
                sta $798,x
                dex
                bpl !-   

                rts
    }

    debug_number: {

        clc
        adc #48
        sta SCREEN_RAM + 40
        rts

    }

}

// INTERRUPTS
INTERRUPTS: {
    
    init:
        sei
        
        lda #%01111111
        sta INTERRUPT_REG
        lda RASTER_LINE_MSB
        and #%01111111
        sta RASTER_LINE_MSB
        
        lda #66
        sta RASTER_LINE
        lda #<lane1
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane1
        sta INTERRUPT_EXECUTION_HIGH

        lda INTERRUPT_ENABLE
        ora #%00000001 
        sta INTERRUPT_ENABLE

        cli

        rts

    lane1:
        lda selected_lane
        cmp #$01
        bne !+
        ldx #WHITE
        jmp lane1_draw
    !:
        ldx lanecolors + 4
    lane1_draw:
        lda RASTER_LINE
        cmp #68
        bne lane1_draw
        stx SCREEN_COLOR

        lda #LANE_1_Y
        sta SPRITE_1_Y

        lda #69
        sta SPRITE_2_Y
        lda #89
        sta SPRITE_3_Y

        lda #BLUE
        sta SPRITE_COLOR_0
        sta SPRITE_COLOR_2
        sta SPRITE_COLOR_3

        lda #110
        sta RASTER_LINE
        lda #<lane2
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane2
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge

    lane2:
        lda selected_lane
        cmp #$02
        bne !+
        ldx #WHITE
        jmp lane2_draw
    !:
        ldx lanecolors + 1
    lane2_draw:
        lda RASTER_LINE
        cmp #113
        bne lane2_draw
        stx SCREEN_COLOR

        lda #LANE_2_Y
        sta SPRITE_1_Y

        lda #115
        sta SPRITE_2_Y
        lda #135
        sta SPRITE_3_Y

        lda #PURPLE
        sta SPRITE_COLOR_0
        sta SPRITE_COLOR_2
        sta SPRITE_COLOR_3

        lda #157
        sta RASTER_LINE
        lda #<lane3
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane3
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge

    lane3:
        lda selected_lane
        cmp #$02
        bne !+
        ldx #WHITE
        jmp lane3_draw
    !:
        ldx lanecolors + 2
    lane3_draw:
        lda RASTER_LINE
        cmp #159
        bne lane3_draw
        stx SCREEN_COLOR
        
        lda #LANE_3_Y
        sta SPRITE_1_Y

        lda #161
        sta SPRITE_2_Y
        lda #181
        sta SPRITE_3_Y

        lda #LIGHT_RED
        sta SPRITE_COLOR_0
        sta SPRITE_COLOR_2
        sta SPRITE_COLOR_3
        
        lda #203
        sta RASTER_LINE
        lda #<lane4
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane4
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge

    lane4:
        lda selected_lane
        cmp #$02
        bne !+
        ldx #WHITE
        jmp lane4_draw
    !:
        ldx lanecolors + 3
    lane4_draw:
        lda RASTER_LINE
        cmp #205
        bne lane4_draw
        stx SCREEN_COLOR

        lda #LANE_4_Y
        sta SPRITE_1_Y

        lda #207
        sta SPRITE_2_Y
        lda #227
        sta SPRITE_3_Y

        lda #CYAN
        sta SPRITE_COLOR_0
        sta SPRITE_COLOR_2
        sta SPRITE_COLOR_3

        lda #250
        sta RASTER_LINE
        lda #<finish
        sta INTERRUPT_EXECUTION_LOW
        lda #>finish
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge 


    finish:
        lda #$01
        sta mainloop_flag
        
        ldx #BLACK
        lda RASTER_LINE
        cmp #252
        bne finish
        stx SCREEN_COLOR
        
        lda #66
        sta RASTER_LINE
        lda #<lane1
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane1
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge 

    acknowledge:
        dec INTERRUPT_STATUS
        jmp SYS_IRQ_HANDLER
}

// SPRITE STORAGE
*= $3200 "Sprites"
.import binary "assets/bin/sprites.bin"