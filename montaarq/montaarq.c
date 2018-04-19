#include <stdio.h>
#include <stdlib.h>

int main( int argc, char *argv[]) {
  int x=0;

  FILE *arqsaida;

  arqsaida = fopen("./arquivoemail.txt","w+");
    if (arqsaida!=NULL) {
    for(x=0;x<=500000;x++) {
      fprintf(arqsaida,"emailmask%d@delphixmasking.com\n",x);
    }
  } 

  fclose(arqsaida);

  return(0);
}

