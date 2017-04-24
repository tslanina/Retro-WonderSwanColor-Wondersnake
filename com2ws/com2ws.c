#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#define ROMSIZE 512*1024 //minimal ROM size for wondermagic device is 4 mbit

int main(int argc, char* argv[]) {

    unsigned char *buffer;
    FILE *file;
    int size;
    int i, checksum;

    printf("com2ws 1.0a (c) tomasz@slanina.pl\n");
    if(argc<3){
        printf(" usage: com2ws.exe file.com file.ws\n");
        return -1;
    }

    buffer =  malloc(ROMSIZE);
	memset(buffer,0,ROMSIZE);
	
    file=fopen(argv[1],"rb");
    if(file) {
        fseek(file,0,SEEK_END);
    	size=ftell(file);
    	fseek(file,0,SEEK_SET);
    	fread(&buffer[0x100], 1, size, file);
    	fclose(file);

        for(checksum=i=0; i<ROMSIZE-2; checksum+=buffer[i], ++i);
        
        checksum&= 0xffff;
        buffer[ROMSIZE-1]=checksum>>8;
        buffer[ROMSIZE-2]=checksum&0xff; //checksum
        buffer[ROMSIZE-4]=4; //horizontal
        buffer[ROMSIZE-6]=1; //rom size
        buffer[ROMSIZE-16]=0xea;//jump to start of code 
        buffer[ROMSIZE-15]=0x00; 
        buffer[ROMSIZE-14]=0x01; 
        buffer[ROMSIZE-12]=0x80; 
        buffer[ROMSIZE-9]=0x1; //wonderswan color flag
        
        file=fopen(argv[argc-1],"wb");
        if(file){
            fwrite(buffer, 1, ROMSIZE, file);
            fclose(file);
        }
    }
    free(buffer);
    return 0;
}

