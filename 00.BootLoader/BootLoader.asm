[ORG 0x00]	;코드의 시작 주소 지정
[BITS 16]	;이하 코드는 16비트 코드로 설정

SECTION .text	;text 섹션(세그먼트)정의

jmp 0x07C0:START;CS 세그먼트 레지스터에 0x07C0 복사하면서 START 레이블로 이등

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	MINT64 OS 관련 환경설정 값
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOTALSECTORCOUNT:	dw 0x02	;부트로더 제외 os 이미지 크기
				;최대 1152섹터(0x90000byte)까지 가능

KERNEL32SECTORCOUNT: dw 0x02	;보호모드 커널의 총 섹터 수

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
	mov ax, 0x07C0	;
	mov ds, ax	;
	mov ax, 0xB800	;
	mov es, ax	;

	
	mov ax, 0x0000	;
	mov ss, ax	;
	mov sp, 0xFFFE	;
	mov bp, 0xFFFE	;

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 화면 모두 지우고 속성값을 녹색으로 설정
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov si, 0	;

.SCREENCLEARLOOP:	; 화면 지우는 루프
	mov byte[es:si], 0		;es + si 위치에 0복사(문자 삭제)
	mov byte[es:si + 1], 0x0A	;es + si + 1 위치에 0x0A복사(밝은 녹색 글자설정)
	add si, 2			;si 값(문자 위치 인덱스) 증가
	cmp si, 80 * 25 * 2		;si값으로 화면 전체의 문자를 지웠는지 확인
	jl .SCREENCLEARLOOP		;다 안됬으면 루프 반복

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 화면 상단에 시작 메세지 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push MESSAGE1	;출력 메세지 주소 스택에 삽입
	push 0		;화면 y좌표 스택에 삽입
	push 0		;화면 x좌표 스택에 삽입
	call PRINTMESSAGE	; PRINTMESSAGE함수 호출
	add sp, 6	;삽입 파라미터 제거(스택포인터를 이동시키는것)

	   
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; OS 이미지 로딩한다는 메시지 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push IMAGELOADINGMESSAGE
	push 1
	push 0
	call PRINTMESSAGE
	add sp, 6


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크에서 os 이미지 로딩
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크 읽기전 먼저 리셋
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; BIOS Reset Function 호출
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 서비스 번호 0, 드라이브 번호(0=Floppy)
	mov ax, 0
	mov dl, 0
	int 0x13
	jc HANDLEDISKERROR	;에러발생 시 에러 처리로 이동

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크에서 섹터를 읽음
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크의 내용을 메모리로 복사할 주소(ES:BX)를0x10000으로 설정
	mov si, 0x1000		; OS이미지를 복사할 주소(0x10000)를
				; 세그먼트 레지스터 값으로 변환
	mov es, si		; ES 세그먼트 레지스터에 값 설정
	mov bx, 0x0000		; BX 레지스터에 0x0000을 설정하여 복사할 주소를
				; 0x1000:0000(0x10000)으로 최종 설정

	mov di, word[TOTALSECTORCOUNT]	;복사할 OS이미지의 섹터 수를 DI 레지스터에 설정

READDATA:			; 디스크를 읽는 코드의 시작
	;모든 섹터를 다 읽었는지 확인
	cmp di, 0
	je READEND
	sub di, 0x1	;복사할 섹터 수를 1 감소

	 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; BIOS Read Function 호출
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ah, 0x02	;
	mov al, 0x1	;
	mov ch, byte[TRACKNUMBER]	;
	mov cl, byte[SECTORNUMBER]	;
	mov dh, byte[HEADNUMBER]	;
	mov dl, 0x00	;
	int 0x13	;
	jc HANDLEDISKERROR	;


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 복사할 주소와 트랙, 헤드, 섹터 주소 계산
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	add si, 0x0020	;
	mov es, si	;
	

	mov al, byte[SECTORNUMBER]	;
	add al, 0x01	;
	mov byte[SECTORNUMBER], al	;
	cmp al, 19	;
	jl READDATA	;


	xor byte[HEADNUMBER], 0x01	;
	mov byte[SECTORNUMBER], 0x01	;

	
	cmp byte[HEADNUMBER], 0X00	;
	jne READDATA	;
	
	add byte[TRACKNUMBER], 0x01	;
	jmp READDATA	;
READEND:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; OS이미지가 완료되었다는 메세지 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push LOADINGCOMPLETEMESSAGE	;
	push 1
	push 20
	call PRINTMESSAGE
	add sp, 6
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 로딩한 가상 os 이미지 실행
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp 0x1000:0x0000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 함수 코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;디스크 에러 처리 함수
HANDLEDISKERROR:
	push DISKERRORMESSAGE	;
	push 1	;
	push 20	;
	call PRINTMESSAGE	;

	jmp $	;

PRINTMESSAGE:
	push bp	;
	mov bp, sp	;
	
	push es
	push si
	push di
	push ax
	push cx
	push dx
	
	mov ax, 0xB800	;
	mov es, ax	;

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; X, Y 의 좌표로 비디오 메모리 주소 계산
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Y 좌표를 이용해 먼저 라인 주소 구함
	mov ax, word[bp + 6]	;(ax에 y좌표 설정)
	mov si, 160	; 한 라인의 바이트 수(2 * 80)
	mul si		
	mov di,ax	; 계산된 Y 주소를 di 레지스터에 설정

	;X 좌표 이용해 2를 곱한 후 최종 주소 구함
	mov ax, word[bp + 4]	; ax에 x좌표 설정
	mov si, 2	;
	mul si	;
	add di, ax	; 기존 계산된 Y위치에 x를 더함.

	; 출력할 문자열의 주소
	mov si, word[bp + 8]

.MESSAGELOOP:
	mov cl, byte[si]
	
	cmp cl, 0
	je .MESSAGEEND
	
	mov byte[es:di], cl

	add si, 1
	add di, 2

	jmp .MESSAGELOOP

.MESSAGEEND:
	pop dx
	pop cx
	pop ax
	pop di
	pop si
	pop es
	pop bp
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 데이터 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 부트로더 시작 메세지
MESSAGE1:	db 'MINT64 OS Boot Loader Start', 0 ;마지막은 0으로 해서 문자열 종료를 나타냄

DISKERRORMESSAGE:	db 'DISK Error',0
IMAGELOADINGMESSAGE:	db 'OS Image Loading...',0
LOADINGCOMPLETEMESSAGE:	db 'Complete.',0

;디스크 읽기 관련 변수들
SECTORNUMBER:	db 0x02	;OS 이미지 시작 섹터 번호
HEADNUMBER:	db 0x00 ;OS 이미지 시작 헤드 번호
TRACKNUMBER:	db 0x00	;OS 이미지 시작 트랙 번호

times 510 - ($ - $$) db 0x00



;부트 섹터로 표기
db 0x55
db 0xAA

	
	
