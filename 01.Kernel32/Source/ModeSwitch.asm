[BITS 32]	;이하 코드 32비트 코드로 설정

;C에서 호출가능하도록 이름 노출(Export)
global kReadCPUID, kSwitchAndExecute64BitKernel

SECTION .text	;text 섹션(세그먼트) 정의

; CPUID를 반환
; PARAM: DWORD dwEAX, DWORD* pdwEAX,* pdwEBX,* pdeECX,* pdwEDX
kReadCPUID:
	push ebp
	mov ebp, esp
	push eax
	push ebx
	push ecx
	push edx
	push esi

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;EAX 레지스터 값으로 CPUID 실행
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, dword[ebp + 8]	;파라미터 1(dwEAX)를 레지스터에 저장
	cpuid					;CPUID 명령어 실행
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;반환된 값을 파라미터에 저장
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *pdwEAX
	mov esi, dword[ebp + 12]
	mov dword[esi], eax

	; *pdwEBX
	mov esi, dword[ebp + 16]
	mov dword[esi], ebx

	; *pdwEBX
	mov esi, dword[ebp + 20]
	mov dword[esi], ecx

	; *pdwEBX
	mov esi, dword[ebp + 24]
	mov dword[esi], edx

	pop esi		;함수에서 사용 끝난 레지스터들 값 복원
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret			;함수 호출한 다음 코드로 복귀

;IA-32e모드로 전환하고 64비트 커널 수행
;PARAM: 없음
kSwitchAndExecute64bitKernel:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;CR4 컨트롤 레지스터의 PAE 비트 1로 설정
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, cr4
	or eax, 0x20
	mov cr4, eax

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;CR3 컨트롤 레지스터에 PML4 테이블의 주소와 캐시 활성화
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, 0x100000
	mov cr3, eax

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;IA32_EFER.LME를 1로 설정하여 IA-32e모드를 활성화
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx, 0xC0000080	;IA32_EFER MSR 레지스터 주소.
	rdmsr				;MSR 레지스터 읽기. eax 레지스터로 반환됨.
	or eax, 0X0100		;LME비트(비트8) 활성화
	wrmsr

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;캐시, 페이징 기능 활성화
	;CRO의 NW(비트 29) = 0, CD(비트 30) = 0, PG(비트 31) = 1
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, cr0
	or eax, 0xE0000000	;NW, CD, PG를 모두 1로 설정
	xor eax, 0x60000000	;NW = 0, CD = 0, PG = 1
	mov cr0, eax		;값 저장

	jmp 0x08:0x200000	;CS 세그먼트 셀렉터에 IA-32e모드용 코드 세그먼트 디스크립터 할당.
						;0x200000 주소로 이동

	;여기는 실행되지 않음
	jmp $
