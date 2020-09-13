.386
data segment use16
s db 100 dup(0),0Dh,0Ah,'$'
t db 100 dup(0),0Dh,0Ah,'$'
data ends
code segment use16
assume cs:code, ds:data
main:
    mov ax, data
    mov ds, ax
    mov si, 0	;si:s'index
    mov di, 0	;di:t'index
input:
    mov ah, 1
    int 21h       ;Al=getchar()
    cmp al, 0Dh   ;if '\n' stop input and go input_end
    je input_end
    mov s[si], al ;save in s
    add si, 1     ;si++
    jmp input
input_end:
    mov s[si], 0  ;change '\n' to 00h

    mov si, 0   
process:
    mov al, s[si] ;al=s[si]
    add si, 1
    cmp al, ' '   ;if al=' ',continue to next loop
    je process
    cmp al, 'a'   ;if al<'a',save straight in t[di]
    jb save
    cmp al, 'z'   ;if al>'z',save straight in t[di]
    ja save
    sub al, 20h   ;al is lower case ,do al-20h to change to upper ones
save:
    mov t[di], al ;save in t[di]
    add di, 1
    cmp s[si], 0  ;judge the end of string
    jne process   
   
    mov ah, 2
    mov dl, 0Dh
    int 21h       ;output '\r'»Ø³µ
    mov ah, 2
    mov dl, 0Ah
    int 21h       ;output '\n'»»ÐÐ

    mov di, 0
output:
    mov dl, t[di]
    cmp dl, 0     ;judge the end of string
    je output_end  
    mov ah, 2
    int 21h       ;output the result
    add di, 1
    jmp output
output_end:
    mov ah, 4Ch
    int 21h

code ends
end main


    