.386
data segment use16
;��ʾ��Ϣ
finput db 'Please input filename:',0Dh,0Ah,'$',0
ferror db 'Cannot open file!',0Dh,0Ah,'$',0
;�ļ����
handle dw 0
;�ļ����������
file_size dd 0
offset_n dd 0
offset_t dd 0
bytes_in_buf dw 0
bytes_on_row dw 0
;�ļ���ʾ�ַ���
s db "00000000:            |           |           |                             ",0
p db "00000000:            |           |           |                             ",0
t db "0123456789ABCDEF",0
;���ݻ�����
buf db 255
    db ?
    db 255 dup(?)
data ends
code segment use16
assume cs:code, ds:data
main:
    mov ax,data
    mov ds,ax
    ;��ʾ������ʾ��Ϣ
    mov ah,9
    lea dx,finput
    int 21h 
    ;�����ļ���
    lea dx,buf
    mov ah,0Ah
    int 21h
    ;�������ַ���ĩβ����0
    lea bx,buf+2
    add bl,buf+1
    adc bh,0
    mov byte ptr [bx],0
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'�س�
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'����
    ; ���ļ�
    mov ah,3Dh
    mov al,0 ;ֻ��
    lea dx,buf
    add dx,2
    int 21h
    mov handle,ax
    jnc next   
    mov ah,9   
    lea dx,ferror  ;δ�ɹ���,���������Ϣ
    int 21h 
    jmp exit0
next:              ;�ɹ����ļ�
    ;�����ļ���С
    mov ah,42h
    mov al,2   ;���ĵ�ĩβΪ���յ��ƶ�
    mov bx,handle
    mov cx,0    ;��ʼƫ��λ��
    mov dx,0
    int 21h
    mov word ptr file_size[2],dx  ;�洢��file_size�У��ļ���СΪdx:ax
    mov word ptr file_size[0],ax
loop0:
    ;���㻺�����ֽ���
    mov eax,file_size
    mov edx,offset_n
    sub eax,edx
    cmp ah,0
    ja aboveFF
    mov bytes_in_buf,ax  ;δ��256��
    jmp lmove
aboveFF:
    mov word ptr bytes_in_buf,256
lmove:
    mov ah,42h
    mov al,0  ;���ļ�ͷΪ���յ��ƶ�offset���ֽ�
    mov bx,handle
    mov cx,word ptr offset_n[2]
    mov dx,word ptr offset_n[0]
    int 21h
    ;��ȡ�ļ��е�bytes_in_buf���ֽڵ�buf��
    mov ah,3Fh
    mov bx,handle
    mov cx,bytes_in_buf
    mov dx,offset buf
    int 21h
    ;չʾ�ļ�����
    call CLRscreen   ;����
    call Show  ;��ʾ�ļ�����
    ;��������
    mov ah,0 
    int 16h
    cmp ax,011Bh  ;Esc = 011Bh���ر��ļ�
    jne isPU
    jmp closef
isPU:
    cmp ax,4900h  ;PageUp = 4900h������һҳ
    jne isPD
    mov edx,offset_n
    cmp edx,256  ;�ж��Ƿ�Ϊ��һҳ
    jb iszero
    sub edx,256
    mov offset_n,edx
    jmp keyend
iszero: 
    mov offset_n,0  ;��ҳ����
    jmp keyend
isPD:
    cmp ax,5100h   ;PageDown = 5100h������һҳ
    jne isHome
    mov edx,offset_n
    add edx,256
    cmp edx,file_size
    jae keyend        ;��Ϊ���һҳ������
    mov offset_n,edx
    jmp keyend
isHome:
    cmp ax,4700h   ;Home = 4700h���ص���ͷҳ
    jne isEnd
    mov offset_n,0
    jmp keyend
isEnd:
    cmp ax,4F00h    ;End = 4F00h���ص�ĩβҳ
    jne keyend  
    mov eax,file_size
    mov edx,0
    mov bx,256
    div bx
    mov eax,file_size  
    cmp edx,0        
    je full
    jmp nextstep
