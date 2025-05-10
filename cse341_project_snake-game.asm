.model small
.stack 100h

.data
    ; Snake data
    snake_x db 100 dup(0)     ; Snake body X positions
    snake_y db 100 dup(0)     ; Snake body Y positions
    snake_length db 1
    head_x db 20
    head_y db 10
    tail_x db ?
    tail_y db ?
    
    ; Game state
    direction db 0            ; 0=right, 1=left, 2=down, 3=up
    new_direction db 0
    food_x db 30
    food_y db 12
    score dw 0
    high_score dw 0
    delay_time dw 3           ; Game speed (lower = faster) - number of timer ticks to wait
    game_over_flag db 0
    
    ; Timer variables 
    last_tick dw 0            ; Last recorded timer tick
    
    ; Constants
    SCREEN_WIDTH equ 80
    SCREEN_HEIGHT equ 25
    GAME_WIDTH equ 40
    GAME_HEIGHT equ 20
    BORDER_COLOR equ 09h      ; Blue
    SNAKE_HEAD_COLOR equ 0Fh  ; White
    SNAKE_BODY_COLOR equ 0Ah  ; Green
    FOOD_COLOR equ 0Ch        ; Red
    TITLE_COLOR equ 0Eh       ; Yellow
    TEXT_COLOR equ 07h        ; Light gray
    
    ; Messages
    msg_score db 'Score: $'
    msg_high_score db 'High Score: $'
    msg_game_over db 'GAME OVER! Press any key...$'
    debug_move db 'Moving: $'
    
    ; Welcome screen messages
    welcome_title db '======= SNAKE GAME =======$'
    welcome_instructions db 'Instructions:$'
    welcome_controls1 db '- Use W,A,S,D or Arrow Keys to move the snake$'
    welcome_controls2 db '- Eat food to grow longer and earn points$'
    welcome_controls3 db '- Avoid hitting walls or yourself$'
    welcome_controls4 db '- Press ESC at any time to exit the game$'
    welcome_controls5 db '- Game speed increases as you score points$'
    welcome_prompt db 'Press any key to start...$'
    welcome_author db 'Assembly Snake Game v1.0$ By Ullahel Mahi'

.code
start:
    mov ax, @data
    mov ds, ax
    
    ; Set video mode
    call set_video_mode
    
    ; Display welcome screen
    call show_welcome_screen
    
    ; Wait for keypress to start the game
    mov ah, 00h
    int 16h
    
    ; Initialize game
    call init_game
    
    ; Get initial timer tick for timing
    call get_timer_tick
    mov last_tick, dx
    
    ; Main game loop
    game_loop:
        ; Check if it's time to update the game
        call check_timer
        cmp al, 1
        jne skip_update
        
        ; Update game
        call update_game
        
        ; Check if game is over
        cmp game_over_flag, 1
        je game_loop_end
        
    skip_update:
        ; Always handle input (even between game updates)
        call handle_input
        
        ; Allow for other interrupts and keep CPU usage reasonable
        mov ah, 1
        int 16h        ; Check if a key is available
        jnz game_loop  ; If yes, continue immediately to handle it
        
        ; Small delay to prevent hogging CPU
        mov cx, 1
    short_delay:
        nop
        loop short_delay
        
        jmp game_loop
    game_loop_end:
    
    ; Game over screen
    call show_game_over
    
    ; Exit to DOS
    mov ax, 4C00h
    int 21h

; === Welcome Screen ===
show_welcome_screen proc
    ; Clear screen
    call clear_screen
    
    ; Draw border for welcome screen
    call draw_welcome_border
    
    ; Display title
    mov dh, 3
    mov dl, 27
    call set_cursor
    mov bl, TITLE_COLOR
    lea dx, welcome_title
    call print_colored_text
    
    ; Display instructions header
    mov dh, 6
    mov dl, 20
    call set_cursor
    mov bl, TEXT_COLOR
    lea dx, welcome_instructions
    call print_colored_text
    
    ; Display control instructions
    mov dh, 8
    mov dl, 10
    call set_cursor
    lea dx, welcome_controls1
    call print_colored_text
    
    mov dh, 9
    mov dl, 10
    call set_cursor
    lea dx, welcome_controls2
    call print_colored_text
    
    mov dh, 10
    mov dl, 10
    call set_cursor
    lea dx, welcome_controls3
    call print_colored_text
    
    mov dh, 11
    mov dl, 10
    call set_cursor
    lea dx, welcome_controls4
    call print_colored_text
    
    mov dh, 12
    mov dl, 10
    call set_cursor
    lea dx, welcome_controls5
    call print_colored_text
    
    ; Display start prompt
    mov dh, 16
    mov dl, 27
    call set_cursor
    mov bl, TITLE_COLOR
    lea dx, welcome_prompt
    call print_colored_text
    
    ; Display author/version
    mov dh, 20
    mov dl, 30
    call set_cursor
    mov bl, TEXT_COLOR
    lea dx, welcome_author
    call print_colored_text
    
    ; Display snake graphics as decoration
    call draw_welcome_snake
    
    ret
