#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <err.h>
#include <string.h>
#define LONGEST_WORD_IN_ENGLISH_DICTIONARY 45

int main(int argc, char* argv[]){
	
	if(argc!=3)
		errx(1, "Incorrect usage");
	
	int fd;
	if((fd = open(argv[1], O_RDONLY)) == -1 )
		errx(2, "%s", argv[1]);

	
	char c, chunk[1024], wordRead[LONGEST_WORD_IN_ENGLISH_DICTIONARY + 1];
	char* targetWord = argv[2];
	int left = 0;
	int right = lseek(fd, -1, SEEK_END);

	while(right >= left){
		lseek(fd, (left + right) / 2, SEEK_SET);
		while(read(fd, &c, 1) > 0 && c!='\0'){	// Go to start of word
			lseek(fd, -2, SEEK_CUR);
		}	
		
		int bytesRead = read(fd, wordRead, LONGEST_WORD_IN_ENGLISH_DICTIONARY + 1);
		int i=0;
		while(wordRead[i] != '\n'){ 
			i++;
		}
		wordRead[i] = '\0';
		lseek(fd, - (bytesRead - 1 - i), SEEK_CUR); // Return to start of description, factor in the newline

		if(strcmp(wordRead, targetWord) < 0){
			left = (left + right) / 2 + 1;
		} else if(strcmp(wordRead, targetWord) > 0){
			right = (left + right) / 2 - 1; 
		} else {
			int term = 0;
			do{
				int bytesRead,i;
				if( (bytesRead = read(fd, chunk, sizeof(chunk))) < sizeof(chunk)){ // Check if EOF
					i = bytesRead;
					term = 1;
				}
				
				for(i=0; i<bytesRead; i++){
					if(chunk[i] == '\0'){
						term = 1;
						break;
					}
				}

				if(write(1, chunk, i) != i)
					errx(3, "Error while writing");
			
			} while(!term);
			break;
		}
	}

	if(right < left){
		char text[100] = "Word was not found in dictionary\n";
		write(1, text, strlen(text));
	}
	
	close(fd);
	exit(0);
}
