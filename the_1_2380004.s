PROCESSOR 18F8722
    
#include <xc.inc>

; configurations
CONFIG OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

; global variable declarations

GLOBAL _t1, _t2, _t3    ; variables for time delay
GLOBAL led_flag, port_selection, b_val, c_val, d_val, re4_label, ra4_label ,light, is_finished, c_mul, b_mul    ; state of LEDs

; allocate memory in data bank for variables
PSECT udata_acs
    led_flag:
        DS 1    ; allocate 1 byte
    _t1:
        DS 1    ; allocate 1 byte
    _t2:
        DS 1    ; allocate 1 byte
    _t3:
        DS 1    ; allocate 1 byte
    port_selection:
	DS 1
    b_val:
	DS 1
    c_val:
	DS 1
    re4_label:
	DS 1
    ra4_label:
	DS 1
    light:
	DS 1
    is_finished:
	DS 1
    c_mul:
	DS 1
    b_mul:
	DS 1
    d_val:
	DS 1
	

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    main

; DO NOT DELETE OR MODIFY
; 500ms pass check for test scripts
ms500_passed:
    nop
    return

; DO NOT DELETE OR MODIFY
; 1sec pass check for test scripts
ms1000_passed:
    nop
    return
    
    
busy_delay_1sec:
    movlw 0x84      ; copy desired value to W
    movwf _t3       ; copy W into t3
    _loop3:
        movlw 0xAF      ; copy desired value to W
        movwf _t2       ; copy W into t2
        _loop2:
            movlw 0x8F      ; copy desired value to W
            movwf _t1       ; copy W into t1
            _loop1:
                decfsz _t1, 1   ; decrement t1, if 0 skip next 
                goto _loop1     ; else keep counting down
                decfsz _t2, 1   ; decrement t2, if 0 skip next 
                goto _loop2     ; else keep counting down
                decfsz _t3, 1   ; decrement t3, if 0 skip next 
                goto _loop3     ; else keep counting down
                return 
		
non_busy_delay_500ms:
    movlw 0x42      ; copy desired value to W
    movwf _t3       ; copy W into t3
    _loop6:
        movlw 0x35      ; copy desired value to W
        movwf _t2       ; copy W into t2
        _loop5:
            movlw 0x20      ; copy desired value to W
            movwf _t1       ; copy W into t1
            _loop4:
		call check_buttons
		BTFSC is_finished, 0
		return
                decfsz _t1, 1   ; decrement t1, if 0 skip next 
                goto _loop4     ; else keep counting down
                decfsz _t2, 1   ; decrement t2, if 0 skip next 
                goto _loop5     ; else keep counting down
                decfsz _t3, 1   ; decrement t3, if 0 skip next 
                goto _loop6     ; else keep counting down
		call increment_port
                return
		
busy_delay_500ms:
    movlw 0x42      ; copy desired value to W
    movwf _t3       ; copy W into t3
    _loop9:
        movlw 0xAF      ; copy desired value to W
        movwf _t2       ; copy W into t2
        _loop8:
            movlw 0x88      ; copy desired value to W
            movwf _t1       ; copy W into t1
            _loop7:
                decfsz _t1, 1   ; decrement t1, if 0 skip next 
                goto _loop7     ; else keep counting down
                decfsz _t2, 1   ; decrement t2, if 0 skip next 
                goto _loop8     ; else keep counting down
                decfsz _t3, 1   ; decrement t3, if 0 skip next 
                goto _loop9     ; else keep counting down
                return
		

		



check_buttons:
    BTFSC is_finished, 0
    return
    call check_re4
    movlw 00001000B
    cpfseq port_selection
    goto not_countdown
    call countdown
    return
    
    not_countdown:
	call check_ra4
	
check_ra4:
    BTFSC PORTA, 4
    goto ra4_one
    goto ra4_zero
    
    ra4_one:
	tstfsz ra4_label
	return
	INCF ra4_label
	return
	
    ra4_zero:
	tstfsz ra4_label
	call increment_value
	clrf ra4_label
	return
	
check_re4:
    BTFSC PORTE, 4
    goto re4_one
    goto re4_zero
    
    re4_one:
	tstfsz re4_label
	return
	INCF re4_label
	return
	
    re4_zero:
	tstfsz re4_label
	RLNCF port_selection
	clrf re4_label
	return

increment_port:
    clrf ra4_label
    BTFSC port_selection, 0
    return
    BTFSC port_selection, 2
    goto c_blink
    goto b_blink
    
    
    b_blink:
	BTFSC light, 0
	goto light_led_b
	clrf LATB
	INCF light
	return
	light_led_b:
	movf b_val, 0
	movwf LATB
	clrf light
	return

    c_blink:
	movff b_val, LATB
	BTFSC light, 0
	goto light_led_c
	clrf LATC
	INCF light
	return
	light_led_c:
	movf c_val, 0
	movwf LATC
	clrf light
	return
	
    
increment_value:
    clrf re4_label
    BTFSC port_selection, 1
    goto b_inc
    goto c_inc
    
    
    b_inc:
	INCF b_mul
	RLNCF b_val
	INCF b_val
	BTFSS b_val, 4
	return
	movlw 00000001B
	movwf b_mul
	movwf b_val
	return
	
    c_inc:
        INCF c_mul
	RLNCF c_val
	BTFSS c_val, 2
	return
	movlw 00000001B
	movwf c_mul
	movwf c_val
	return

	
countdown:
    movf b_mul, 0
    mulwf c_mul
    movff c_val, LATC
    movff b_val, LATB
    
    loop_mul:
	RLNCF d_val
        INCF d_val
	decf PRODL
	TSTFSZ PRODL
	goto loop_mul
	movff d_val, LATD
    
	
    loop_c:
	call busy_delay_500ms
	call ms500_passed
	decf d_val
	RRNCF d_val
	movff d_val, LATD
	TSTFSZ LATD
	goto loop_c
	btg is_finished, 0
	call busy_delay_500ms
	return
	
    
PSECT CODE
main:
    ; some code to initialize and wait 1000ms here, maybe
    movlw 00000000B
    movwf TRISB
    movwf TRISC
    movwf TRISD
    movlw 00010000B
    movwf TRISA
    movwf TRISE
    movlw 00000011B
    movwf LATC
    movlw 00001111B
    movwf LATB
    movlw 11111111B
    movwf LATD
    clrf port_selection
    movlw 00000001B
    movwf port_selection
    movwf c_val
    movwf b_val
    clrf LATA
    clrf LATE
    clrf d_val
    call busy_delay_1sec
    call ms1000_passed

    default:
    clrf light
    clrf is_finished
    clrf re4_label
    clrf ra4_label
    movlw 00000001B
    movwf port_selection
    movwf c_val
    movwf b_val
    movwf c_mul
    movwf b_mul
    movwf LATB
    movwf LATC
    movlw 00000000B
    movwf LATD
    ; a loop here, maybe
    loop:
	call non_busy_delay_500ms
	call ms500_passed
	BTFSS is_finished, 0
	goto loop
	btg is_finished, 0
	goto default

end resetVec