show_welcome_screen endp

; === Welcome Screen Decoration ===
draw_welcome_border proc
    ; Draw single-line border
    mov ah, 09h
    mov bh, 0
    mov bl, BORDER_COLOR
    mov cx, 1
    
    ; Top border
    mov dh, 1
    mov dl, 5
    call set_cursor
    mov al, 0DAh      ; Top-left corner
    int 10h
    
    mov dl, 74
    call set_cursor
    mov al, 0BFh      ; Top-right corner
    int 10h
    
    mov dh, 1
    mov dl, 6
    call set_cursor
    mov cx, 68
    mov al, 0C4h      ; Horizontal line
    int 10h
    
    ; Bottom border
    mov dh, 22
    mov dl, 5
    call set_cursor
    mov al, 0C0h      ; Bottom-left corner
    mov cx, 1
    int 10h
    
    mov dl, 74
    call set_cursor
    mov al, 0D9h      ; Bottom-right corner
    int 10h
    
    mov dh, 22
    mov dl, 6
    call set_cursor
    mov cx, 68
    mov al, 0C4h      ; Horizontal line
    int 10h
    
    ; Left and right borders
    mov cx, 1
    mov al, 0B3h      ; Vertical line
    mov dh, 2
draw_welcome_vertical_border:
    ; Left border
    mov dl, 5
    call set_cursor
    int 10h
    
    ; Right border
    mov dl, 74
    call set_cursor
    int 10h
    
    inc dh
    cmp dh, 22
    jl draw_welcome_vertical_border
    
    ret
draw_welcome_border endp

; Draw a decorative snake on the welcome screen
draw_welcome_snake proc
    push ax
    push bx
    push cx
    push dx
    
    ; Draw snake head
    mov ah, 09h
    mov bh, 0
    mov bl, SNAKE_HEAD_COLOR
    mov cx, 1
    mov al, 01h       ; Smiley face
    
    mov dh, 15
    mov dl, 50
    call set_cursor
    int 10h
    
    ; Draw snake body
    mov bl, SNAKE_BODY_COLOR
    mov al, 0FEh      ; Block character
    
    mov dh, 15
    mov dl, 49
    call set_cursor
    int 10h
    
    mov dh, 15
    mov dl, 48
    call set_cursor
    int 10h
    
    mov dh, 15
    mov dl, 47
    call set_cursor
    int 10h
    
    mov dh, 15
    mov dl, 46
    call set_cursor
    int 10h
    
    ; Draw food
    mov bl, FOOD_COLOR
    mov al, 04h       ; Diamond character
    
    mov dh, 15
    mov dl, 55
    call set_cursor
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_welcome_snake endp

print_colored_text proc
    push ax
    
    mov ah, 09h
    int 21h
    
    pop ax
    ret
print_colored_text endp

; === Game Update Function ===
update_game proc
    ; Game logic
    call update_snake
    call check_collisions
    call check_food_collision
    
    ; Rendering
    call draw_game
    
    ret
update_game endp

; === Timer Functions ===
get_timer_tick proc
    push ax
    push cx
    
    mov ah, 00h       ; Get system time
    int 1Ah           ; CX:DX = number of clock ticks since midnight
    
    pop cx
    pop ax
    ret               ; Return value in DX
get_timer_tick endp

check_timer proc
    push bx
    push cx
    
    ; Get current timer tick
    call get_timer_tick
    
    ; Check if enough time has passed
    mov bx, last_tick
    
    ; Calculate elapsed time (DX - BX)
    sub dx, bx
    
    ; If result is negative (midnight passed), always update
    jl update_timer
    
    ; Compare with delay time
    cmp dx, delay_time
    jl no_update
    
