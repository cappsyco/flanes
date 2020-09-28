#import "references/vic2constants.asm"
#import "references/generalconstants.asm"

// OPTIONS
.var BLOCK_SPEED = 2

BasicUpstart2(main)

*= $1000 "Main Program"

// VARIABLES
lane_rnd: .byte 1
block_rnd: .byte 3

title1: .text "                 flanes                 "
title2: .text "         press 'fire' to start!         "
title3: .text "        by jonathan capps (2020)        "

selected_lane: .byte 0
active_lane: .byte 0
active_lane_movement: .byte 0

lane1_shape_x: .byte 0,0
lane2_shape_x: .byte 0,0
lane3_shape_x: .byte 0,0
lane4_shape_x: .byte 0,0

// MAIN PROGRAM
main: {
    title: {
        // screen setup
        jsr screen.clear
        jsr screen.text_color
        jsr title_text

        // wait for space press
        !:
            lda PORT_REG_B
            cmp #$ef
            bne !-
    }

    game: {
        // game setup
        jsr interrupts.init
        jsr screen.clear
        jsr player.setup
        jsr shapes.setup

        // main loop
        !: 
            
            // FIX RANDOMISATION
            lr:
                inc lane_rnd
                lda lane_rnd
                cmp #5
                bne br
                lda #1
                sta lane_rnd
            br:
                inc block_rnd
                lda block_rnd
                cmp #5
                bne main
                lda #1
                sta block_rnd
            
            main:
                // wait for raster line
                lda RASTER_LINE
                cmp #$ff
                bne !-
                    
                jsr shapes.move
                jsr shapes.draw
                jsr shapes.randomise
                jsr player.key_check
                
                // wait for raster line
                lda RASTER_LINE
                cmp #$80
                bne !-
                
                jmp !-
    }

}

// PLAYER
player: {

    setup: {
        
        lda #%11111111
        sta DD_REG_A
        
        lda #%00000000
        sta DD_REG_B

        lda #%11111110
        sta PORT_REG_A

        rts
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
            rts
        end_nopress:
            lda #$00
            sta selected_lane
            rts
    }

}

