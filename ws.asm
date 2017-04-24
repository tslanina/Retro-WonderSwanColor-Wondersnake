; Wondersnake
; (c) Tomasz Slanina
; tomasz@slanina.pl
;
; GNU GPL v3 License


.model tiny
.186
.code
JUMPS

S_COUNTER   equ 19*2
S_TAILL     equ 8
S_DELAY     equ 14


Z_COUNTER   equ 0
Z_KEY       equ 2
Z_KEYAND    equ 4
Z_HEAD      equ 6
Z_TAIL      equ 10
Z_HEADDIR   equ 14
Z_HEADOLD   equ 16
Z_DELAY     equ 18
Z_TAILL     equ 20
Z_RND       equ 22
Z_LEVEL     equ 24
Z_FOOD      equ 26
Z_PASSWORD  equ 28
Z_MENU      equ 40

Z_KW        equ 42
Z_KWE       equ 72
Z_KKK       equ 74

END_MENU    equ 76
NUM_OPTION  equ 78
ENTER_PASS  equ 80
LAST_PLAYED equ 82
PASS_LETTER equ 84
FINISH      equ 86
NUM_LEVEL   equ 88

      org 100h

start:
      cli
      cld
      mov sp,100h
      xor ax,ax
      mov ss,ax
      mov es,ax
      mov es:[LAST_PLAYED],al ;base level
      mov al,0e0h
      out 60h,al	;gfx mode
      mov al,1
      out 14h,al

      call title_screen

sta:
      mov sp,100h
      call tit
      xor ax,ax
      mov es,ax
      mov al,es:[END_MENU]
      dec al
      mov es:[NUM_LEVEL],al
      xor ax,ax
      mov es:[Z_COUNTER],ax

big_loop:
      xor ax,ax
      mov es,ax
      mov al,es:[NUM_LEVEL]
      call levelinfo
      call level
      xor ax,ax
      mov es,ax
      mov al,es:[NUM_LEVEL]
      inc al
      mov es:[NUM_LEVEL],al
      cmp al,20
      jz congratulations
      jmp big_loop

level:
      mov ax,8000h
      mov ds,ax

      xor ax,ax
      out 10h,ax
      out 12h,ax

      mov al,1+2
      out 0,al

      mov al,21h
      out 7,al  ; scrloc 800,1000

      xor di,di
      push di
      pop es
      mov di,4000h
      mov si,offset tile_data
      mov cx,48*32
      cld
      rep movsw

      mov si,offset palety
      mov di,0fe00h
      mov cx,100h
      rep movsw	;palety

      mov di,800h
      mov cl,16	
l1:
      mov ch,16
l2:
      mov ax,1+2*512
      stosw
      mov ax,2+2*512
      stosw
      dec ch
      jnz l2

      mov ch,16
l3:
      mov ax,3+2*512
      stosw
      mov ax,4+2*512
      stosw
      dec ch
      jnz l3

      dec cl
      jnz l1	;mamy background

      call licznik

      mov ax,S_DELAY
      mov es:[Z_DELAY],ax

      mov al,es:[NUM_LEVEL]
      mov es:[LAST_PLAYED],al
      xor ah,ah
      call makelevel

mainloop:

      mov dx,2

cz1:
      in al,dx
      cmp al,90
      jnz cz1

cz2:
      in al,dx
      cmp al,91
      jnz cz2

      call skrol

      mov ax,es:[Z_DELAY]  ; calculate delay
      dec ax
      mov es:[Z_DELAY],ax

      or ax,ax
      jnz mainloop
      mov ax,S_DELAY
      mov es:[Z_DELAY],ax

      mov al,es:[Z_FOOD]
      or al,al

      jnz is_food
      mov ax,150
      call wait_frames
      ret

is_food:

      ;vblank

      call licznik
      call keypad
      mov al,es:[Z_KEYAND]
      and al,0f0h
      shr al,4
      mov bl,al   ;bl = new direction
      mov ax,es:[Z_HEADDIR]
      or bl,bl
      jnz dalej1
      mov bl,al
dalej1:

      xor bh,bh
      mov es:[Z_HEADDIR],bx
      mov ah,al
      mov al,bl

      test al,1
      jnz mov_gora
      test al,2
      jnz mov_prawo
      test al,4
      jnz mov_dol

mov_lewo:
      mov dx,-2 ;co dodamy do wspolrzednych
      mov cx,10+4000h ;lewo - gdzie glowa
      test ah,2
      jnz game_over
      mov bx,45
      test ah,8
      jnz wpisz ;przedtem tez lewo
      mov bx,46
      test ah,1
      jnz wpisz ; przedtem do gory
      mov bx,47
      jmp wpisz ;przedtem w dol

mov_prawo:
      mov dx,2 ;co dodamy do wspolrzednych
      mov cx,10 ;prawo - gdzie glowa
      test ah,8
      jnz game_over
      mov bx,49
      test ah,2
      jnz wpisz ;prev = left
      mov bx,51
      test ah,1
      jnz wpisz ;prev = up
      mov bx,50
      jmp wpisz ;prev = down

mov_gora:
      mov dx,-64 ;co dodamy do wspolrzednych
      mov cx,9+8000h ;prawo - gdzie glowa
      test ah,4
      jnz game_over
      mov bx,53
      test ah,1
      jnz wpisz ;przedtem tez gora
      mov bx,54
      test ah,2
      jnz wpisz ;przedtem do gory
      mov bx,55
      jmp wpisz ;przedtem w dol

mov_dol:
      mov dx,64 ;co dodamy do wspolrzednych
      mov cx,9 ;prawo - gdzie glowa
      test ah,1
      jnz game_over
      mov bx,57
      test ah,4
      jnz wpisz ;przedtem tez lewo
      mov bx,58
      test ah,2
      jnz wpisz ;przedtem do gory
      mov bx,59

wpisz:
      ;bx co do nowego , cx co do starego , dx jakie nowe
      inc bx

      mov di,1000h
      add di,es:[Z_HEAD]
      add di,dx
      mov ax,es:[di]
      or  ax,ax
      jz dalej11

      cmp ax,512+11+62
      jnz game_over

      ;zwiekszamy licznik

      push bx
      push cx
      mov ax,es:[Z_COUNTER]
      mov bx,1
      add ax,bx
      daa
      mov es:[Z_COUNTER],ax

      dec byte ptr es:[Z_FOOD]

      mov ax,S_TAILL
      mov es:[Z_TAILL],ax

      pop cx
      pop bx

dalej11:
      mov di,1000h
      add di,es:[Z_HEAD]
      mov es:[di],bx
      add di,dx
      mov es:[di],cx
      sub di,1000h
      mov es:[Z_HEAD],di


moveogon:
      mov ax,es:[Z_TAILL]
      or ax,ax
      jz ddl
      dec ax
      mov es:[Z_TAILL],ax
      jmp mainloop

