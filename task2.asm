.386
code segment use16
assume cs:code

main:
   call clscreen   ;����
   mov ax, 0B800h
   mov es, ax
   mov bx, 0    ;ƫ�Ƶ�ַ
   mov al, 00h
   mov ah, 0Ch
   mov cx, 256  ;256��ASCII�ַ�ѭ��
   mov si, 0    ;the index of y
   mov di, 0    ;the index of x
   mov dl, 00h  ;��λ
   mov dh, 00h  ;ʮλ
   
draw:   
   ;��ʾASCII�뼰��Ӧ16��������
   mov word ptr es:[bx], ax ;draw symbol of ASCII
   push ax      ;����ԭֵ
    
   add bx, 2    ;��ʾ��λ
   mov al, dh
   cmp al, 9    ;�ж������ֻ�����ĸ
   ja l1        ;����ĸ��ת��l1
   add al, '0'  ;����ת�����ַ�����0��-��9��
   jmp s1
l1:
   sub al,10     
   add al,'A'   ;����ת�����ַ�����A��-��F��
s1:
   mov ah, 0Ah
   mov word ptr es:[bx], ax ;��ʮλ

   add bx, 2    ;��ʾ�ڶ�λ
   mov al, dl
   cmp al, 9    ;�ж������ֻ�����ĸ
   ja l2
   add al, '0'
   jmp s2
l2:
   sub al,10
   add al,'A'
s2:
   mov ah, 0Ah
   mov word ptr es:[bx], ax ;����λ

;ASCII���������һ��
   cmp dl,0Fh 
   je carry  ;��λΪF�����λ
   add dl,1  ;��λ��1�������λ
   jmp position
carry:
   mov dl, 0 ;��λ����
   add dh, 1 ;ʮλ��1

;������ʾ�ַ�����
position:
   push dx   ;����ASCII���Ӧ���ָ�ʮλ
   cmp si,24 ;�ж��Ƿ���Ҫ����
   je update 
   add si,1  ;ֻ���У�y�������
   jmp next  
update:
   mov si,0 ;���У�y��������
   add di,7 ;x�������

;ƫ�Ƶ�ַ����
next:   
   mov ax,80 ;y*80
   mov bx,si
   mul bx
   add ax,di ;y*80+x
   mov bx,2
   mul bx    ;(y*80+x)*2
   mov bx,ax 

   pop dx   ;�ָ�ASCII���Ӧ��ʮλ
   pop ax   ;�ָ���ַ

   add al,1��;��ʾ��һ��ASCII��
   mov ah,0Ch
   
   sub cx,1  ;�ж�ѭ������
   jnz draw  

   mov ah, 1   ;�����������
   int 21h
   mov ah, 4Ch
   int 21h

clscreen:   ;����
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