// SPIKES
shapes: {

    setup: {

        // placeholder shapes
        lda #201
        sta SPRITE_POINTER_0
        lda #203
        sta SPRITE_POINTER_1
        lda #205
        sta SPRITE_POINTER_2
        lda #207
        sta SPRITE_POINTER_3

        // solid shapes
        lda #200
        sta SPRITE_POINTER_4
        lda #202
        sta SPRITE_POINTER_5
        lda #204
        sta SPRITE_POINTER_6
        lda #206
        sta SPRITE_POINTER_7

        lda #BLACK
        sta SPRITE_COLOR_0
        sta SPRITE_COLOR_1
        sta SPRITE_COLOR_2
        sta SPRITE_COLOR_3
        sta SPRITE_COLOR_4
        sta SPRITE_COLOR_5
        sta SPRITE_COLOR_6
        sta SPRITE_COLOR_7

        lda #%00000000
        sta SPRITE_DOUBLE_X
        sta SPRITE_DOUBLE_Y
        
        lda #%00000000
        sta SPRITE_MODE

        lda #120
        sta SPRITE_0_X
        lda #180
        sta SPRITE_1_X
        lda #240
        sta SPRITE_2_X
        lda #45
        sta SPRITE_3_X
        lda #%00001000
        sta SPRITE_MSB_X

        // temp positions for testing movement
        lda #0
        sta SPRITE_4_X
        sta SPRITE_5_X
        sta SPRITE_6_X
        sta SPRITE_7_X
        lda #65
        sta SPRITE_4_Y
        lda #115
        sta SPRITE_5_Y
        lda #165
        sta SPRITE_6_Y
        lda #215
        sta SPRITE_7_Y

        lda #%11111111
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
            lda lane_rnd
            sta active_lane
            
        move_active:
            lda active_lane
            cmp #1
            beq move_1_x
            cmp #2
            beq move_2_x
            cmp #3
            beq move_3_x
            cmp #4
            beq move_4_x        
        
        move_1_x:
            clc
            lda lane1_shape_x
            adc #BLOCK_SPEED
            sta lane1_shape_x
            bcc move_end
            lda #BLOCK_SPEED
            sta lane1_shape_x + 1
            jmp move_end
        move_2_x:
            clc
            lda lane2_shape_x
            adc #BLOCK_SPEED
            sta lane2_shape_x
            bcc move_end
            lda #BLOCK_SPEED
            sta lane2_shape_x + 1
            jmp move_end
        move_3_x:
            clc
            lda lane3_shape_x
            adc #BLOCK_SPEED
            sta lane3_shape_x
            bcc move_end
            lda #BLOCK_SPEED
            sta lane3_shape_x + 1
            jmp move_end
        move_4_x:
            clc
            lda lane4_shape_x
            adc #BLOCK_SPEED
            sta lane4_shape_x
            bcc move_end
            lda #BLOCK_SPEED
            sta lane4_shape_x + 1
        
        move_end:
            rts
    }

    draw: {

        set_1_x:
            lda lane1_shape_x
            sta SPRITE_4_X
            lda lane1_shape_x + 1
            cmp #BLOCK_SPEED
            bne set_2_x
        set_1_high_x:
            lda lane1_shape_x
            cmp #100
            beq set_1_low_x
            lda SPRITE_MSB_X
            ora #%00010000
            jmp store_1_msb_x
        set_1_low_x:
            lda #00
            sta lane1_shape_x + 1
            sta lane1_shape_x
            lda #0
            sta active_lane_movement
            lda SPRITE_MSB_X
            and #%11101111
        store_1_msb_x:    
            sta SPRITE_MSB_X

        set_2_x:
            lda lane2_shape_x
            sta SPRITE_5_X
            lda lane2_shape_x + 1
            cmp #BLOCK_SPEED
            bne set_3_x
        set_2_high_x:
            lda lane2_shape_x
            cmp #100
            beq set_2_low_x
            lda SPRITE_MSB_X
            ora #%00100000
            jmp store_2_msb_x
        set_2_low_x:
            lda #00
            sta lane2_shape_x + 1
            sta lane2_shape_x
            lda #0
            sta active_lane_movement
            lda SPRITE_MSB_X
            and #%11011111
        store_2_msb_x:    
            sta SPRITE_MSB_X

        set_3_x:
            lda lane3_shape_x
            sta SPRITE_6_X
            lda lane3_shape_x + 1
            cmp #BLOCK_SPEED
            bne set_4_x
        set_3_high_x:
            lda lane3_shape_x
            cmp #100
            beq set_3_low_x
            lda SPRITE_MSB_X
            ora #%01000000
            jmp store_3_msb_x
        set_3_low_x:
            lda #00
            sta lane3_shape_x + 1
            sta lane3_shape_x
            lda #0
            sta active_lane_movement
            lda SPRITE_MSB_X
            and #%10111111
        store_3_msb_x:    
            sta SPRITE_MSB_X

        set_4_x:
            lda lane4_shape_x
            sta SPRITE_7_X
            lda lane4_shape_x + 1
            cmp #BLOCK_SPEED
            bne draw_end
        set_4_high_x:
            lda lane4_shape_x
            cmp #100
            beq set_4_low_x
            lda SPRITE_MSB_X
            ora #%10000000
            jmp store_4_msb_x
        set_4_low_x:
            lda #00
            sta lane4_shape_x + 1
            sta lane4_shape_x
            lda #0
            sta active_lane_movement
            lda SPRITE_MSB_X
            and #%01111111
        store_4_msb_x:    
            sta SPRITE_MSB_X
      
        draw_end:
            lda lane1_shape_x
            sta SPRITE_4_X
            lda lane2_shape_x
            sta SPRITE_5_X
            lda lane3_shape_x
            sta SPRITE_6_X
            lda lane4_shape_x
            sta SPRITE_7_X
              
            rts

    }

    randomise: {

        
        lda block_rnd
        cmp #1
        beq set_shape_2
        cmp #2
        beq set_shape_1
        cmp #3
        beq set_shape_4
        cmp #4
        beq set_shape_3
    
        set_shape_1:
            ldx #200
            jmp randomise_shape_1
        
        set_shape_2:
            ldx #202
            jmp randomise_shape_1
        
        set_shape_3:
            ldx #204
            jmp randomise_shape_1
        
        set_shape_4:
            ldx #206
            jmp randomise_shape_1

        randomise_shape_1:
            lda lane1_shape_x + 1
            cmp #0
            bne randomise_shape_2

            lda lane1_shape_x
            cmp #0
            bne randomise_shape_2
            stx SPRITE_POINTER_4

        randomise_shape_2:
            lda lane2_shape_x + 1
            cmp #0
            bne randomise_shape_3
            
            lda lane2_shape_x
            cmp #0
            bne randomise_shape_3
            stx SPRITE_POINTER_5

        randomise_shape_3:
            lda lane3_shape_x + 1
            cmp #0
            bne randomise_shape_4
            
            lda lane3_shape_x
            cmp #0
            bne randomise_shape_4
            stx SPRITE_POINTER_6

        randomise_shape_4:
            lda lane4_shape_x + 1
            cmp #0
            bne randomise_end
            
            lda lane4_shape_x
            cmp #0
            bne randomise_end
            stx SPRITE_POINTER_7

        randomise_end:
            rts

    }

}