ddl:
      mov ax,es:[Z_TAIL]
      add ax,1000h
      mov di,ax
      mov bx,es:[di]
      mov cx,-2
      cmp bx,5
      jz ogon
      mov cx,2
      cmp bx,6
      jz ogon
      mov cx,-64
      cmp bx,7
      jz ogon
      mov cx,64

ogon:
      xor si,si
      mov di,ax
      mov es:[di],si ;czyscimy
      add ax,cx
      mov di,ax
      mov bx,es:[di]
      sub ax,1000h
      mov es:[Z_TAIL],ax ;bx to to co bylo
      sub bx,46
      shr bx,2
      add bx,5
      mov es:[di],bx
      jmp mainloop

licznik:
      xor ax,ax
      mov es,ax
      mov si,Z_COUNTER
      mov ax,es:[si]
      mov cx,ax
      mov di,S_COUNTER+1000h
      mov ax,3*512+17
      stosw
      mov ax,18+3*512
      stosw
      add di,8
      mov ax,21+3*512
      stosw
      mov di,S_COUNTER+1000h+64
      mov ax,3*512+19
      stosw
      mov ax,20+3*512
      stosw
      add di,8
      mov ax,22+3*512
      stosw

      mov al,ch
      shr ax,4
      and ax,0fh
      add ax,23+3*512
      mov di,S_COUNTER+1000h+4
      stosw
      mov al,ch
      and ax,0fh
      add ax,23+3*512
      stosw
      mov al,cl
      shr ax,4
      and ax,0fh
      add ax,23+3*512
      stosw
      mov al,cl
      and ax,0fh
      add ax,23+3*512
      stosw

      mov al,ch
      shr ax,4
      and ax,0fh
      add ax,23+3*512+10
      mov di,S_COUNTER+1000h+4+64
      stosw
      mov al,ch
      and ax,0fh
      add ax,23+3*512+10
      stosw
      mov al,cl
      shr ax,4
      and ax,0fh
      add ax,23+3*512+10
      stosw
      mov al,cl
      and ax,0fh
      add ax,23+3*512+10
      stosw
      ret

keypad:
      mov dx,0b5h
      mov al,20h
      out dx,al
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      in al,dx ;kierunki
      and al,0fh

      test al,1
      jz v1
      and al,1
v1:
      test al,2
      jz v2
      and al,2
v2:
      test al,4
      jz v3
      and al,4
v3:
      test al,8
      jz v4
      and al,8
v4:
      shl al,4
      mov bl,al
      mov al,40h
      out dx,al
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      in al,dx ;kierunki
      and al,0fh
      mov cl,al
      or bl,al

      mov al,es:[Z_KEY]
      mov es:[Z_KEY],bl
      xor al,bl
      and al,bl
      mov es:[Z_KEYAND],al
      ret

makelevel:
      mov es:[Z_LEVEL],ax

      mov si,offset levels
      xor dx,dx
      mov bx,336
      mul bx
      add si,ax

      mov di,1000h+64+64+2+2
      mov ch,14
ml1:
      mov cl,24
ml2:
      mov al,ds:[si]
      mov ah,0
      or al,al
      jz is_zero
      mov bx,8*512
      cmp al,11
      jnz skip_set
      mov bx,1*512
skip_set:
      add ax,bx
      add ax,62
is_zero:
      mov es:[di],ax
      add di,2
      inc si
      dec cl
      jnz ml2
      add di,64-24*2
      dec ch
      jnz ml1

      ;ramka

      mov di,1000h
      mov ax,3*512+16
      stosw
      mov cx,26
      mov ax,13+3*512
      rep stosw
      mov ax,3*512+16+4000h
      stosw                  ;gorny rzad

      mov di,1000h+32*2
      mov ax,3*512+11
      stosw
      mov ax,3*512+14
      stosw
      mov cx,24
      mov ax,15+3*512
      rep stosw
      mov ax,3*512+14+4000h
      stosw
      mov ax,3*512+11+4000h
      stosw                  ;gorny rzad cd

      mov di,1000h+17*32*2
      mov ax,3*512+16+8000h
      stosw
      mov cx,26
      mov ax,13+3*512+8000h
      rep stosw
      mov ax,3*512+16+8000h+4000h
      stosw                  ;dolny rzad

      mov di,1000h+16*32*2
      mov ax,3*512+11
      stosw
      mov ax,3*512+14+8000h
      stosw
      mov cx,24
      mov ax,15+3*512+8000h
      rep stosw
      mov ax,3*512+14+4000h+8000h
      stosw
      mov ax,3*512+11+4000h
      stosw                  ;dolny rzad cd

      mov cx,14
      mov di,1000h+32*2*2
lk1:
      mov ax,11+3*512
      stosw
      mov ax,12+3*512
      stosw
      add di,32*2-4
      loop lk1

      mov cx,14
      mov di,1000h+32*2*2+26*2

lk2:
      mov ax,12+3*512+4000h
      stosw
      mov ax,11+3*512+4000h
      stosw
      add di,32*2-4
      loop lk2

      mov ax,2
      mov es:[Z_HEADDIR],ax
      mov es:[Z_HEADOLD],ax

      push es

      mov cl,es:[NUM_LEVEL]
      mov si,offset start_offsets
      xor ch,ch
      add cx,cx
      add si,cx
      mov ax,8000h
      mov es,ax
      mov cl,es:[si]  ;x
      mov ch,es:[si+1];y
      add cl,2
      add ch,2
      mov al,ch
      xor ah,ah
      shl ax,6 ;*64
      xor ch,ch
      add cx,cx
      add ax,cx
      pop es

      push ax
      mov es:[Z_HEAD],ax
      mov bx,10
      mov di,ax
      add di,1000h
      mov es:[di],bx

      pop ax
      sub ax,2

      mov es:[Z_TAIL],ax
      mov bx,6
      mov di,ax
      add di,1000h
      mov es:[di],bx

      mov ax,S_TAILL
      mov es:[Z_TAILL],ax

      mov ax,10
      mov es:[Z_FOOD],ax
      ret

skrol:
      push ax
      mov dx,10h
      in al,dx
      mov bl,al
      inc dx
      in al,dx
      mov bh,al

      mov ax,es:[Z_HEADDIR]
      shl al,4
      test al,16
      jz s1
      dec bh
s1:
      test al,128
      jz s2
      dec bl
s2:
      test al,64
      jz s3
      inc bh
s3:
      test al,32
      jz s4
      inc bl
s4:
      mov al,bh
      out dx,al
      dec dx
      mov al,bl
      out dx,al

      pop ax
      ret

levels:
      include levels\l00.inc
      include levels\l01.inc
      include levels\l02.inc
      include levels\l03.inc
      include levels\l04.inc
      include levels\l05.inc
      include levels\l06.inc
      include levels\l07.inc
      include levels\l08.inc
      include levels\l09.inc
      include levels\l10.inc
      include levels\l11.inc
      include levels\l12.inc
      include levels\l13.inc
      include levels\l14.inc
      include levels\l15.inc
      include levels\l16.inc
      include levels\l17.inc
      include levels\l18.inc
      include levels\l19.inc



