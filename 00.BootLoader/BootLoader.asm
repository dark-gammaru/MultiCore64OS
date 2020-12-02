[ORG 0x00]	; 코드 시작 어드레스 0x00
[BITS 16]	; 이하 코드는 16비트 코드로 설정

SECTION .text	; text 섹션(세그먼트) 정의
jmp 0x07C0:START


START:
	mov ax, 0x07C0	; 부트로더의 시작 주소(0x7C00)를 세그먼트 레지스터 값으로 변환
	mov ds, ax	; DS 세그먼트 레지스터에 설정

	mov ax, 0xB800	; AX 레지스터에 0xB800 복사(비디오 메모리 시작 주소)
	mov es, ax	; ES 세그먼트 레지스터에 0xB800 복사

	mov si, 0	; SI 레지스터 초기화(문자열 원본)

.SCREENCLEARLOOP:	; 화면 지우는 루프
	mov byte[es:si], 0		;es + si 위치에 0복사(문자 삭제)
	mov byte[es:si + 1], 0x0A	;es + si + 1 위치에 0x0A복사(밝은 녹색 글자설정)
	add si, 2			;si 값(문자 위치 인덱스) 증가
	cmp si, 80 * 25 * 2		;si값으로 화면 전체의 문자를 지웠는지 확인
	jl .SCREENCLEARLOOP		;다 안됬으면 루프 반복


	mov si, 0	; SI 레지스터 초기화(문자열 원본)
	mov di, 0	; DI 레지스터 초기화(문자열 대상)

.MESSAGELOOP:		; 문자열 출력 루프
	mov cl, byte[si + MESSAGE1]	; CL레지스터는 CX의 하위 1바이트 의미.
					; 이 CL에 MESSAGE1의 SI번째 문자를 복사.

	cmp cl, 0 			; 문자의 끝을 의미하는 0과 같은지 비교
	je .MESSAGEEND			;

	mov byte[es:di],cl	;0이 아니면 0xb800 + di에 문자 출력
	add si, 1		;
	add di, 2		;
	jmp .MESSAGELOOP	;

.MESSAGEEND:
	jmp $		; 현재 위치에서 무한루프 수행

MESSAGE1:	DB 'HELLO MY CUSTOM OS', 0	; 출력 문자열 정의

;mov byte [es: 0x00], 'M'	; ES 세그먼트:오프셋 0xB800: 0x0000에 M을 복사, 여기에 es: 없으면 디폴트로 DS 세그먼트로 지정됨.
;mov byte [es: 0x01], 0x42	; ES 세그먼트:오프셋 0xB800: 0x0001에 0x4A(빨간배경에 밝은녹색)복사
;mov byte [es: 0x02], 'M'	; ES 세그먼트:오프셋 0xB800: 0x0002에 M을 복사
;mov byte [es: 0x03], 0x4A	; ES 세그먼트:오프셋 0xB800: 0x0003에 0x4A(빨간배경에 녹색)복사


times 510 - ($ - $$) db 0x00	; $: 현재 라인의 주소
				; $$: 현재 섹션(.text)의 시작 주소
				; $ - $$: 현재 섹션을 기준으로 하는 오프셋
				; 510 - ($ - $$): 현재부터 어드레스 510까지
				; time: 반복수행
				; 현재 위치에서 주소 510까지 0x00으로 채움

db 0x55		; 1바이트 선언하고 값 0x55
db 0xAA		; 1바이트 선언하고 갓 0xAA
		; 주속 511,512에 0x55, 0xAA 써서 부트섹터로 표기



