.386
data segment use16
buf db 6    ;�������ַ�����5��
    db ?    ;���ʵ�������ַ�����
    db 6 dup(?) ;��������ַ�
input dw 2 dup(0)       ;�������16����16λ�Ƿ�����
result dd 1 dup(0)        ;���16���ƽ��
s db 10 dup(' '),0Dh,0Ah,'$'   ;���ʮ���ƽ���ַ�
data ends
code segment use16
assume cs:code, ds:data
main:
    mov ax,data
    mov ds,ax
    call input_two
    mov di,0  ;����input����
    mov eax,0
    mov edx,0
    mov ax,input[di]
    mov dx,input[di+2]
    mul edx    	;�����Ƿ�������ˣ����������eax��
    mov si,0
    mov result[si],eax   
    
    ;ʮ�������
    mov cx,0  ;ͳ��push����
    mov di,0   ;����s����
to_char_ten:
    mov edx,0  ;������edx:eax
    mov ebx,10 
    div ebx	;��eax������edx
    add dl,'0'
    push dx     ;�Ӹ�λ����λ˳�򱣴浽��ջ���Ա��������
    inc cx
    cmp eax,0
    jnz to_char_ten
pop_save:
    pop dx
    mov s[di],dl ;���浽������
    inc di
    dec cx
    jnz pop_save
    mov ah,9     ;����ַ���
    lea dx,s
    int 21h

    ;ʮ���������
    mov eax,result[si]
    mov cx,8  ;�ж��������
    push eax
again:
    pop eax
    rol eax,4
    push eax
    mov edx,0Fh ;���λѭ�����Ƶ���λ��"��"�������ȡֵ
    and edx,eax
    cmp dl,10   ;С��10,���֣�����10����ĸ
    jb is_digit
    add dl,'A'-10
    jmp output_16
is_digit:
    add dl,'0'
output_16:
    mov ah,02h  ;��λ����ַ�
    int 21h
    dec cx
    jnz again
    mov dl,'h'
    mov ah,02h   ;���16���Ʒ��š�h��
    int 21h     
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'�س�
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'����
    
    ;���������
    mov eax,result[si]
    mov cx,4    ;�ж�4�κ�����ո�
next:
    shl eax,1    ;���ƺ�ֱ�Ӹ���CF�ж�
    push eax
    jc is_one
    mov dl,'0'
    mov ah,02h   ;���0
    int 21h
    jmp step
is_one:
    mov dl,'1'
    mov ah,02h   ;���1
    int 21h  
step:
    pop eax
    dec cx      ;ѭ��4��
    jnz next
    push eax
    mov cx,4
    pop eax 
    cmp eax,0   ;�ж�2��������Ƿ����
    je end_2
    push eax
    mov dl,' '
    mov ah,02h   ;���' '
    int 21h
    pop eax
    jmp next
end_2:
    mov dl,'B'
    mov ah,02h   ;���'B'
    int 21h
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'�س�
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'����
    mov ah,1
    int 21h
    mov ah,4Ch
    int 21h
;���뺯��
;�����������<=0xFFFFh��ʮ���ƷǷ�����ת��Ϊ16���Ʋ��洢��������
input_two:
    mov cx,2    ;���������Ƿ�����
    mov di,0	;��������input����
input_one:
    lea dx,buf
    mov ah,0Ah  ;����һ���ַ���
    int 21h
    mov si,0    ;buff������ 
    mov bh,0
    mov bl,buf[si+1] ;��ȡʵ���������
    sub bl,1       ;bp��ȡ����λ����ĸ���
    mov bp,bx
    mov bx,0
    mov ax,0
    cmp bp,0  ;ֻ�и�λ����Ը�λ����������
    je last
to_digit:
    mov bl, buf[si+2] ;��Ҫ����buff����¼�ַ������������ֽ�
    sub bl, '0'	      ;�ַ�תΪ����
    add ax, bx	
    mov dx, 10
    mul dx 	      ;��λ���μӺͳ�10
    inc si
    cmp si,bp
    jnz to_digit
last:
    mov bl, buf[si+2]   ;���һλֱ�ӼӺͲ���10
    sub bl, '0'	
    add ax, bx
    mov input[di],ax	;���ת��Ϊ16���ƴ洢��input����
    add di, 2
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'�س�
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'����
    sub cx, 1
    jnz input_one
    ret
    
code ends
end main