print:
      ;al=x
      ;ah=y
      ;cl=znak
      ;ch=pal

      push cx

      xor ch,ch
      sub cx,65
      add cx,cx
      add cx,257

      pop bx
      xor bl,bl
      add bx,bx ;bity
      or cx,bx

      push ax
      xor al,al

      shr ax,2

      pop bx
      xor bh,bh
      add bx,bx
      or  ax,bx
      mov di,800h
      add di,ax
      xor bx,bx
      push bx
      pop es
      mov es:[di],cx
      add di,2
      inc cx
      mov es:[di],cx
      add di,64-2
      add cx,79
      mov es:[di],cx
      add di,2
      inc cx
      mov es:[di],cx
      ret

print2:
      ;al=x
      ;ah=y
      ;cl=znak
      ;ch=pal

      push cx

      xor ch,ch
      sub cx,65
      add cx,cx
      add cx,257

      pop bx
      xor bl,bl
      add bx,bx ;bity
      or cx,bx

      push ax
      xor al,al

      shr ax,2

      pop bx
      xor bh,bh
      add bx,bx
      or  ax,bx
      mov di,1000h
      add di,ax
      xor bx,bx
      push bx
      pop es
      mov es:[di],cx
      add di,2
      inc cx
      mov es:[di],cx
      add di,64-2
      add cx,79
      mov es:[di],cx
      add di,2
      inc cx
      mov es:[di],cx
      ret

print3:
      ;al=x
      ;ah=y
      ;cl=znak
      ;ch=pal

      push cx

      xor ch,ch
      sub cx,65
      add cx,cx
      add cx,S_POCZO

      pop bx
      xor bl,bl
      add bx,bx ;bity
      or cx,bx

      push ax
      xor al,al

      shr ax,2

      pop bx
      xor bh,bh
      add bx,bx
      or  ax,bx
      mov di,1000h
      add di,ax
      xor bx,bx
      push bx
      pop es
      mov es:[di],cx
      add di,2
      inc cx
      mov es:[di],cx
      add di,64-2
      add cx,79
      mov es:[di],cx
      add di,2
      inc cx
      mov es:[di],cx
      ret


menu:
      ;clear screen
      ;load new tiles
      ;display texts

levelinfo:

      push ax

      call blackpal

      mov si,offset zigzag
      xor ax,ax
      mov es,ax
      mov di,4000h
      mov ax,8000h
      mov ds,ax
      xor ax,ax
      out 10h,al
      out 11h,al
      out 12h,al
      out 13h,al
      cld
      mov cx,16
      rep stosw ;1st = 0
      mov ax,1111h
      mov cx,16
      rep stosw ;2nd = 1
      mov cx,16*8
      rep movsw ; zigzak

      mov al,1
      out 0,al
      xor al,al
      out 1,al
      mov al,21h
      out 7,al  ; scrloc 800,1000
      mov si,offset mapa1_info
      mov di,800h
      mov cx,1024
      rep movsw

      mov si,offset fonty
      mov di,4000h+256*32
      xor ax,ax
      mov cx,16
      rep stosw
      mov cx,512*16
      rep movsw

      ;al=x
      ;ah=y
      ;cl=znak
      ;ch=pal

      mov cl,'L'
      mov ch,1
      mov ax,0706h
      call print
      mov cl,'E'
      mov ch,1
      mov ax,0708h
      call print
      mov cl,'V'
      mov ch,1
      mov ax,070ah
      call print
      mov cl,'E'
      mov ch,1
      mov ax,070ch
      call print
      mov cl,'L'
      mov ch,1
      mov ax,070eh
      call print

      mov si,offset tabasci
      mov bx,8000h
      mov ds,bx

      pop ax
      push ax

      add ax,ax
      add si,ax
      mov dx,ds:[si]
      push dx

      mov cl,dl
      add cl,43
      mov ch,1
      mov ax,0712h
      call print

      pop dx
      mov cl,dh
      add cl,43
      mov ch,1
      mov ax,0714h
      call print

      pop ax
      mov si,offset passwords
      add ax,ax
      add ax,ax

      add si,ax
      mov bx,8000h
      mov ds,bx

      push ds
      push si
      mov cl,ds:[si]
      mov ch,2
      mov ax,0a0ah
      call print


      pop si
      pop ds
      inc si
      push ds
      push si
      mov cl,ds:[si]
      mov ch,2
      mov ax,0a0ch
      call print

      pop si
      pop ds
      inc si
      push ds
      push si
      mov cl,ds:[si]
      mov ch,2
      mov ax,0a0eh
      call print

      pop si
      pop ds
      inc si
      mov cl,ds:[si]
      mov ch,2
      mov ax,0a10h
      call print

      mov ax,offset paleta_info
      call setpal

      xor ax,ax
      mov es,ax
      mov ax,8000h
      mov ds,ax

      xor bx,bx  ;petla scrolla
lo11:
      push bx
      mov al,100
      call wait_linia
      call wait_vbl
      mov al,100
      call wait_linia
      call wait_vbl
      pop bx

      mov ah,bl
      xor al,al
      mov si,offset zigzag
      add si,ax
      mov di,4040h
      mov cx,128
      rep movsw

      inc bx
      and bx,31 ;max frames

      push es
      push ds
      push bx

      call keypad
      xor ax,ax
      mov es,ax
      mov al,es:[Z_KEYAND]
      and al,14
      pop bx
      pop ds
      pop es

      jz lo11
      ret


blackpal:
      call wait_vbl
      xor ax,ax
      push ax
      pop es
      mov cx,256
      cld
      mov di,0fe00h
      rep stosw
      ret


setpal:
      push ax
      call wait_vbl
      xor ax,ax
      mov es,ax
      mov ax,8000h
      mov ds,ax
      mov cx,256
      cld
      mov di,0fe00h
      pop si
      rep movsw
      ret

wait_vbl:
      mov al,144

wait_linia:
      mov bl,al
      mov dx,2
wait1:
      in al,dx
      cmp al,bl
      jne wait1
      ret

game_over:
      mov ax,120
      call wait_frames

      call blackpal

      mov si,offset gover_til
      xor ax,ax
      mov es,ax
      mov di,4000h
      mov ax,8000h
      mov ds,ax
      xor ax,ax
      out 10h,al
      out 11h,al
      out 12h,al
      out 13h,al
      cld
      mov cx,16*18
      rep movsw ; zigzak

      mov al,1
      out 0,al
      xor al,al
      out 1,al
      mov al,21h
      out 7,al  ; scrloc 800,1000
      mov si,offset gover_map
      mov di,800h
      mov cx,1024
      rep movsw

      mov si,offset fonty
      mov di,4000h+256*32
      xor ax,ax
      mov cx,16
      rep stosw
      mov cx,512*16
      rep movsw

      ;al=x
      ;ah=y
      ;cl=znak
      ;ch=pal

      mov cl,'G'
      mov ch,1
      mov ax,0707h
      call print
      mov cl,'A'
      mov ch,1
      mov ax,0709h
      call print
      mov cl,'M'
      mov ch,1
      mov ax,070bh
      call print
      mov cl,'E'
      mov ch,1
      mov ax,070dh
      call print


      mov cl,'O'
      mov ch,1
      mov ax,0a0fh
      call print
      mov cl,'V'
      mov ch,1
      mov ax,0a11h
      call print
      mov cl,'E'
      mov ch,1
      mov ax,0a13h
      call print
      mov cl,'R'
      mov ch,1
      mov ax,0a15h
      call print

      mov ax,offset gover_pal
      call setpal

      xor ax,ax
      mov es,ax
      mov ax,8000h
      mov ds,ax

      xor bx,bx  ;petla scrolla