update_timer:
    ; Update last_tick
    call get_timer_tick
    mov last_tick, dx
    
    ; Return 1 in AL to indicate update needed
    mov al, 1
    jmp check_timer_done
    
no_update:
    ; Return 0 in AL to indicate no update needed
    mov al, 0
    
check_timer_done:
    pop cx
    pop bx
    ret
check_timer endp

; === Game Initialization ===
init_game proc 
    call clear_screen
    call draw_borders
    call draw_score
    
    ; Initialize snake positions (start with a 3-segment snake)
    mov snake_x[0], 20
    mov snake_y[0], 10
    mov head_x, 20
    mov head_y, 10
    
    ; Create initial snake body segments
    mov snake_x[1], 19
    mov snake_y[1], 10
    mov snake_x[2], 18
    mov snake_y[2], 10
    mov snake_length, 3
    
    ; Save initial tail position
    mov al, snake_x[2]
    mov tail_x, al
    mov al, snake_y[2]
    mov tail_y, al
    
    ; Clear remaining positions
    mov cx, 97
    mov si, 3
clear_snake:
    mov snake_x[si], 0
    mov snake_y[si], 0
    inc si
    loop clear_snake
    
    ; Initialize direction (start moving right)
    mov direction, 0
    mov new_direction, 0
    
    ; Reset score and game speed
    mov score, 0
    mov delay_time, 3  ; Reset to initial speed (3 timer ticks)
    mov game_over_flag, 0
    
    ; Place first food
    call place_food
    
    ; Draw initial game state
    call draw_game
    
    ret
init_game endp

; === Input Handling ===
handle_input proc
    ; Check for key press
    mov ah, 01h
    int 16h
    jz no_key_pressed
    
    ; Get key
    mov ah, 00h
    int 16h
    
    ; Handle key (check for both lowercase and uppercase)
    cmp al, 'w'
    je set_up
    cmp al, 'W'
    je set_up
    cmp al, 's'
    je set_down
    cmp al, 'S'
    je set_down
    cmp al, 'a'
    je set_left
    cmp al, 'A'
    je set_left
    cmp al, 'd'
    je set_right
    cmp al, 'D'
    je set_right
    ; Also support arrow keys
    cmp ah, 48h  ; Up arrow (scan code)
    je set_up
    cmp ah, 50h  ; Down arrow
    je set_down
    cmp ah, 4Bh  ; Left arrow
    je set_left
    cmp ah, 4Dh  ; Right arrow
    je set_right
    cmp al, 27    ; ESC key
    je exit_game
    jmp no_key_pressed
    
set_up:
    ; Cannot go up if currently going down (no reversal)
    cmp direction, 2
    je no_key_pressed
    mov new_direction, 3
    jmp key_processed
    
set_down:
    ; Cannot go down if currently going up
    cmp direction, 3
    je no_key_pressed
    mov new_direction, 2
    jmp key_processed
    
set_left:
    ; Cannot go left if currently going right
    cmp direction, 0
    je no_key_pressed
    mov new_direction, 1
    jmp key_processed
    
set_right:
    ; Cannot go right if currently going left
    cmp direction, 1
    je no_key_pressed
    mov new_direction, 0
    jmp key_processed

key_processed:
    ; Clear keyboard buffer to prevent queuing up moves
    mov ah, 0Ch
    mov al, 0
    int 21h
    
exit_game:
    cmp al, 27    ; ESC key
    jne no_key_pressed
    mov game_over_flag, 1
    
no_key_pressed:
    ret
handle_input endp

; === Game Logic ===
update_snake proc
    ; Update direction from new_direction
    mov al, new_direction
    mov direction, al
    
    ; Only save tail if length > 1
    cmp snake_length, 1
    jle move_head_only
    
    ; Save tail position (last element in arrays)
    xor ah, ah
    mov al, snake_length
    dec ax
    mov si, ax
    mov al, snake_x[si]
    mov tail_x, al
    mov al, snake_y[si]
    mov tail_y, al
    
    ; Move body segments from tail towards head
    xor ch, ch
    mov cl, snake_length
    dec cl      ; number of segments to move
    mov si, cx  ; start from tail
    
move_body:
    ; Move each segment to follow the one before it
    mov al, snake_x[si-1]
    mov snake_x[si], al
    mov al, snake_y[si-1]
    mov snake_y[si], al
    
    dec si
    jnz move_body  ; Continue until we reach head (index 0)

