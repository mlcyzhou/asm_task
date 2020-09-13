.386
data segment use16
;提示信息
finput db 'Please input filename:',0Dh,0Ah,'$',0
ferror db 'Cannot open file!',0Dh,0Ah,'$',0
;文件句柄
handle dw 0
;文件处理变量名
file_size dd 0
offset_n dd 0
offset_t dd 0
bytes_in_buf dw 0
bytes_on_row dw 0
;文件显示字符串
s db "00000000:            |           |           |                             ",0
p db "00000000:            |           |           |                             ",0
t db "0123456789ABCDEF",0
;数据缓冲区
buf db 255
    db ?
    db 255 dup(?)
data ends
code segment use16
assume cs:code, ds:data
main:
    mov ax,data
    mov ds,ax
    ;显示输入提示信息
    mov ah,9
    lea dx,finput
    int 21h 
    ;输入文件名
    lea dx,buf
    mov ah,0Ah
    int 21h
    ;在输入字符串末尾加上0
    lea bx,buf+2
    add bl,buf+1
    adc bh,0
    mov byte ptr [bx],0
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'回车
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'换行
    ; 打开文件
    mov ah,3Dh
    mov al,0 ;只读
    lea dx,buf
    add dx,2
    int 21h
    mov handle,ax
    jnc next   
    mov ah,9   
    lea dx,ferror  ;未成功打开,输出报错信息
    int 21h 
    jmp exit0
next:              ;成功打开文件
    ;计算文件大小
    mov ah,42h
    mov al,2   ;以文档末尾为参照点移动
    mov bx,handle
    mov cx,0    ;初始偏移位置
    mov dx,0
    int 21h
    mov word ptr file_size[2],dx  ;存储到file_size中，文件大小为dx:ax
    mov word ptr file_size[0],ax
loop0:
    ;计算缓存区字节数
    mov eax,file_size
    mov edx,offset_n
    sub eax,edx
    cmp ah,0
    ja aboveFF
    mov bytes_in_buf,ax  ;未满256个
    jmp lmove
aboveFF:
    mov word ptr bytes_in_buf,256
lmove:
    mov ah,42h
    mov al,0  ;从文件头为参照点移动offset个字节
    mov bx,handle
    mov cx,word ptr offset_n[2]
    mov dx,word ptr offset_n[0]
    int 21h
    ;读取文件中的bytes_in_buf个字节到buf中
    mov ah,3Fh
    mov bx,handle
    mov cx,bytes_in_buf
    mov dx,offset buf
    int 21h
    ;展示文件内容
    call CLRscreen   ;清屏
    call Show  ;显示文件内容
    ;键盘输入
    mov ah,0 
    int 16h
    cmp ax,011Bh  ;Esc = 011Bh，关闭文件
    jne isPU
    jmp closef
isPU:
    cmp ax,4900h  ;PageUp = 4900h，翻上一页
    jne isPD
    mov edx,offset_n
    cmp edx,256  ;判断是否为第一页
    jb iszero
    sub edx,256
    mov offset_n,edx
    jmp keyend
iszero: 
    mov offset_n,0  ;首页不动
    jmp keyend
isPD:
    cmp ax,5100h   ;PageDown = 5100h，翻下一页
    jne isHome
    mov edx,offset_n
    add edx,256
    cmp edx,file_size
    jae keyend        ;若为最后一页，不动
    mov offset_n,edx
    jmp keyend
isHome:
    cmp ax,4700h   ;Home = 4700h，回到开头页
    jne isEnd
    mov offset_n,0
    jmp keyend
isEnd:
    cmp ax,4F00h    ;End = 4F00h，回到末尾页
    jne keyend  
    mov eax,file_size
    mov edx,0
    mov bx,256
    div bx
    mov eax,file_size  
    cmp edx,0        
    je full
    jmp nextstep
full:         ;文件字节数正好填满每一页，则需额外-256调到上一页
    mov edx,256
nextstep:
    sub eax,edx
    mov offset_n,eax