lo12:
      push bx
      mov al,100
      call wait_linia
      call wait_vbl
      mov al,100
      call wait_linia
      call wait_vbl
      mov al,100
      call wait_linia
      call wait_vbl
      mov al,100
      call wait_linia
      call wait_vbl
      pop bx

      mov ah,bl
      add ah,ah
      xor al,al
      mov si,offset gover_til
      add si,ax
      mov di,4000h
      mov cx,128*2
      rep movsw
      inc bx
      and bl,15

      push es
      push ds
      push bx

      call keypad
      xor ax,ax
      mov es,ax
      mov al,es:[Z_KEYAND]
      and al,14
      pop bx
      pop ds
      pop es

      jz lo12
      jmp sta
      ret

gover_pal:
      db 201,6,67,0,128,0,128,8,8,0,8,8
      db 136,0,204,12,220,12,207,10,15,0,240,0
      db 0,15,240,15,15,15,255,0

      db 86,0,255,15,253,15,233,15,192,13,160,12
      db 64,7,48,4,16,3,16,2,50,4,53,10
      db 103,11,69,11,68,11,17,8


gover_til:

      include fala.inc

      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

gover_map:
      include fmap.inc



mapa1_info:
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 2,3,4,5,2,3,4,5,2,3,4,5,2,3,4,5,2,3,4,5,2,3,4,5,2,3,4,5,2,3,4,5
      dw 6,7,8,9,6,7,8,9,6,7,8,9,6,7,8,9,6,7,8,9,6,7,8,9,6,7,8,9,6,7,8,9
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      dw 0c009h,0c008h,0c007h,0c006h,0c009h,0c008h,0c007h,0c006h,0c009h,0c008h,0c007h,0c006h,0c009h,0c008h,0c007h,0c006h,0c009h,0c008h,0c007h,0c006h,0c009h,0c008h,0c007h,0c006h,0c009h,0c008h,0c007h,0c006h,0c009h,0c008h,0c007h,0c006h
      dw 0c005h,0c004h,0c003h,0c002h,0c005h,0c004h,0c003h,0c002h,0c005h,0c004h,0c003h,0c002h,0c005h,0c004h,0c003h,0c002h,0c005h,0c004h,0c003h,0c002h,0c005h,0c004h,0c003h,0c002h,0c005h,0c004h,0c003h,0c002h,0c005h,0c004h,0c003h,0c002h
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      dw 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

paleta_info:
      db 156,8,6,1,128,0,128,8,8,0,8,8
      db 136,0,204,12,220,12,207,10,15,0,240,0
      db 0,15,240,15,15,15,255,0

      db 86,0,255,15,253,15,233,15,192,13,160,12
      db 64,7,48,4,16,3,16,2,50,4,53,10
      db 103,11,69,11,68,11,17,8

      db 86,0,255,15,221,15,153,15,101,13,68,12
      db 50,7,33,4,16,3,16,2,50,4,53,10
      db 103,11,69,11,68,11,17,8

fonty:
      include fonty.inc

tile_data:
      include tiles.inc

palety:
      include pals.inc

zigzag:
      include zigzag.inc

tabasci:
      db '0','1'
      db '0','2'
      db '0','3'
      db '0','4'
      db '0','5'
      db '0','6'
      db '0','7'
      db '0','8'
      db '0','9'
      db '1','0'
      db '1','1'
      db '1','2'
      db '1','3'
      db '1','4'
      db '1','5'
      db '1','6'
      db '1','7'
      db '1','8'
      db '1','9'
      db '2','0'



passwords:
      db 'XXXX'
      db 'SJOS'
      db 'WQYH'
      db 'ELOF'
      db 'DSUI'
      db 'CKAQ'
      db 'VYQW'
      db 'FOAS'
      db 'RRXX'
      db 'TOAI'

      db 'GMKA'
      db 'BVYA'
      db 'NQWQ'
      db 'HMAL'
      db 'YXYH'
      db 'UPOA'
      db 'JLLQ'
      db 'MKIA'
      db 'KMNZ'
      db 'IZXZ'

start_offsets:
      db 12,6
      db 16,6
      db 16,7
      db 9,7
      db 12,12
      db 12,1
      db 12,12
      db 12,6
      db 12,6
      db 12,12
      db 12,6
      db 12,3
      db 12,4
      db 12,0
      db 13,13
      db 12,9
      db 12,4
      db 12,7
      db 12,13
      db 12,0

      


      S_POCZO equ 64

