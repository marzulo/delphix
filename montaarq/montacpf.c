#include <stdio.h>
#include <stdlib.h>

int main( int argc, char *argv[]) {
  int x=0;

  FILE *arqsaida;

  arqsaida = fopen("./arquivocpf.txt","w+");
    if (arqsaida!=NULL) {
    for(x=0;x<=1000000;x++) {
      fprintf(arqsaida,"987%08d\n",x);
    }
  } 

  fclose(arqsaida);

  return(0);
}

