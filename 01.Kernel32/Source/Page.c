#include "Page.h"

//IA-32e모드 커널 위한 페이지 테이블 생성

void kInitializePageTables(void)
{
	PML4ENTRY* pstPML4Entry;
	PDPTENTRY* pstPDPTEntry;
	PDENTRY* pstPDEntry;
	DWORD dwMappingAddress;
	int i;

	//PML4테이블 생성. 4KB
	///첫 번째 엔트리 외 나머지 모두 0으로 초기화
	pstPML4Entry = (PML4ENTRY*)0x100000;

	//PML4 테이블 첫번째 엔트리, 가리키는 디렉터리 포인터 테이블 주소: 0x101000  플래그: 해당 엔트리 유효 + 읽기쓰기 가능
	kSetPageEntryData(&(pstPML4Entry[0]), 0x00, 0x101000, PAGE_FLAGS_DEFAULT, 0);
	for (i = 1; i < PAGE_MAXENTRYCOUNT; i++)
	{
		kSetPageEntryData(&(pstPML4Entry[i]), 0, 0, 0, 0);
	}

	//페이지 디렉터리 포인터 테이블 생성. 4KB
	//하나의 PDPT로 512GB까지 매핑 가능.
	//64개의 엔트리를 생성해서 64GB까지 매핑함
	pstPDPTEntry = (PDPTENTRY*)0x101000;
	for (i = 0; i < 64; i++)
	{
		//각각의 페이지 디렉터리 포인터 엔트리, 가리키는 디렉터리 테이블 주소: 0x102000 + i * 테이블 크기  플래그: 해당 엔트리 유효 + 읽기쓰기 가능
		kSetPageEntryData(&(pstPDPTEntry[i]), 0, 0x102000 + (i * PAGE_TABLESIZE), PAGE_FLAGS_DEFAULT, 0);
	}

	for (i = 64; i < PAGE_MAXENTRYCOUNT; i++)
	{
		//나머지 페이지 디렉터리는 안쓰므로 비활성화.
		kSetPageEntryData(&(pstPDPTEntry[i]), 0, 0, 0, 0);
	}

	//페이지 디렉터리 테이블 생성. 256KB
	//하나의 페이지 디렉터리당 1GB 매핑 가능
	//64개의 페이지 디렉터리를 생성하여 총 64GB까지 지원
	pstPDEntry = (PDENTRY*)0x102000;
	dwMappingAddress = 0;
	for (i = 0; i < PAGE_MAXENTRYCOUNT * 64; i++)
	{
		//각각의 페이지 디렉터리 엔트리, 가리키는 페이지 상위 32bit 주소 계산.   플래그: 해당 엔트리 유효 + 읽기쓰기 가능 + PS 플래그 1=페이지 크기 2MB 
		kSetPageEntryData(&(pstPDEntry[i]), (i * (PAGE_DEFAULTSIZE >> 20)) >> 12, dwMappingAddress, PAGE_FLAGS_DEFAULT | PAGE_FLAGS_PS, 0);
		dwMappingAddress += PAGE_DEFAULTSIZE;
	}
}
//페이지 엔트리에 기준 주소와 속성 플래그를 설정
void kSetPageEntryData(PTENTRY* pstEntry, DWORD dwUpperBaseAddress, DWORD dwLowerBaseAddress, DWORD dwLowerFlags, DWORD dwUpperFlags)
{
	pstEntry -> dwAttributeAndLowerBaseAddress = dwLowerBaseAddress | dwLowerFlags;
	pstEntry->dwUpperBaseAddressAndEXB = (dwUpperBaseAddress & 0xFF) | dwUpperFlags;
}