tit:

    xor ax,ax
      mov ds,ax
      mov ds:[END_MENU],al
      mov ds:[NUM_OPTION],al
      mov ds:[ENTER_PASS],al

      call blackpal

      mov si,offset title_til
      xor ax,ax
      mov es,ax
      mov di,4000h
      mov ax,8000h
      mov ds,ax
      xor ax,ax
      out 10h,al
      out 11h,al
      out 12h,al
      out 13h,al
      cld
      mov cx,16
      rep stosw ;czysta

      mov cx,16*4
      rep movsw

      mov si,offset title_til
      add si,4*32*3*2
      mov cx,16*4
      rep movsw

      mov si,offset title_til
      add si,4*32*5*2
      mov cx,16*4
      rep movsw

      mov si,offset title_til
      add si,4*32*8*2
      mov cx,16*4
      rep movsw

      mov si,offset title_til
      add si,4*32*11*2
      mov cx,16*4
      rep movsw


      mov si,offset title_til
      add si,4*32*14*2
      mov cx,16*4
      rep movsw


      mov si,offset ramka
      mov cx,16*10
      rep movsw

      mov al,3
      out 0,al
      xor al,al
      out 1,al
      mov al,21h
      out 7,al  ; scrloc 800,1000
      xor ax,ax
      mov di,800h
      mov cx,1024
      rep stosw ;czyscimy

      mov di,1000h
      mov cx,1024
      rep stosw ;czyscimy

      mov si,offset krata
      mov di,4000h+64*32
      mov cx,512*16
      rep movsw

      mov si,offset fonty
      mov di,4000h+256*32
      xor ax,ax
      mov cx,16
      rep stosw
      mov cx,512*16
      rep movsw

      mov di,Z_KW
      xor ax,ax
      mov es,ax
      mov ax,8000h
      mov ds,ax
      mov si,offset startup
      mov cx,6
      cld
      rep movsw

      mov al,6
      mov es:[Z_KWE],al ;wolny to 5

      xor ax,ax
      mov es:[Z_KKK],al

      mov al,1
      mov ch,0
      call wpisz_al

      mov al,5
      mov ch,1
      call wpisz_al

      mov al,9
      mov ch,2
      call wpisz_al

      mov al,13
      mov ch,3
      call wpisz_al

      mov al,17
      mov ch,4
      call wpisz_al

      mov al,21
      mov ch,5
      call wpisz_al

      xor ax,ax
      mov es,ax
      mov di,1000h+2*64+3*2
      mov ax,512*3+27
      stosw
      mov ax,26+3*512
      mov cx,19
      rep stosw
      mov ax,512*3+28
      stosw

      mov di,1000h+3*64+3*2
      mov ax,512*3+25
      stosw
      mov ax,33+3*512
      mov cx,19
      rep stosw
      mov ax,512*3+31
      stosw

      mov ax,512*3+25
      mov di,1000h+4*64+3*2
      stosw
      mov ax,33+3*512
      mov cx,19
      rep stosw
      mov ax,512*3+31
      stosw

      mov ax,512*3+25
      mov di,1000h+5*64+3*2
      stosw
      mov ax,33+3*512
      mov cx,19
      rep stosw
      mov ax,512*3+31
      stosw

      mov ax,512*3+25
      mov di,1000h+6*64+3*2
      stosw
      mov ax,33+3*512
      mov cx,19
      rep stosw
      mov ax,512*3+31
      stosw

      mov ax,512*3+25
      mov di,1000h+7*64+3*2
      stosw

      mov ax,33+3*512
      mov cx,19
      rep stosw
      mov ax,512*3+31
      stosw

      mov di,1000h+8*64+3*2
      mov ax,512*3+29
      stosw
      mov ax,32+3*512
      mov cx,19
      rep stosw
      mov ax,512*3+30
      stosw

      mov cl,'W'
      mov ch,3
      mov ax,305h
      call print3

      mov cl,'O'
      mov ch,3
      mov ax,308h
      call print3

      mov cl,'N'
      mov ch,3
      mov ax,30bh
      call print3

      mov cl,'D'
      mov ch,3
      mov ax,30eh
      call print3

      mov cl,'E'
      mov ch,3
      mov ax,311h
      call print3

      mov cl,'R'
      mov ch,3
      mov ax,314h
      call print3



      mov cl,'S'
      mov ch,3
      mov ax,607h
      call print3

      mov cl,'N'
      mov ch,3
      mov ax,60ah
      call print3

      mov cl,'A'
      mov ch,3
      mov ax,60dh
      call print3

      mov cl,'K'
      mov ch,3
      mov ax,610h
      call print3

      mov cl,'E'
      mov ch,3
      mov ax,613h
      call print3

      call wyswietl_opcje

      mov ax,offset title_pal
      call setpal

title_loop:

      mov al,130
      call wait_linia
      call wait_vbl
      mov al,130
      call wait_linia
      call wait_vbl
      mov al,130
      call wait_linia
      call wait_vbl

      call check_keys

      mov al,130
      call wait_linia
      call wait_vbl
      mov al,130
      call wait_linia
      call wait_vbl

      

      xor ax,ax
      mov es,ax
      mov al,es:[Z_KKK] ;klatka
      xor ah,ah
      inc ax
      and ax,31
      mov es:[Z_KKK],al
      push es
      push ax
      xor ax,ax
      mov es,ax
      mov ax,8000h
      mov ds,ax
      mov si,offset title_til
      mov di,4000h+32
      pop ax
      push ax
      shl ax,7
      add si,ax
      mov cx,64
      rep movsw

      mov si,offset title_til
      pop ax
      push ax
      add ax,3*2
      and ax,31

      shl ax,7
      add si,ax
      mov cx,64
      rep movsw

      mov si,offset title_til
      pop ax
      push ax
      add ax,5*2
      and ax,31
      shl ax,7
      add si,ax
      mov cx,64
      rep movsw

      mov si,offset title_til
      pop ax
      push ax
      add ax,8*2
      and ax,31
      shl ax,7
      add si,ax
      mov cx,64
      rep movsw

      mov si,offset title_til
      pop ax
      push ax
      add ax,11*2
      and ax,31
      shl ax,7
      add si,ax
      mov cx,64
      rep movsw

      mov si,offset title_til
      pop ax
      push ax
      add ax,14*2
      and ax,31
      shl ax,7
      add si,ax
      mov cx,64
      rep movsw

      pop ax
      pop es
      call sprawdz

      xor ax,ax
      mov ds,ax
      mov al,ds:[END_MENU]
      or al,al
      jz title_loop
      ret

check_keys:
      ;read keys
      ;up/down = next option
      ;a/b/start level 1 start or enter password

      call keypad
      xor ax,ax
      mov es,ax
      mov al,es:[ENTER_PASS]
      or al,al
      jne wpisujemy
      mov al,es:[Z_KEYAND]
      and al,80
      jnz daala
      mov al,es:[Z_KEYAND]
      and al,14
      jnz batonn
      ret

daala:
      xor byte ptr es:[NUM_OPTION],1
      jmp wyswietl_opcje

batonn:
      mov al,es:[NUM_OPTION]
      or al,al
      jnz passwd
      mov al,1
      mov es:[END_MENU],al
      ret

wpisujemy:
      mov al,es:[Z_KEYAND]
      and al,80
      jnz zmiana_litery
      mov al,es:[Z_KEYAND]
      and al,160
      jnz zmiana_edytowanej
      mov al,es:[Z_KEYAND]
      and al,14
      jnz wprowadzono
      ret

zmiana_edytowanej:
      mov bl,es:[PASS_LETTER]
      test al,128
      jz drugi
      dec bl
      jmp wyjuj

drugi:
      inc bl

wyjuj:
      and bl,3
      mov es:[PASS_LETTER],bl
      jmp wypisz_password

zmiana_litery:
      mov bl,es:[PASS_LETTER]
      mov si,Z_PASSWORD
      xor bh,bh
      add si,bx
      mov ah,es:[si]
      test al,64 ;mniejsza
      jz zwiekszamy
      cmp ah,'A'
      jnz spox1
      mov ah,'Z'
      jmp spox2

spox1:
      dec ah

spox2:
      mov es:[si],ah
      jmp spox3

zwiekszamy:
      cmp ah,'Z'
      jnz spox11
      mov ah,'A'
      jmp spox21

spox11:
      inc ah

spox21:
      mov es:[si],ah
      
spox3:
      jmp wypisz_password

wprowadzono:
      xor ax,ax
      mov es,ax
      mov ax,8000h
      mov ds,ax
      mov al,es:[Z_PASSWORD]
      xor cl,cl
      mov si,offset passwords

lupa:
      cmp al,ds:[si]
      je pasi
      add si,4
      inc cl
      cmp cl,20
      jne lupa