move_head_only:
    ; Move head based on direction
    cmp direction, 0
    je move_right
    cmp direction, 1
    je move_left
    cmp direction, 2
    je move_down
    cmp direction, 3
    je move_up
    jmp update_head

move_right:
    inc head_x
    jmp update_head
move_left:
    dec head_x
    jmp update_head
move_down:
    inc head_y
    jmp update_head
move_up:
    dec head_y

update_head:
    ; Update head position in array
    mov al, head_x
    mov snake_x[0], al
    mov al, head_y
    mov snake_y[0], al
    
    ret
update_snake endp

check_collisions proc
    ; Check wall collision
    cmp head_x, 1
    jl collision
    cmp head_x, GAME_WIDTH-2
    jg collision
    cmp head_y, 1
    jl collision
    cmp head_y, GAME_HEIGHT-1
    jg collision
    
    ; Check self collision (skip head)
    xor ch, ch
    mov cl, snake_length
    cmp cl, 1
    jle no_collision
    mov si, 1
check_self:
    mov al, snake_x[si]
    cmp al, head_x
    jne next_segment
    mov al, snake_y[si]
    cmp al, head_y
    je collision
next_segment:
    inc si
    loop check_self
    
no_collision:
    ret
    
collision:
    mov game_over_flag, 1
    ret
check_collisions endp

check_food_collision proc
    mov al, head_x
    cmp al, food_x
    jne no_food
    
    mov al, head_y
    cmp al, food_y
    jne no_food
    
    ; Snake ate food - increase length and score
    inc snake_length
    add score, 10
    
    ; Update high score if needed
    mov ax, score
    cmp ax, high_score
    jle no_high_score
    mov high_score, ax
no_high_score:
    
    ; Increase speed (up to a point)
    cmp delay_time, 1
    jbe no_speed_increase
    dec delay_time
no_speed_increase:
    
    ; Place new food
    call place_food
    
    ; Update score display
    call draw_score
    
no_food:
    ret
check_food_collision endp

; === Food Placement ===
place_food proc
    push bx
    push cx
    
try_again:
    ; Random X position (1 to GAME_WIDTH-2)
    call random_byte
    xor ah, ah
    mov bl, GAME_WIDTH-2
    div bl
    mov al, ah
    inc al
    mov food_x, al
    
    ; Random Y position (1 to GAME_HEIGHT-1)
    call random_byte
    xor ah, ah
    mov bl, GAME_HEIGHT-1
    div bl
    mov al, ah
    inc al
    mov food_y, al
    
    ; Check if food is on snake
    xor ch, ch
    mov cl, snake_length
    mov si, 0
check_snake:
    mov al, snake_x[si]
    cmp al, food_x
    jne next_segment_check
    mov al, snake_y[si]
    cmp al, food_y
    je try_again      ; Food on snake, try again
next_segment_check:
    inc si
    loop check_snake
    
    pop cx
    pop bx
    ret
place_food endp

random_byte proc
    mov ah, 00h       ; BIOS get system time
    int 1Ah
    mov al, dl        ; Use lower byte of timer
    xor al, dh        ; Mix with higher byte
    ret
random_byte endp

; === Rendering ===
set_video_mode proc
    mov ah, 00h
    mov al, 03h      ; 80x25 text mode
    int 10h
    
    ; Hide cursor
    mov ah, 01h
    mov ch, 20h      ; Make cursor invisible
    int 10h
    ret
set_video_mode endp

clear_screen proc
    mov ax, 0600h    ; Clear screen
    mov bh, 07h      ; White on black
    mov cx, 0        ; Upper left corner
    mov dx, 184Fh    ; Lower right corner
    int 10h
    
    mov ah, 02h      ; Set cursor position
    mov bh, 00h      ; Page 0
    mov dx, 0        ; Row 0, column 0
    int 10h
    ret
clear_screen endp

draw_borders proc
    ; Top border
    mov dh, 0
    mov dl, 0
    call set_cursor
    mov cx, GAME_WIDTH
    mov al, 0C4h      ; Horizontal line character
    call print_char_repeat
    
    ; Bottom border
    mov dh, GAME_HEIGHT
    mov dl, 0
    call set_cursor
    mov cx, GAME_WIDTH
    mov al, 0C4h
    call print_char_repeat
    
    ; Left and right borders
    mov cx, GAME_HEIGHT-1
    mov dh, 1