keyend:
    jmp loop0
    
    ;关闭文件
closef:
    mov ah,3Eh
    mov bx,handle
    int 21h
    call CLRscreen
    jmp exit0
exit0:
    mov ah,4Ch
    mov al,0
    int 21h
;清屏
CLRscreen:
   mov ax, 0B800h
   mov es, ax
   mov di, 0
   mov cx, 2000
again:
   mov byte ptr es:[di],' '
   mov byte ptr es:[di+1],0
   add di,2
   sub cx,1
   jnz again
   ret 
;显示文件内容
Show:
   ;计算当前页的行数
   mov ax,bytes_in_buf
   add ax,15
   mov bl,16
   div bl  ;al...ah,al为总行数
   movzx ax,al  
   mov bx,0  ;bx为遍历行数的索引
loop_row:
   mov dx,ax
   push ax
   push dx
   mov ax,bx
   mov dl,16
   mul dl
   mov bp,ax ;计算bp=bx*16
   ;计算当前行的字节数
   pop dx
   dec dx   
   cmp bx,dx
   jne ntrue
   mov ax,bytes_in_buf  ;计算最后一行字节数
   sub ax,bp
   mov bytes_on_row,ax
   jmp para_ready
ntrue:
   mov word ptr bytes_on_row,16  ;非最后一行都为16字节
para_ready:  
   mov eax,offset_n   ;保留offset原值
   mov dx,bp 
   movzx edx,dx
   add eax,edx      
   mov offset_t,eax   ;为遍历每行做准备
   call Show1Row
   inc bx
   pop ax
   cmp bx,ax
   jb loop_row
   ret 
;显示单独一行的状态
Show1Row:
   push bx   ;bx作为当前行数需要保护
   ;恢复s的初始状态
   mov si,0
renew:
   mov al,p[si]
   mov s[si],al
   inc si
   cmp al,0
   jne renew
   ;将偏移地址写入显示字符s
   mov eax,offset_t
   mov cx,8
p1:   
   rol eax,4
   push eax
   mov di,cx
   sub di,8
   neg di   ;di=8-cx
   and ax,0Fh
   mov si,ax
   mov dl,t[si] ;数字转化为16进制字符
   mov s[di],dl
   pop eax
   dec cx
   cmp cx,0
   jne p1
   ;将后续内容填入s中
   mov cx,bytes_on_row
   mov di,0   ;用于记录每行的字节数
p2:
   mov ax,di
   mov bl,3
   mul bl
   add ax,10
   mov si,ax   ;s[10+di*3]，si为用于记录数组buf各元素16进制格式的索引
   ;把buf中各个字节转化成16进制格式填入s中的xx处
   mov al,buf[di+bp]
   mov ah,0
   push ax
   rol al,4
   and ax,0Fh
   mov bx,ax
   mov dl,t[bx]
   mov s[si],dl  ;将buf[di]的首位转化为16进制字符
   pop ax
   and ax,0Fh
   mov bx,ax
   mov dl,t[bx]
   mov s[si+1],dl   ;将buf[di]的个位转化为16进制字符
   ;把buf中各个字节填入s右侧小数点处
   mov al,buf[di+bp]
   mov s[59+di],al
   inc di
   dec cx
   cmp cx,0
   jne p2
   ;显示到屏幕上
   mov ax, 0B800h
   mov es, ax
   mov si,0
   mov ax,bp
   mov bl,10
   mul bl
   mov di,ax  ;di为当前行对应偏移地址
show_byte:
   mov al,s[si]
   cmp al,0
   je ShowEnd
   mov byte ptr es:[di],al
   cmp al,'|'  ;检查是否为用于隔断的高亮度白色竖线
   jne iswhite
   cmp si,59
   jae iswhite
   mov byte ptr es:[di+1],0Fh  ;高亮白色    
   jmp snext
iswhite:
   mov byte ptr es:[di+1],07h ;普通白色
snext:
   inc si
   add di,2
   jmp show_byte
ShowEnd:
   pop bx
   ret

code ends
end main
