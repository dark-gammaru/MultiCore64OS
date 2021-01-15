#include "Types.h"

void kPrintString(int iX, int iY, const char* pcString);
BOOL kInitializeKernel64Area(void);
//Main
void Main(void)
{
	//DWORD i;

	kPrintString(0, 3, "C Language Kernel Started.");

	//IA-32e모드의 커널영역 초기화
	kInitializeKernel64Area();
	kPrintString(0,4,"IA-32e Kernel Area Initialization Complete.");
	while(1);
}

//문자 출력 함수
void kPrintString(int iX, int iY, const char* pcString)
{
	CHARACTER* pstScreen = (CHARACTER*)0xB8000;
	int i;

	pstScreen += (iY*80) + iX;

	for(i = 0; pcString[i] != 0; i++)
		pstScreen[i].bCharactor = pcString[i];
}

//IA-32e모드용 커널영역 0으로 초기화
BOOL kInitializeKernel64Area(void)
{
	DWORD* pdwCurrentAddress;

	//초기화 시작할 주소 설정
	pdwCurrentAddress = (DWORD*) 0x100000;

	//마지막 주소까지 루프 돌면서 4바이트씩 0으로 채움.
	while((DWORD)pdwCurrentAddress < 0x600000)
	{
		*pdwCurrentAddress = 0x00;

		//0으로 저장 후 다시 읽었을 때 0이 나오지 않으면 해당 주소를
		//사용하는데 문제가 생긴것이므로 중단하고 종료.
		if(*pdwCurrentAddress != 0)
		{
			return FALSE;
		}

		//다음 주소로 이동. 4바이트+
		pdwCurrentAddress++;
	}
	return TRUE;
}