frtr:
      xor ax,ax
      ;powrot do main
      mov es,ax
      mov es:[ENTER_PASS],al
      mov es:[NUM_OPTION],al
      jmp wyswietl_opcje

pasi:
      mov al,es:[Z_PASSWORD+1]
      inc si
      cmp al,ds:[si]
      jne frtr

      mov al,es:[Z_PASSWORD+2]
      inc si
      cmp al,ds:[si]
      jne frtr

      mov al,es:[Z_PASSWORD+3]
      inc si
      cmp al,ds:[si]
      jne frtr
      inc cl
      mov es:[END_MENU],cl
      ret

passwd:
      ;kasujemy password na 'last played'
      xor ax,ax
      mov es,ax
      mov al,es:[LAST_PLAYED]
      xor ah,ah
      add ax,ax
      add ax,ax
      mov bx,8000h
      mov ds,bx
      mov si,offset passwords
      add si,ax
      mov ax,ds:[si]
      mov es:[Z_PASSWORD],ax
      mov ax,ds:[si+2]
      mov es:[Z_PASSWORD+2],ax ;haslo skopiowane
      ;ustawiamy mode na wpis hasla
      mov al,1
      mov es:[ENTER_PASS],al
      xor al,al
      mov es:[PASS_LETTER],al
      ;kasujemy napis
      xor ax,ax

      mov es:[1000h+0ch*64+09*2],ax
      mov es:[1000h+0ch*64+10*2],ax
      mov es:[1000h+0dh*64+10*2],ax
      mov es:[1000h+0dh*64+09*2],ax

      mov es:[1000h+0ch*64+0bh*2],ax
      mov es:[1000h+0ch*64+0ch*2],ax
      mov es:[1000h+0dh*64+0bh*2],ax
      mov es:[1000h+0dh*64+0ch*2],ax

      mov es:[1000h+0ch*64+0dh*2],ax
      mov es:[1000h+0ch*64+0eh*2],ax
      mov es:[1000h+0dh*64+0dh*2],ax
      mov es:[1000h+0dh*64+0eh*2],ax

      mov es:[1000h+0ch*64+0fh*2],ax
      mov es:[1000h+0ch*64+10h*2],ax
      mov es:[1000h+0dh*64+0fh*2],ax
      mov es:[1000h+0dh*64+10h*2],ax

      mov es:[1000h+0ch*64+11h*2],ax
      mov es:[1000h+0ch*64+12h*2],ax
      mov es:[1000h+0dh*64+11h*2],ax
      mov es:[1000h+0dh*64+12h*2],ax

      mov es:[1000h+0eh*64+6h*2],ax
      mov es:[1000h+0eh*64+7h*2],ax
      mov es:[1000h+0fh*64+6h*2],ax
      mov es:[1000h+0fh*64+7h*2],ax

      mov es:[1000h+0eh*64+8h*2],ax
      mov es:[1000h+0eh*64+9h*2],ax
      mov es:[1000h+0fh*64+8h*2],ax
      mov es:[1000h+0fh*64+9h*2],ax

      mov es:[1000h+0eh*64+0ah*2],ax
      mov es:[1000h+0eh*64+0bh*2],ax
      mov es:[1000h+0fh*64+0ah*2],ax
      mov es:[1000h+0fh*64+0bh*2],ax

      mov es:[1000h+0eh*64+0ch*2],ax
      mov es:[1000h+0eh*64+0dh*2],ax
      mov es:[1000h+0fh*64+0ch*2],ax
      mov es:[1000h+0fh*64+0dh*2],ax

      mov es:[1000h+0eh*64+0eh*2],ax
      mov es:[1000h+0eh*64+0fh*2],ax
      mov es:[1000h+0fh*64+0eh*2],ax
      mov es:[1000h+0fh*64+0fh*2],ax

      mov es:[1000h+0eh*64+10h*2],ax
      mov es:[1000h+0eh*64+11h*2],ax
      mov es:[1000h+0fh*64+10h*2],ax
      mov es:[1000h+0fh*64+11h*2],ax

      mov es:[1000h+0eh*64+12h*2],ax
      mov es:[1000h+0eh*64+13h*2],ax
      mov es:[1000h+0fh*64+12h*2],ax
      mov es:[1000h+0fh*64+13h*2],ax

      mov es:[1000h+0eh*64+14h*2],ax
      mov es:[1000h+0eh*64+15h*2],ax
      mov es:[1000h+0fh*64+14h*2],ax
      mov es:[1000h+0fh*64+15h*2],ax

wypisz_password:
      xor ax,ax
      mov es,ax
      mov al,es:[PASS_LETTER]
      mov ch,1
      cmp al,0
      jne om1
      mov ch,2

om1:
      mov cl,es:[Z_PASSWORD]
      mov ax,0c0bh
      call print2

      xor ax,ax
      mov es,ax
      mov al,es:[PASS_LETTER]
      mov ch,1
      cmp al,1
      jne om2
      mov ch,2
om2:
      mov cl,es:[Z_PASSWORD+1]
      mov ax,0c0dh
      call print2

      xor ax,ax
      mov es,ax
      mov al,es:[PASS_LETTER]
      mov ch,1
      cmp al,2
      jne om3
      mov ch,2
om3:
      mov cl,es:[Z_PASSWORD+2]
      mov ax,0c0fh
      call print2

      xor ax,ax
      mov es,ax
      mov al,es:[PASS_LETTER]
      mov ch,1
      cmp al,3
      jne om4
      mov ch,2
om4:
      mov cl,es:[Z_PASSWORD+3]
      mov ax,0c11h
      jmp print2

wyswietl_opcje:
      xor ax,ax
      mov ds,ax
      mov al,ds:[NUM_OPTION]
      or al,al
      jnz drugie

      mov cl,'S'
      mov ch,2
      mov ax,0c09h
      call print2

      mov cl,'T'
      mov ch,2
      mov ax,0c0bh
      call print2

      mov cl,'A'
      mov ch,2
      mov ax,0c0dh
      call print2

      mov cl,'R'
      mov ch,2
      mov ax,0c0fh
      call print2

      mov cl,'T'
      mov ch,2
      mov ax,0c11h
      call print2

      mov cl,'P'
      mov ch,1
      mov ax,0e06h
      call print2

      mov cl,'A'
      mov ch,1
      mov ax,0e08h
      call print2

      mov cl,'S'
      mov ch,1
      mov ax,0e0ah
      call print2

      mov cl,'S'
      mov ch,1
      mov ax,0e0ch
      call print2

      mov cl,'W'
      mov ch,1
      mov ax,0e0eh
      call print2

      mov cl,'O'
      mov ch,1
      mov ax,0e10h
      call print2

      mov cl,'R'
      mov ch,1
      mov ax,0e12h
      call print2

      mov cl,'D'
      mov ch,1
      mov ax,0e14h
      jmp print2

