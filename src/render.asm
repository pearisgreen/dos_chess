  include std.asm
  include tilem.asm
  include boardm.asm

  public draw_rect
  public draw_filled_rect
  public draw_board

  extrn tile_draw:proc

  extrn board_at_pos:proc
  extrn get_player:proc

  .data

  .code

switch_color macro
  local nblack, conn
  ;; set white or black
  cmp bx, 8
  jne nblack
  ;; else
  mov bx, 7
  jmp conn
nblack:
  mov bx, 8
conn:
  endm

;;; draw the chessboard
draw_board proc near
  entr 0

  disable_cursor

  ;; draw player indicator
  call get_player
  cmp ax, 0
  jne @@player_black

@@player_white:
  mov bh, tile_indicator_hw
  mov bl, tile_indicator_vw

  jmp @@done_player
@@player_black:
  mov bh, tile_indicator_hb
  mov bl, tile_indicator_vb

@@done_player:
  xor ax, ax

  mov al, bh
  mov cx, board_xpos + (board_width / 2) - (indicator_l / 2)
  mov dx, board_ypos - indicator_s
  push_args<ax, cx, dx>
  call tile_draw
  pop_args

  mov dx, board_ypos + board_height
  push_args<ax, cx, dx>
  call tile_draw
  pop_args

  mov al, bl
  mov cx, board_xpos - indicator_s
  mov dx, board_ypos + (board_height / 2) - (indicator_l / 2)
  push_args<ax, cx, dx>
  call tile_draw
  pop_args

  mov cx, board_xpos + board_width
  push_args<ax, cx, dx>
  call tile_draw
  pop_args

  ;; ------------

  ;; draw board
  mov cx, board_xpos
  mov dx, board_ypos

  mov bx, 0
  ;; draw black
@@draw_black:

  mov ax, bx
  call board_at_pos

  cmp ax, 0ffffh
  je @@done

  push bx
  mov bx, 1

  call draw_piece

  pop bx

  ;; inc and check for next line
  inc bx
  add cx, tile_size
  cmp cx, board_xpos + tile_size * 8
  je @@next_line_black
  jmp @@draw_white

@@next_line_black:
  mov cx, board_xpos
  add dx, tile_size

  cmp dx, board_ypos + tile_size * 8
  je @@done
  jmp @@draw_black


  ;; draw white
@@draw_white:

  mov ax, bx
  call board_at_pos

  cmp ax, 0ffffh
  je @@done

  push bx
  mov bx, 0

  call draw_piece

  pop bx

  ;; inc and check for next line
  inc bx
  add cx, tile_size
  cmp cx, board_xpos + tile_size * 8
  jne @@draw_black

  mov cx, board_xpos
  add dx, tile_size

  cmp dx, board_ypos + tile_size * 8
  jne @@draw_white


  ;; --------
@@done:

  enable_cursor

  leav
  ret
  endp

draw_piece proc near
  push ax

  cmp bx, 0
  je @@black_sq

  ;; white square
  cmp ah, board_flag0
  je @@white_sel

  mov ax, tile_empty_w
  jmp @@done_sq

@@white_sel:
  mov ax, tile_empty_ws
  jmp @@done_sq

  ;; black square
@@black_sq:

  cmp ah, board_flag0
  je @@black_sel

  mov ax, tile_empty_b
  jmp @@done_sq

@@black_sel:
  mov ax, tile_empty_bs

  ;; -----
@@done_sq:
  push_args<ax, cx, dx>
  call tile_draw
  pop_args

  pop ax

  cmp al, 0
  je @@done

  xor ah, ah
  add cx, 2
  add dx, 2
  push_args<ax, cx, dx>
  call tile_draw
  pop_args
  sub cx, 2
  sub dx, 2

@@done:

  ret
  endp

;;; --  ----------------------------------

  ;; draws a rectangle at x y with color c
  ;; args:
  ;; x | y | w | h | c
  ;; uses : { ax, bx, cx, di, es }
draw_rect proc near
  entr 0

x = bp + 6 + 8
y = bp + 6 + 6
w = bp + 6 + 4
h = bp + 6 + 2
c = bp + 6

  mov ax, vram
  mov es, ax

  ;; move to left top corner
  mov ax, word ptr [y]
  mov bx, 320
  mul bx
  mov di, ax
  add di, word ptr [x]
  mov ax, word ptr [c]
  mov cx, word ptr [w]
  dec cx

  cld
  rep
  stosb

  mov cx, word ptr [w]
  dec cx
  mov bx, word ptr [h]
@@draw_v:
  mov es:[di], al
  sub di, cx
  mov es:[di], al
  add di, cx
  add di, 320

  dec bx
  jnz @@draw_v

  sub di, 320
  std
  rep
  stosb

  leav
  ret
  endp

  ;; draws filled rectangle at x y with color c and
  ;; border color cb
  ;; args:
  ;; x | y | w | h | c | cb
draw_filled_rect proc near
  entr 0

x = bp + 6 + 10
y = bp + 6 + 8
w = bp + 6 + 6
h = bp + 6 + 4
c = bp + 6 + 2
cb = bp + 6

  mov ax, vram
  mov es, ax

  ;; move to left top corner
  mov ax, word ptr [y]
  mov bx, 320
  mul bx
  mov di, ax
  add di, word ptr [x]
  mov ax, word ptr [c]
  mov bx, word ptr [h]
  mov cx, word ptr [w]
  dec cx

@@draw_v:
  cld
  rep
  stosb

  add di, 320
  mov cx, word ptr [w]
  dec cx
  sub di, cx
  dec bx
  jnz @@draw_v

  push word ptr [x]
  push word ptr [y]
  push word ptr [w]
  push word ptr [h]
  push word ptr [cb]

  call draw_rect
  pop_args 5

  leav
  ret
  endp

  end
