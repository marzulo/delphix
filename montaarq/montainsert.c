#include <stdio.h>
#include <stdlib.h>

int main( int argc, char *argv[]) {
  int x=0;

  FILE *arqsaida;

  arqsaida = fopen("./arquivoinsert.txt","w+");
    if (arqsaida!=NULL) {
    for(x=0;x<=500000;x++) {
      fprintf(arqsaida,"insert into delphixdb.employees values (%d,'NOME%d','SOBRENOME%d','TESTMASK','CITY%d',987%08d);\n",x,x,x,x/2,x);
    }
  } 

  fclose(arqsaida);

  return(0);
}

