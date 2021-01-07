[ORG 0x00]	;코드 시작 주소
[BITS 16]	;이하 코드 16비트

SECTION .text	;text 섹션(세그먼트) 정의

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
	mov ax, 0x1000	;보호모드 엔트리 포인트 시작 주소 0x10000의 레지스터값.
	mov ds, ax	;0x1000
	mov es, ax	;0x1000

	cli		;인터럽트 발생 못하도록 설정
	lgdt[GDTR]	;GDTR 자료구조를 프로세서에 설정하여 GDT테이블 로드
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 보호모드로 진입
	; Disable paging, cache, Internal FPU, Align Check
	; Enable ProtectedMode
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, 0x4000003B	;PG=0 CD=1 NW=0 AM=0 WP=0 NE=1 ET=1 TS=1 EM=0 MP=1 PE=1
	mov cr0, eax		;CR0 컨트롤 레지스터에 위에서 정한 플래그 설정
				;보호모드 전환
	
	;커널 코드 세그먼트를 0x00을 기준으로 하는것으로 교체, EIP값을 0x00기준으로 재설정
	;CS세그먼트 셀렉터: EIP
	jmp dword 0x08:(PROTECTMODE - $$ + 0x10000)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 보호모드로 진입
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]	;이하 코드 32비트 설정
PROTECTMODE:
	mov ax, 0x10	;보호모드 커널용 데이터 세그먼트 디스크립터를 AX레지스터에 저장
			;아래 세그먼트 셀렉터들에 설정
	mov ds, ax	
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	;스택을 0x00000000~0x0000FFFF영역에 64kb 크기로 생성
	mov ss, ax
	mov esp, 0xFFFE
	mov ebp, 0xFFFE

	;화면에 보호모드 전환 메시지 출력
	push (SWITCHSUCCESSMESSAGE - $$ + 0X10000)	;출력할 메시지 주소 스택에 삽입
	push 2						;화면 Y좌표 스택 삽입
	push 0						;화면 X좌표 스택 삽입
	call PRINTMESSAGE				;함수 호출
	add esp, 12					;삽입 파라미터 제거(4x3)
	jmp $						;현재 위치 무한루프 수행


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 함수 코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;메시지 출력 함수
PRINTMESSAGE:
	push ebp	;베이스 포인터 레지스터 스택 삽입
	mov ebp, esp	;베이스 포인터 레지스터에 스택 포인터 레지스터 값으로 갱신
	push esi	;함수에서 쓸 레지스터들 기존 데이터 스택에 백업
	push edi	
	push eax
	push ecx
	push edx

	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;X, Y의 좌표로 비디오 메모리 주소 계산
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;Y좌표 이용해서 라인 주소 구함.
	mov eax, dword[ebp + 12]	;아까 스택에 넣었던 Y좌표값 가져오기 
	mov esi, 160			;한 라인의 바이트 수.
	mul esi				;Y 좌표값 x 라인 크기 = Y 좌표 주소계산
	mov edi, eax			;EDI 레지스터에 설정
	
	;X좌표 이용하서 2를 곱한 후 최종 주소 구함
	mov eax, dword[ebp + 8]		;아까 스택에 넣었던 X좌표값 가져오기
	mov esi, 2			;한 문자를 나타내는 바이트 수
	mul esi				;X좌표값 x 문자 크기 = X 좌표 주소계산
	add edi, eax			;X좌표 주소 + Y좌표 주소 = 최종 좌표 주소
	
	;출력할 문자열의 주소
	mov esi, dword[ebp + 16]	;아까 스택에 넣었던 출력할 메시지 주소 가져오기

.MESSAGELOOP:				;메시지 출력 루프
	mov cl, byte[esi]		;메시지 주소에서 문자하나 CL에 복사
	cmp cl, 0			;문자를 0과 비교
	je .MESSAGEEND			;0이면 문자열 끝난것.
	mov byte [edi + 0xB8000], cl	;0이 아니면 아까 구한 좌표에 문자 출력
		
	add esi, 1			;다음 문자 주소 계산
	add edi, 2			;다음 좌표 계산
	jmp .MESSAGELOOP		;반복.

.MESSAGEEND:
	pop edx		;함수 끝나고 레지스터 값 복원
	pop ecx
	pop eax
	pop edi
	pop esi
	pop ebp	
	ret		;함수 호출했던 위치로 돌아감.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 데이터 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;아래 데이터들을 8바이트에 맞춰 정렬하기 위해 추가
align 8, db 0

;GDTR의 끝을 8바이트로 정렬하기 위해 추가
dw 0x0000

;GDTR 자료구조 정의
GDTR:
	dw GDTEND - GDT - 1		;아래에 위치하는 GDT테이블의 전체 크기
	dd (GDT - $$ + 0x10000)		;아래에 위치하는 GDT테이블의 시작 주소

;GDT테이블 정의
GDT:
	; 널 디스크립터. 반드시 0으로 초기화
	NULLDescriptor:
		dw 0x0000
		dw 0x0000
		db 0x00
		db 0x00
		db 0x00
		db 0x00

	;보호모드 커널용 코드 세그먼트 디스크립터
	CODEDESCRIPTOR:
		dw 0xFFFF	;Limit	[15:0]
		dw 0x0000	;Base	[15:0]
		db 0x00		;Base	[23,16]
		db 0x9A		;P=1, DPL=0, Code Segment, Execute/Read
		db 0xCF		;G=1, D=1, L=0, Limit[19,16]
		db 0x00		;Base	[31:24]

	;보호모드 커널용 데이터 세그먼트 디스크립터
	DATADESCRIPTOR:
		dw 0xFFFF	;Limit	[15:0]
		dw 0x0000	;Base	[15:0]
		db 0x00		;Base	[23:16]
		db 0x92		;P=1, DPL=0, Data Segment, Read/Write
		db 0xCF		;G=1, D=1, L=1, Limit[19,16]
		db 0x00		;Base	[31,24]
	GDTEND:

	;보호모드로 전환되었다는 메시지
	SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success', 0

	times 512 - ($ - $$) db 0x00	;512바이트 맞추기 위해 남은부분 0으로 채움
	