drugie:
      mov cl,'S'
      mov ch,1
      mov ax,0c09h
      call print2

      mov cl,'T'
      mov ch,1
      mov ax,0c0bh
      call print2

      mov cl,'A'
      mov ch,1
      mov ax,0c0dh
      call print2

      mov cl,'R'
      mov ch,1
      mov ax,0c0fh
      call print2

      mov cl,'T'
      mov ch,1
      mov ax,0c11h
      call print2

      mov cl,'P'
      mov ch,2
      mov ax,0e06h
      call print2

      mov cl,'A'
      mov ch,2
      mov ax,0e08h
      call print2

      mov cl,'S'
      mov ch,2
      mov ax,0e0ah
      call print2

      mov cl,'S'
      mov ch,2
      mov ax,0e0ch
      call print2

      mov cl,'W'
      mov ch,2
      mov ax,0e0eh
      call print2

      mov cl,'O'
      mov ch,2
      mov ax,0e10h
      call print2

      mov cl,'R'
      mov ch,2
      mov ax,0e12h
      call print2

      mov cl,'D'
      mov ch,2
      mov ax,0e14h
      jmp print2

sprawdz:
      mov di,Z_KW
      xor ax,ax
      mov es,ax
      mov cx,6

mainp:
      push cx
      mov al,es:[di+1]
      inc al
      cmp al,32
      jnz okok

      ;koniec klatki
      mov al,es:[di]
      push es
      push di
      call wpisz_0
      pop di
      pop es
      push ax

      mov cl,es:[Z_KWE]
      mov es:[di],cl ;ktory to teraz bedzie
      mov ch,cl
      inc cl
      cmp cl,22
      jne sssp
      xor cl,cl

sssp:
      mov es:[Z_KWE],cl
      pop ax
      push es
      push di
      call wpisz_al
      pop di
      pop es
      xor al,al

okok:
      mov es:[di+1],al
      pop cx
      add di,2
      loop mainp
      ret

wpisz_al:
      ;w al co wpisac
      ;w ch numer z tabelki
      xor ah,ah
      push ax
      mov cl,ch
      xor ch,ch
      add cx,cx
      mov bx,8000h
      mov ds,bx
      mov si,offset kwadraty
      add si,cx
      mov al,ds:[si];x
      mov cl,ds:[si+1];y
      xor ch,ch
      shl cx,6 ;*64
      xor ah,ah
      add ax,ax
      add ax,cx
      mov si,800h
      add si,ax
      xor bx,bx
      mov ds,bx
      pop ax
      push ax
      mov ds:[si],ax
      inc ax
      mov ds:[si+2],ax
      inc ax
      mov ds:[si+64],ax
      inc ax
      mov ds:[si+66],ax
      add si,4
      pop ax
      push ax
      or ax,4000h
      inc ax
      mov ds:[si],ax
      dec ax
      mov ds:[si+2],ax
      inc ax
      inc ax
      inc ax
      mov ds:[si+64],ax
      dec ax
      mov ds:[si+66],ax
      pop ax
      push ax
      add si,128-4
      or ax,8000h
      inc ax
      inc ax
      mov ds:[si],ax
      inc ax
      mov ds:[si+2],ax
      dec ax
      dec ax
      dec ax
      mov ds:[si+64],ax
      inc ax
      mov ds:[si+66],ax
      add si,4
      pop ax
      or ax,0c000h
      inc ax
      inc ax
      inc ax
      mov ds:[si],ax
      dec ax
      mov ds:[si+2],ax
      dec ax
      mov ds:[si+64],ax
      dec ax
      mov ds:[si+66],ax
      ret

wpisz_0:
      xor ah,ah
      add ax,ax
      mov bx,8000h
      mov ds,bx
      mov si,offset kwadraty
      add si,ax
      mov al,ds:[si]
      mov cl,ds:[si+1]
      xor ch,ch
      shl cx,6 ;*64
      xor ah,ah
      add ax,ax
      add ax,cx
      mov si,800h
      add si,ax
      xor bx,bx
      mov ds,bx
      mov ax,ds:[si]
      and ax,0ffh
      push ax ;stary numer
      xor ax,ax
      mov ds:[si],ax
      mov ds:[si+2],ax
      mov ds:[si+4],ax
      mov ds:[si+6],ax
      add si,64
      mov ds:[si],ax
      mov ds:[si+2],ax
      mov ds:[si+4],ax
      mov ds:[si+6],ax
      add si,64
      mov ds:[si],ax
      mov ds:[si+2],ax
      mov ds:[si+4],ax
      mov ds:[si+6],ax
      add si,64
      mov ds:[si],ax
      mov ds:[si+2],ax
      mov ds:[si+4],ax
      mov ds:[si+6],ax
      pop ax
      ret

startup:
      db 0,0
      db 1,3*2
      db 2,5*2
      db 3,8*2
      db 4,11*2
      db 5,14*2

kwadraty: ;23
      db 5,1
      db 13,7
      db 17,1
      db 18,13
      db 8,15
      db 0,9
      db 13,3
      db 25,3
      db 5,8
      db 21,2
      db 4,12
      db 18,9
      db 1,5
      db 23,11
      db 9,5
      db 17,5
      db 9,11
      db 22,7
      db 0,13
      db 14,12
      db 9,0
      db 0,0
      db 24,15

      db 5,1
      db 13,7
      db 17,1
      db 18,13
      db 9,15
      db 0,9
      db 13,3
      db 25,3
      db 5,8
      db 21,2
      db 4,12
      db 18,9
      db 1,5
      db 22,11
      db 9,5
      db 17,5
      db 9,11
      db 22,7
      db 0,13
      db 14,12
      db 9,0
      db 22,7
      db 24,15


title_til:
      include kwadraty.inc

title_pal:
      db 101,8,0,0,167,11,128,8,8,0,8,8
      db 136,0,204,12,220,12,207,10,15,0,240,0
      db 0,15,240,15,15,15,255,0

      db 86,0,255,15,253,15,233,15,192,13,160,12
      db 64,7,48,4,16,3,16,2,50,4,53,10
      db 103,11,69,11,68,11,17,8

      db 86,0,255,15,221,15,153,15,101,13,68,12
      db 50,7,33,4,16,3,16,2,50,4,53,10
      db 103,11,69,11,68,11,17,8

      db 86,0,255,15,223,13,159,8,109,6,111,3
      db 55,2,36,1,19,1,16,2,50,4,53,10
      db 103,11,69,11,255,15,102,6


      db 86,0,255,15,223,13,159,8,109,6,111,3
      db 55,2,36,1,19,1,16,2,50,4,53,10
      db 103,11,69,11,68,11,255,15

ramka:
      include ramka.inc


krata:
      include krata.inc

