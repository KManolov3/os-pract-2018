#include <unistd.h>
#include <stdlib.h>
#include <err.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>

int getNumberOfTokens(char* string, int delimeter){
	int pos = 0, numTokens=0, afterDelim = 1;
	while(string[pos]!='\0'){
		if(string[pos]!=delimeter && afterDelim == 1){
			numTokens++;
			afterDelim = 0;
		} else if(string[pos] == delimeter)
			afterDelim = 1;
		pos++;
	}

	return numTokens;
}

void executeCommand(char* command){
	fprintf(stderr, "Executing command %s with ppid %d and pid %d\n", command, getppid(), getpid());
	int numberOfArgs = getNumberOfTokens(command, ' ');

	char** args = malloc(sizeof(char*) * numberOfArgs);
	char* arg = strtok(command, " ");
	int argNum = 0;
	do{
		args[argNum] = arg;
		argNum++;
	}while( (arg = strtok(NULL," ")) != NULL);

	int procId = fork();
	if(procId == -1)
		err(8, "Error while forking");
	if(procId == 0){
		execvp(args[0], args);
		err(7, "Error while execing");
	}
	wait(NULL);
	free(args);
	exit(0);
}

char* findReducedSequence(char* sequence){
	int pipePos = 0;
	while(sequence[pipePos] != '|'){
		if(sequence[pipePos] == '\0')
			return (char*) NULL;
		pipePos++;
	}

	return sequence + pipePos + 1;
}

void executeSequence(char* sequence){
	char* reducedSequence = findReducedSequence(sequence);
	char* command = strtok(sequence, "|");
	if(reducedSequence != NULL){
		int pipeFD[2];
		if(pipe(pipeFD) == -1)
			err(6, "Error while piping");
		int procId = fork();
		if(procId == -1)
			err(5, "Error while forking");
		if(procId == 0){
			dup2(pipeFD[0], 0);
			close(pipeFD[1]);
			executeSequence(reducedSequence);
		}
		dup2(pipeFD[1], 1);
		close(pipeFD[0]);
	}
	executeCommand(command);

	exit(0);
}

void executeLine(char* line){
	char *sequence = NULL;
	sequence = strtok(line, ";");
	do{
		int procId = fork();
		if(procId == -1)
			err(4, "Error while forking");
		if(procId == 0)
			executeSequence(sequence);
		wait(NULL);
	} while( (sequence = strtok(NULL, ";")) != NULL);
	
	free(line);

	exit(0);
}

char* readLine(){
	char c;
	int lineLength=0;
	while(read(0,&c,1)>0 && c!='\n'){
		lineLength++;
	}
	lseek(0, -(lineLength+1), SEEK_CUR);
	char* line = malloc(lineLength+1);
	if(read(0, line, lineLength) != lineLength)
		errx(2, "Error while reading line");
	line[lineLength] = '\0';

	read(0, &c, 1); //Adjusting for the newline that follows; If it's EOF, that is fine as well
	
	return line;
}

int main(int argc, char* argv[]){
	if(argc != 2)
		errx(1, "Invalid function usage");

	int maxParallelOps = atoi(argv[1]), curParallelOps = 0;
	char* line;
	while(strlen(line = readLine()) > 0){
		if(curParallelOps == maxParallelOps){
			wait(NULL);
			fprintf(stderr, "line finished, executing next one\n");
		} else
			curParallelOps++;

		int procId = fork();
		if(procId == -1)
			err(3, "Error while forking");
		if(procId == 0)
			executeLine(line);

	}

	while(curParallelOps > 0){
		wait(NULL);
		curParallelOps--;
		fprintf(stderr,"line finished cleaning\n");
	}
	
	exit(0);
}