// SCREEN OPERATIONS
screen: {
    clear: {
        lda #DARK_GRAY
        sta BORDER_COLOR
        lda #RED
        sta SCREEN_COLOR
        jsr CLEAR_SCREEN
        rts
    }
    text_color: {
            lda #WHITE
            ldx #0
        !:
            sta TXTCOLOR_START,x
            sta TXTCOLOR_START + 250,x
            sta TXTCOLOR_START + 500,x
            sta TXTCOLOR_START + 750,x
            inx
            cpx #250
            bne !-
            rts
        }
}

// TEXT DRAWING OPERATIONS
title_text: {

    line1_draw: {
            ldx #$00
            jmp !+
        !:
            lda title1,x
            sta $0590,x
            inx
            cpx #$28
            bne !-
            jmp line2_draw
    }
    line2_draw: {
            ldx #$00
            jmp !+
        !:
            lda title2,x
            sta $05e0,x
            inx
            cpx #$28
            bne !-
            jmp line3_draw
    }      
    line3_draw: {
            ldx #$00
            jmp !+
        !:
            lda title3,x
            sta $0798,x
            inx
            cpx #$28
            bne !-
    }
    rts
}

// INTERRUPTS
interrupts: {
    init:
        sei
        
        lda #%01111111
        sta INTERRUPT_REG
        lda INTERRUPT_ENABLE
        ora #%00000001 
        sta INTERRUPT_ENABLE
        lda RASTER_LINE_MSB
        and #%01111111
        sta RASTER_LINE_MSB
        
        lda #50
        sta RASTER_LINE
        lda #<lane1
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane1
        sta INTERRUPT_EXECUTION_HIGH

        cli

        rts

    lane1:

        lda #65
        sta SPRITE_0_Y
        sta SPRITE_1_Y
        sta SPRITE_2_Y
        sta SPRITE_3_Y
        
        ldx #YELLOW
        lda selected_lane
        cmp #$01
        bne !+

        ldx #WHITE
    !:
        stx SCREEN_COLOR
        lda #100
        sta RASTER_LINE
        lda #<lane2
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane2
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge

    lane2:

        lda #115
        sta SPRITE_0_Y
        sta SPRITE_1_Y
        sta SPRITE_2_Y
        sta SPRITE_3_Y

        ldx #GREEN
        lda selected_lane
        cmp #$02
        bne !+
        
        ldx #WHITE
    !:
        stx SCREEN_COLOR
        lda #150
        sta RASTER_LINE
        lda #<lane3
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane3
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge

    lane3:

        lda #165
        sta SPRITE_0_Y
        sta SPRITE_1_Y
        sta SPRITE_2_Y
        sta SPRITE_3_Y

        ldx #CYAN
        lda selected_lane
        cmp #$03
        bne !+
        
        ldx #WHITE
    !:
        stx SCREEN_COLOR
        lda #200
        sta RASTER_LINE
        lda #<lane4
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane4
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge

    lane4:
        //pha
        //txa 
        //pha
        //tya 
        //pha

        lda #215
        sta SPRITE_0_Y
        sta SPRITE_1_Y
        sta SPRITE_2_Y
        sta SPRITE_3_Y

        ldx #LIGHT_RED
        lda selected_lane
        cmp #$04
        bne !+
        
        ldx #WHITE
    !:
        stx SCREEN_COLOR
        lda #50
        sta RASTER_LINE
        lda #<lane1
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane1
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge 

    acknowledge:
        dec INTERRUPT_STATUS
        //pla 
        //tay 
        //pla 
        //tax 
        //pla
        jmp SYS_IRQ_HANDLER
}

// SPRITE STORAGE
*= $3200 "Sprites"
.import binary "assets/bin/sprites.bin"