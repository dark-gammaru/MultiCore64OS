#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#define BYTESOFSECTOR  512

#ifndef O_BINARY
#define O_BINARY 0x00
#endif

// 함수 선언
int AdjustInSectorSize(int iFd, int iSourceSize);
void WriteKernelInformation(int iTargetFd, int iKernelSectorCount);
int CopyFile(int iSourceFd, int iTargetFd);

int main(int argc, char* argv[])
{
    int iSourceFd;
    int iTargetFd;
    int iBootLoaderSize;
    int iKernel32SectorCount;
    int iSourceSize;
    
    //커멘드 라인 옵션 검사
    if(argc < 3)
    {
        fprintf(stderr, "[ERROR] ImageMaker BootLoader.bin Kernel32.bin\n");
        exit(-1);
    }
    
    //Disk.img 파일 생성
    if((iTargetFd = open("Disk.img", O_RDWR | O_CREAT | O_TRUNC |
        O_BINARY, S_IREAD | S_IWRITE)) == -1)
        {
            fprintf(stderr, "[ERROR] Disk.img open fail.\n");
            exit(-1);
        }
        
    /**********************************************************
    * 부트로더 파일 열어서 모든 내용 디스크 이미지 파일로 복사
    **********************************************************/
    printf("[INFO] Copy bootLoader To Image File\n");
    if((iSourceFd = open(argv[1], O_RDONLY | O_BINARY)) == -1)
    {
        fprintf(stderr,"[ERROR] %s open fail\n",argv[1]);
        exit(-1);
    }
    
    iSourceSize = CopyFile(iSourceFd, iTargetFd);
    close(iSourceFd);
    
    //파일 크기를 섹터 크기인 512바이트로 맞추기 위해 나머지 부분을 0x00으로 채움
    iBootLoaderSize = AdjustInSectorSize(iTargetFd, iSourceSize);
    printf("[INFO] %s size = [%d] and sector count = [%d]\n",argv[1],iSourceSize,iBootLoaderSize);
    
    /**********************************************************
    * 32비트 커널 파일을 열어서 모든 내용을 디스크 이미지 파일로 복사
    **********************************************************/
    printf("[INFO] Copy Protected Mode Kernel To Image File\n");
    
    if((iSourceFd = open(argv[2], O_RDONLY | O_BINARY)) == -1)
    {
        fprintf(stderr,"[ERROR] %s open fail\n",argv[2]);
        exit(-1);
    }
    iSourceSize = CopyFile(iSourceFd, iTargetFd);
    close(iSourceFd);
    
    //파일 크기를 섹터 크기인 512바이트로 맞추기 위해 나머지 부분을 0x00으로 채움
    iKernel32SectorCount = AdjustInSectorSize(iTargetFd, iSourceSize);
    printf("[INFO] %s size = [%d] and sector count = [%d]\n",argv[1],iSourceSize,iKernel32SectorCount);
    
    /**********************************************************
    * 디스크 이미지에 커널 정보를 갱신
    **********************************************************/
    printf("[INFO] Start TO Write Kernel Information\n");
    //부트섹터의 5번째 바이트부터 커널 정보 추가
    WriteKernelInformation(iTargetFd,iKernel32SectorCount);
    printf("[INFO] Image File Create Complete\n");
    
    close(iTargetFd);
    return 0;
}

//현재 위치부터 512바이트 배수 위치까지 맞추어 0x00으로 채움
int AdjustInSectorSize(int iFd, int iSourceSize)
{
    int i;
    int iAdjustSizeToSector;
    char cCh;
    int iSectorCount;
    
    iAdjustSizeToSector = iSourceSize % BYTESOFSECTOR;
    cCh = 0x00;
    
    if(iAdjustSizeToSector != 0)
    {
        iAdjustSizeToSector = 512 - iAdjustSizeToSector;
        printf("[INFO] File Size [%lu] And Fill [%u] Byte\n",iSourceSize, iAdjustSizeToSector);
        
        for(i = 0; i < iAdjustSizeToSector; i++)
        {
            write(iFd,&cCh, 1);
        }
            
    }
    
    else 
    {
        printf("[INFO] File Size Is Aligned 512 Byte\n");
    }
    
    //섹터 수 되돌려줌
    iSectorCount = (iSourceSize + iAdjustSizeToSector) / BYTESOFSECTOR;
    return iSectorCount;
}

//부트로더에 커널에 대한 정보 삽입
void WriteKernelInformation(int iTargetFd, int iKernelSectorCount)
{
    unsigned short usData;
    long lPosition;
    
    //파일 시작에서 5바이트 떨어진 위치가 커널 총 섹터 수 정보 나타내는 곳.
    lPosition = lseek(iTargetFd,(off_t)5, SEEK_SET);
    if(lPosition == -1)
    {
        fprintf(stderr,"lseek fail. Return value = %ld, errno = %d, %d\n",
            lPosition, errno, SEEK_SET);
        exit(-1);
    }
    
    usData = (unsigned short) iKernelSectorCount;
    write(iTargetFd,&usData,2);
    
    printf("[INFO] Total Sector Count Except BootLoader [%d]\n", iKernelSectorCount);
}

//소스 파일(SourceFd)의 내용을 목표 파일(TargetFd)에 복사하고 그 크기를 리턴
int CopyFile(int iSourceFd, int iTargetFd)
{
    int iSourceFileSize;
    int iRead;
    int iWrite;
    char vcBuffer[BYTESOFSECTOR];
    
    iSourceFileSize = 0;
    while(1)
    {
        iRead = read(iSourceFd, vcBuffer, sizeof(vcBuffer));
        iWrite = write(iTargetFd, vcBuffer, iRead);
        
        if(iRead != iWrite)
        {
            fprintf(stderr,"[ERROR] iRead != iWrite.\n");
            exit(-1);
        }
        iSourceFileSize += iRead;
        if(iRead != sizeof(vcBuffer))
        {
            break;
        }
    }
    return iSourceFileSize;
}