draw_vertical:
    ; Left border
    mov dl, 0
    call set_cursor
    mov al, 0B3h      ; Vertical line character
    call print_char
    
    ; Right border
    mov dl, GAME_WIDTH-1
    call set_cursor
    mov al, 0B3h
    call print_char
    
    inc dh
    loop draw_vertical
    
    ; Corners
    mov dh, 0
    mov dl, 0
    call set_cursor
    mov al, 0DAh      ; Top-left corner
    call print_char
    
    mov dl, GAME_WIDTH-1
    call set_cursor
    mov al, 0BFh      ; Top-right corner
    call print_char
    
    mov dh, GAME_HEIGHT
    mov dl, 0
    call set_cursor
    mov al, 0C0h      ; Bottom-left corner
    call print_char
    
    mov dl, GAME_WIDTH-1
    call set_cursor
    mov al, 0D9h      ; Bottom-right corner
    call print_char
    
    ret
draw_borders endp

draw_game proc
    ; Debug - always draw initial snake position
    mov al, snake_length
    cmp al, 0
    jne continue_draw
    
    ; If snake length is 0, set it to 1 and initialize position
    mov snake_length, 1
    mov snake_x[0], 20
    mov snake_y[0], 10
    mov head_x, 20
    mov head_y, 10
    
continue_draw:
    ; Erase tail if snake moved and length > 1
    cmp snake_length, 1
    jle draw_head
    
    mov dh, tail_y
    mov dl, tail_x
    call set_cursor
    mov al, ' '
    call print_char
    
draw_head:
    ; Draw head
    mov dh, head_y
    mov dl, head_x
    call set_cursor
    mov al, 01h      ; Smiley face for head
    mov bl, SNAKE_HEAD_COLOR
    call print_colored_char
    
    ; Draw body (skip head if length = 1)
    xor ch, ch
    mov cl, snake_length
    cmp cl, 0
    jle draw_food
    mov si, 1
draw_body:
    mov dh, snake_y[si]
    mov dl, snake_x[si]
    call set_cursor
    mov al, 0FEh      ; Block character for body
    mov bl, SNAKE_BODY_COLOR
    call print_colored_char
    inc si
    dec cx
    jnz draw_body
    
draw_food:
    ; Draw food
    mov dh, food_y
    mov dl, food_x
    call set_cursor
    mov al, 04h      ; Diamond character for food
    mov bl, FOOD_COLOR
    call print_colored_char
    
    ret
draw_game endp

draw_score proc
    ; Draw score at top right
    mov dh, 0
    mov dl, GAME_WIDTH + 2
    call set_cursor
    
    lea dx, msg_score
    mov ah, 09h
    int 21h
    
    mov ax, score
    call print_number
    
    ; Draw high score below it
    mov dh, 1
    mov dl, GAME_WIDTH + 2
    call set_cursor
    
    lea dx, msg_high_score
    mov ah, 09h
    int 21h
    
    mov ax, high_score
    call print_number
    
    ret
draw_score endp

; === Utility Functions ===
set_cursor proc
    mov ah, 02h
    mov bh, 00h
    int 10h
    ret
set_cursor endp

print_char proc
    mov ah, 09h
    mov bh, 00h
    mov bl, BORDER_COLOR
    mov cx, 1
    int 10h
    ret
print_char endp

print_char_repeat proc
    mov ah, 09h
    mov bh, 00h
    mov bl, BORDER_COLOR
    int 10h
    ret
print_char_repeat endp

print_colored_char proc
    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h
    ret
print_colored_char endp

print_number proc
    ; Prints the number in AX
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor cx, cx
    
    ; Push digits onto stack
extract_digits:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz extract_digits
    
    ; Print digits
print_digits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_digits
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

; === Game Over Screen ===
show_game_over proc
    ; Clear screen
    call clear_screen
    
    ; Show game over message
    mov dh, 12
    mov dl, 30
    call set_cursor
    
    lea dx, msg_game_over
    mov ah, 09h
    int 21h
    
    ; Show final score
    mov dh, 14
    mov dl, 30
    call set_cursor
    
    lea dx, msg_score
    mov ah, 09h
    int 21h
    
    mov ax, score
    call print_number
    
    ; Wait for key press
    mov ah, 00h
    int 16h
    
    ret
show_game_over endp

end start