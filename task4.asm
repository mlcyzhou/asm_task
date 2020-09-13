.386
data segment use16
buf db 6    ;存放最大字符个数5个
    db ?    ;存放实际输入字符个数
    db 6 dup(?) ;存放输入字符
input dw 2 dup(0)       ;存放两个16进制16位非符号数
result dd 1 dup(0)        ;存放16进制结果
s db 10 dup(' '),0Dh,0Ah,'$'   ;输出十进制结果字符
data ends
code segment use16
assume cs:code, ds:data
main:
    mov ax,data
    mov ds,ax
    call input_two
    mov di,0  ;数组input索引
    mov eax,0
    mov edx,0
    mov ax,input[di]
    mov dx,input[di+2]
    mul edx    	;两个非符号数相乘，结果储存在eax中
    mov si,0
    mov result[si],eax   
    
    ;十进制输出
    mov cx,0  ;统计push次数
    mov di,0   ;数组s索引
to_char_ten:
    mov edx,0  ;被除数edx:eax
    mov ebx,10 
    div ebx	;商eax，余数edx
    add dl,'0'
    push dx     ;从个位到首位顺序保存到堆栈，以便正序输出
    inc cx
    cmp eax,0
    jnz to_char_ten
pop_save:
    pop dx
    mov s[di],dl ;储存到数组中
    inc di
    dec cx
    jnz pop_save
    mov ah,9     ;输出字符串
    lea dx,s
    int 21h

    ;十六进制输出
    mov eax,result[si]
    mov cx,8  ;判断输出结束
    push eax
again:
    pop eax
    rol eax,4
    push eax
    mov edx,0Fh ;最高位循环左移到个位，"与"运算后提取值
    and edx,eax
    cmp dl,10   ;小于10,数字；大于10，字母
    jb is_digit
    add dl,'A'-10
    jmp output_16
is_digit:
    add dl,'0'
output_16:
    mov ah,02h  ;逐位输出字符
    int 21h
    dec cx
    jnz again
    mov dl,'h'
    mov ah,02h   ;输出16进制符号‘h’
    int 21h     
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'回车
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'换行
    
    ;二进制输出
    mov eax,result[si]
    mov cx,4    ;判断4次后输出空格
next:
    shl eax,1    ;左移后直接根据CF判断
    push eax
    jc is_one
    mov dl,'0'
    mov ah,02h   ;输出0
    int 21h
    jmp step
is_one:
    mov dl,'1'
    mov ah,02h   ;输出1
    int 21h  
step:
    pop eax
    dec cx      ;循环4次
    jnz next
    push eax
    mov cx,4
    pop eax 
    cmp eax,0   ;判断2进制输出是否结束
    je end_2
    push eax
    mov dl,' '
    mov ah,02h   ;输出' '
    int 21h
    pop eax
    jmp next
end_2:
    mov dl,'B'
    mov ah,02h   ;输出'B'
    int 21h
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'回车
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'换行
    mov ah,1
    int 21h
    mov ah,4Ch
    int 21h
;输入函数
;将输入的两个<=0xFFFFh的十进制非符号数转化为16进制并存储到数组里
input_two:
    mov cx,2    ;输入两个非符号数
    mov di,0	;储存数组input索引
input_one:
    lea dx,buf
    mov ah,0Ah  ;读入一行字符串
    int 21h
    mov si,0    ;buff区索引 
    mov bh,0
    mov bl,buf[si+1] ;获取实际输入个数
    sub bl,1       ;bp获取除个位以外的个数
    mov bp,bx
    mov bx,0
    mov ax,0
    cmp bp,0  ;只有个位，则对高位处理步骤跳过
    je last
to_digit:
    mov bl, buf[si+2] ;需要跳过buff区记录字符个数的两个字节
    sub bl, '0'	      ;字符转为数字
    add ax, bx	
    mov dx, 10
    mul dx 	      ;各位依次加和乘10
    inc si
    cmp si,bp
    jnz to_digit
last:
    mov bl, buf[si+2]   ;最后一位直接加和不乘10
    sub bl, '0'	
    add ax, bx
    mov input[di],ax	;结果转化为16进制存储在input数组
    add di, 2
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'回车
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'换行
    sub cx, 1
    jnz input_one
    ret
    
code ends
end main