[ORG 0x00]	;코드의 시작 주소
[BITS 16]	;이하 코드는 16비트

SECTION .text	;text 섹션을 정의

jmp 0x1000:START	; CS 세그먼트 레지스터에0x1000복사하면서 START 레이블로 이동

SECTORCOUNT:	dw 0x0000	;현재  실행중인 섹터 번호 저장
TOTALSECTORCOUNT equ 1024	;가상 os의 총 섹터 수
				;최대 1152섹터(0x90000byte)까지 가능

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 코드영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


START:
	mov ax, cs
	mov ds, ax
	mov ax, 0xB800
	mov es, ax	;ES 세그먼트 레지스터에 비디오 메모리 주소 저장


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 각 섹터별로 코드 생성
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	%assign i 0	;반복문 인덱스로 이용하는 변수 초기화
	%rep TOTALSECTORCOUNT	; TOTALSECTORCOUNT에 저장된 값만큼 아래 코드 반복
		%assign i i + 1
		mov ax, 2		;한 문자는 2바이트.
		mul word[SECTORCOUNT]	;AX = AX * SECTORCOUNT
		mov si, ax		;즉 SI = 2 * SECTORCOUNT -> 다음문자 적힐 위치
		mov byte[es:si + (160*2)], '0' + (i % 10)	
					;비디오 시작주소에서부터 160*2만큼 더함.
					;= (한줄에 80자) x (문자크기 2바이트) x 2줄
					;세번째 줄에서 si 위치에 0을 표시.

		add word[SECTORCOUNT],1	;섹터 수 나타내는 인덱스 1 증가.

		%if i == TOTALSECTORCOUNT
			jmp $	;현재 위치에서 무한루프 수행
		%else
			jmp (0x1000 + i * 0x20): 0x0000	;다음 섹터 오프셋으로 이동
		%endif	;if문 끝

		times (512 - ($ - $$) % 512) db 0x00	; $는 현재 라인 주소
						; $$는 현재 섹션(.text)의 시작 주소
						; $ - $$는 현재 섹션을 기준으로 하는 오프셋.
						; 512 - ($ - $$)는 현재부터 주소 512까지
						; db 0x00은 Define 1 Byte 그리고 0x00 값 할당.
						; time 은 반복 수행
						; 현재 위치에서 주소 512까지 0x00으로 채움.
	%endrep		;반복문 끝