title_screen:
      call blackpal
      xor ax,ax
      mov es,ax
      mov di,4000h
      xor ax,ax
      out 10h,al
      out 11h,al
      out 12h,al
      out 13h,al
      cld
      mov cx,16*18
      rep stosw ; zerowy znaczek

      mov al,1
      out 0,al
      xor al,al
      out 1,al
      mov al,21h
      out 7,al  ; scrloc 800,1000

      mov di,800h
      mov cx,1024
      xor ax,ax
      rep stosw

      mov ax,8000h
      mov ds,ax

      mov si,offset fonty
      mov di,4000h+256*32
      xor ax,ax
      mov cx,16
      rep stosw
      mov cx,512*16
      rep movsw


      mov cl,'C'
      mov ch,1
      mov ax,0402h
      call print

      mov cl,'O'
      mov ch,1
      mov ax,0404h
      call print


      mov cl,'D'
      mov ch,1
      mov ax,0406h
      call print


      mov cl,'E'
      mov ch,1
      mov ax,0408h
      call print


      mov cl,'A'
      mov ch,1
      mov ax,040ch
      call print

      mov cl,'N'
      mov ch,1
      mov ax,040eh
      call print


      mov cl,'D'
      mov ch,1
      mov ax,0410h
      call print


      mov cl,'G'
      mov ch,1
      mov ax,0414h
      call print

      mov cl,'F'
      mov ch,1
      mov ax,0416h
      call print

      mov cl,'X'
      mov ch,1
      mov ax,0418h
      call print


      mov cl,'D'
      mov ch,2
      mov ax,080bh
      call print

      mov cl,'O'
      mov ch,2
      mov ax,080dh
      call print

      mov cl,'X'
      mov ch,2
      mov ax,080fh
      call print


      mov cl,'D'
      mov ch,2
      mov ax,0c02h
      call print

      mov cl,'O'
      mov ch,2
      mov ax,0c04h
      call print

      mov cl,'X'
      mov ch,2
      mov ax,0c06h
      call print

      mov cl,'h'
      mov ch,1
      mov ax,0c08h
      call print

      mov cl,'S'
      mov ch,2
      mov ax,0c0ah
      call print

      mov cl,'P'
      mov ch,2
      mov ax,0c0ch
      call print


      mov cl,'A'
      mov ch,2
      mov ax,0c0eh
      call print

      mov cl,'C'
      mov ch,2
      mov ax,0c10h
      call print

      mov cl,'E'
      mov ch,2
      mov ax,0c12h
      call print


      mov cl,'e'
      mov ch,1
      mov ax,0c14h
      call print

      mov cl,'P'
      mov ch,2
      mov ax,0c16h
      call print

      mov cl,'L'
      mov ch,2
      mov ax,0c18h
      call print

      mov ax,offset ts_pal
      call setpal

      ;czekamy

      mov ax,150
      call wait_frames

      xor ax,ax
      mov es,ax

      mov di,800h
      mov cx,1024
      xor ax,ax
      rep stosw



      mov cl,'L'
      mov ch,1
      mov ax,0408h
      call print

      mov cl,'E'
      mov ch,1
      mov ax,040ah
      call print


      mov cl,'V'
      mov ch,1
      mov ax,040ch
      call print


      mov cl,'E'
      mov ch,1
      mov ax,040eh
      call print


      mov cl,'L'
      mov ch,1
      mov ax,0410h
      call print

      mov cl,'S'
      mov ch,1
      mov ax,0412h
      call print


      mov cl,'K'
      mov ch,2
      mov ax,0808h
      call print


      mov cl,'O'
      mov ch,2
      mov ax,080ah
      call print

      mov cl,'J'
      mov ch,2
      mov ax,080ch
      call print

      mov cl,'O'
      mov ch,2
      mov ax,080eh
      call print


      mov cl,'T'
      mov ch,2
      mov ax,0810h
      call print

      mov cl,'E'
      mov ch,2
      mov ax,0812h
      call print






      mov cl,'W'
      mov ch,2
      mov ax,0c00h
      call print


      mov cl,'W'
      mov ch,2
      mov ax,0c02h
      call print

      mov cl,'W'
      mov ch,2
      mov ax,0c04h
      call print

      mov cl,'e'
      mov ch,1
      mov ax,0c06h
      call print

      mov cl,'P'
      mov ch,2
      mov ax,0c08h
      call print

      mov cl,'D'
      mov ch,2
      mov ax,0c0ah
      call print

      mov cl,'R'
      mov ch,2
      mov ax,0c0ch
      call print


      mov cl,'O'
      mov ch,2
      mov ax,0c0eh
      call print

      mov cl,'M'
      mov ch,2
      mov ax,0c10h
      call print

      mov cl,'S'
      mov ch,2
      mov ax,0c12h
      call print


      mov cl,'e'
      mov ch,1
      mov ax,0c14h
      call print

      mov cl,'C'
      mov ch,2
      mov ax,0c16h
      call print

      mov cl,'O'
      mov ch,2
      mov ax,0c18h
      call print

      mov cl,'M'
      mov ch,2
      mov ax,0c1ah
      call print

      mov ax,150
      jmp wait_frames

congratulations:
      call blackpal
      xor ax,ax
      mov es,ax
      mov di,4000h
      xor ax,ax
      out 10h,al
      out 11h,al
      out 12h,al
      out 13h,al
      cld
      mov cx,16*18
      rep stosw ; zerowy znaczek

      mov al,1
      out 0,al
      xor al,al
      out 1,al
      mov al,21h
      out 7,al  ; scrloc 800,1000

      mov di,800h
      mov cx,1024
      xor ax,ax
      rep stosw

      mov ax,8000h
      mov ds,ax

      mov si,offset fonty
      mov di,4000h+256*32
      xor ax,ax
      mov cx,16
      rep stosw
      mov cx,512*16
      rep movsw


      mov cl,'W'
      mov ch,1
      mov ax,0906h
      call print

      mov cl,'O'
      mov ch,2
      mov ax,0909h
      call print


      mov cl,'W'
      mov ch,3
      mov ax,090ch
      call print


      mov cl,'f'
      mov ch,1
      mov ax,0912h
      call print

      mov cl,'f'
      mov ch,2
      mov ax,0914h
      call print

      mov cl,'f'
      mov ch,3
      mov ax,0916h
      call print


      mov ax,offset ts_pal
      call setpal

dead_end:
      jmp dead_end

wait_frames:
      push ax
      mov al,100
      call wait_linia
      call wait_vbl
      pop ax
      dec ax
      jnz wait_frames
      ret

ts_pal:
      db 101,8,0,0,167,11,128,8,8,0,8,8
      db 136,0,204,12,220,12,207,10,15,0,240,0
      db 0,15,240,15,15,15,255,0

      db 86,0,255,15,253,15,233,15,192,13,160,12
      db 64,7,48,4,16,3,16,2,50,4,53,10
      db 103,11,69,11,68,11,17,8

      db 86,0,255,15,221,15,153,15,101,13,68,12
      db 50,7,33,4,16,3,16,2,50,4,53,10
      db 103,11,69,11,68,11,17,8

      db 86,0,255,15,223,13,159,8,109,6,111,3
      db 55,2,36,1,19,1,16,2,50,4,53,10
      db 103,11,69,11,255,15,102,6

      db 86,0,255,15,223,13,159,8,109,6,111,3
      db 55,2,36,1,19,1,16,2,50,4,53,10
      db 103,11,69,11,68,11,255,15


      END start