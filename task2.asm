.386
code segment use16
assume cs:code

main:
   call clscreen   ;清屏
   mov ax, 0B800h
   mov es, ax
   mov bx, 0    ;偏移地址
   mov al, 00h
   mov ah, 0Ch
   mov cx, 256  ;256个ASCII字符循环
   mov si, 0    ;the index of y
   mov di, 0    ;the index of x
   mov dl, 00h  ;个位
   mov dh, 00h  ;十位
   
draw:   
   ;显示ASCII码及对应16进制数字
   mov word ptr es:[bx], ax ;draw symbol of ASCII
   push ax      ;保留原值
    
   add bx, 2    ;显示首位
   mov al, dh
   cmp al, 9    ;判断是数字还是字母
   ja l1        ;是字母跳转到l1
   add al, '0'  ;整数转化成字符串‘0’-‘9’
   jmp s1
l1:
   sub al,10     
   add al,'A'   ;整数转换成字符串‘A’-‘F’
s1:
   mov ah, 0Ah
   mov word ptr es:[bx], ax ;画十位

   add bx, 2    ;显示第二位
   mov al, dl
   cmp al, 9    ;判断是数字还是字母
   ja l2
   add al, '0'
   jmp s2
l2:
   sub al,10
   add al,'A'
s2:
   mov ah, 0Ah
   mov word ptr es:[bx], ax ;画个位

;ASCII码更新至下一个
   cmp dl,0Fh 
   je carry  ;个位为F，需进位
   add dl,1  ;个位加1，无需进位
   jmp position
carry:
   mov dl, 0 ;个位清零
   add dh, 1 ;十位进1

;更新显示字符坐标
position:
   push dx   ;保存ASCII码对应数字个十位
   cmp si,24 ;判断是否需要换列
   je update 
   add si,1  ;只换行，y坐标更新
   jmp next  
update:
   mov si,0 ;换列，y坐标清零
   add di,7 ;x坐标更新

;偏移地址计算
next:   
   mov ax,80 ;y*80
   mov bx,si
   mul bx
   add ax,di ;y*80+x
   mov bx,2
   mul bx    ;(y*80+x)*2
   mov bx,ax 

   pop dx   ;恢复ASCII码对应个十位
   pop ax   ;恢复地址

   add al,1　;显示下一个ASCII码
   mov ah,0Ch
   
   sub cx,1  ;判断循环条件
   jnz draw  

   mov ah, 1   ;按任意键继续
   int 21h
   mov ah, 4Ch
   int 21h

clscreen:   ;清屏
   mov ax, 0B800h
   mov es, ax
   mov di, 0
   mov cx, 2000 
again:
   mov byte ptr es:[edi],' '
   add di,2
   sub cx,1
   jnz again
   ret

code ends   
end main