full:         ;�ļ��ֽ�����������ÿһҳ���������-256������һҳ
    mov edx,256
nextstep:
    sub eax,edx
    mov offset_n,eax
keyend:
    jmp loop0
    
    ;�ر��ļ�
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
;����
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
;��ʾ�ļ�����
Show:
   ;���㵱ǰҳ������
   mov ax,bytes_in_buf
   add ax,15
   mov bl,16
   div bl  ;al...ah,alΪ������
   movzx ax,al  
   mov bx,0  ;bxΪ��������������
loop_row:
   mov dx,ax
   push ax
   push dx
   mov ax,bx
   mov dl,16
   mul dl
   mov bp,ax ;����bp=bx*16
   ;���㵱ǰ�е��ֽ���
   pop dx
   dec dx   
   cmp bx,dx
   jne ntrue
   mov ax,bytes_in_buf  ;�������һ���ֽ���
   sub ax,bp
   mov bytes_on_row,ax
   jmp para_ready
ntrue:
   mov word ptr bytes_on_row,16  ;�����һ�ж�Ϊ16�ֽ�
para_ready:  
   mov eax,offset_n   ;����offsetԭֵ
   mov dx,bp 
   movzx edx,dx
   add eax,edx      
   mov offset_t,eax   ;Ϊ����ÿ����׼��
   call Show1Row
   inc bx
   pop ax
   cmp bx,ax
   jb loop_row
   ret 
;��ʾ����һ�е�״̬
Show1Row:
   push bx   ;bx��Ϊ��ǰ������Ҫ����
   ;�ָ�s�ĳ�ʼ״̬
   mov si,0
renew:
   mov al,p[si]
   mov s[si],al
   inc si
   cmp al,0
   jne renew
   ;��ƫ�Ƶ�ַд����ʾ�ַ�s
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
   mov dl,t[si] ;����ת��Ϊ16�����ַ�
   mov s[di],dl
   pop eax
   dec cx
   cmp cx,0
   jne p1
   ;��������������s��
   mov cx,bytes_on_row
   mov di,0   ;���ڼ�¼ÿ�е��ֽ���
p2:
   mov ax,di
   mov bl,3
   mul bl
   add ax,10
   mov si,ax   ;s[10+di*3]��siΪ���ڼ�¼����buf��Ԫ��16���Ƹ�ʽ������
   ;��buf�и����ֽ�ת����16���Ƹ�ʽ����s�е�xx��
   mov al,buf[di+bp]
   mov ah,0
   push ax
   rol al,4
   and ax,0Fh
   mov bx,ax
   mov dl,t[bx]
   mov s[si],dl  ;��buf[di]����λת��Ϊ16�����ַ�
   pop ax
   and ax,0Fh
   mov bx,ax
   mov dl,t[bx]
   mov s[si+1],dl   ;��buf[di]�ĸ�λת��Ϊ16�����ַ�
   ;��buf�и����ֽ�����s�Ҳ�С���㴦
   mov al,buf[di+bp]
   mov s[59+di],al
   inc di
   dec cx
   cmp cx,0
   jne p2
   ;��ʾ����Ļ��
   mov ax, 0B800h
   mov es, ax
   mov si,0
   mov ax,bp
   mov bl,10
   mul bl
   mov di,ax  ;diΪ��ǰ�ж�Ӧƫ�Ƶ�ַ
show_byte:
   mov al,s[si]
   cmp al,0
   je ShowEnd
   mov byte ptr es:[di],al
   cmp al,'|'  ;����Ƿ�Ϊ���ڸ��ϵĸ����Ȱ�ɫ����
   jne iswhite
   cmp si,59
   jae iswhite
   mov byte ptr es:[di+1],0Fh  ;������ɫ    
   jmp snext
iswhite:
   mov byte ptr es:[di+1],07h ;��ͨ��ɫ
snext:
   inc si
   add di,2
   jmp show_byte
ShowEnd:
   pop bx
   ret

code ends
end main
