#import "references/vic2constants.asm"
#import "references/generalconstants.asm"

BasicUpstart2(main)

*= $1000 "Main Program"

// MAIN PROGRAM
main: {
    title: {
        // screen setup
        jsr screen.clear

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
        jsr spikes.setup

        // main loop
        !:
            // wait for raster line
            lda RASTER_LINE
            cmp #$FF
            bne !-
            
            jsr player.key_check
            jsr spikes.move
            jmp !-
    }

}

// PLAYER
player: {

    selected_lane: .byte $00

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
spikes: {

    setup: {

        lda #200
        sta SPRITE_POINTER_0

        lda #BLACK
        sta SPRITE_COLOR_0

        lda #%00000000
        sta SPRITE_DOUBLE_X
        sta SPRITE_DOUBLE_Y
        
        lda #%00000000
        sta SPRITE_MODE

        lda #35
        sta SPRITE_0_X
        lda #65
        sta SPRITE_0_Y

        lda #%00000001
        sta SPRITE_ENABLE

        rts
    }

    animation: {
            inc delay_counter
            lda delay_counter
            cmp #1
            bne continue
            lda #0
            sta delay_counter
            ldx frame_counter
            cpx #8
            bne animation_draw
            ldx #0
            stx frame_counter
        animation_draw:
            lda animation_frames,x
            sta SPRITE_POINTER_0
            inc frame_counter
        continue:
            rts

        frame_counter:
            .byte $00
        delay_counter:
            .byte $00
        animation_frames:
            .byte 200,201,202,203,204,205,206,207
    }

    move: {

        inc SPRITE_0_X

    }

}

// SCREEN OPERATIONS
screen: {
    clear: {
        lda #DARK_GRAY
        sta BORDER_COLOR
        lda #BLACK
        sta SCREEN_COLOR
        jsr CLEAR_SCREEN
        rts
    }
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
        
        lda #00
        sta RASTER_LINE
        lda #<animations
        sta INTERRUPT_EXECUTION_LOW
        lda #>animations
        sta INTERRUPT_EXECUTION_HIGH

        cli

        rts

    animations:
        pha
        txa 
        pha
        tya 
        pha

        jsr spikes.animation

        lda #50
        sta RASTER_LINE
        lda #<lane1
        sta INTERRUPT_EXECUTION_LOW
        lda #>lane1
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge
        
    lane1:
        pha
        txa 
        pha
        tya 
        pha

        lda #65
        sta SPRITE_0_Y
        
        ldx #YELLOW
        lda player.selected_lane
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
        pha
        txa 
        pha
        tya 
        pha

        lda #115
        sta SPRITE_0_Y

        ldx #GREEN
        lda player.selected_lane
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
        pha
        txa 
        pha
        tya 
        pha

        lda #165
        sta SPRITE_0_Y

        ldx #CYAN
        lda player.selected_lane
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
        pha
        txa 
        pha
        tya 
        pha

        lda #215
        sta SPRITE_0_Y

        ldx #LIGHT_RED
        lda player.selected_lane
        cmp #$04
        bne !+
        
        ldx #WHITE
    !:
        stx SCREEN_COLOR
        lda #00
        sta RASTER_LINE
        lda #<animations
        sta INTERRUPT_EXECUTION_LOW
        lda #>animations
        sta INTERRUPT_EXECUTION_HIGH

        jmp acknowledge 

    acknowledge:
        dec INTERRUPT_STATUS
        pla 
        tay 
        pla 
        tax 
        pla

        jmp SYS_IRQ_HANDLER
}

// SPRITE STORAGE
*= $3200 "Sprites"
.import binary "assets/bin/sprites.bin"