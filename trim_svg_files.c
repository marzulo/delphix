/* The intention of this code is trim a SVG file to reduce the file size
   by eliminating all decimal values for each line starting with "<path d="
   or "<path id="
   
   Compile with gcc -g trim_svg_file.c and call ./a.out <filename.svg>
   The program will create a file called <filename.svg>_out

   Thing to do:
   1 - Implement control of decimal exclusion only inside of " ";
   2 - Ignore lines that do not start with "<path d="
   3 - Receive output file name as parameter
   4 - LOG LEVEL (0 DEBUG - 1 WARNING - 2 ERROR)
*/

#include <stdio.h>
#include <string.h>

int debug (char *logmessage, int errorlevel) {
	if (errorlevel == 0) fprintf(stdout,"[DEBUG] %s\n", logmessage);
	if (errorlevel == 1) fprintf(stdout,"[WARNING] %s\n", logmessage);
	if (errorlevel == 2) fprintf(stdout,"[ERROR] %s\n", logmessage);
	if (errorlevel>2 || errorlevel<0) {
		fprintf(stdout,"%s\n",logmessage);
		return(1);
	}
	return(0);
}

int main(int argc, char *argv[]) {

  FILE *fin,*fou;
  int lines, cont, sizet, copia, contout, contaspa, copialinha, linhagrande;
  char string[15000], filename[250], fileout[255], stringout[15000], logmessage[2000];
  char chr;

  memset(string, '\0', 15000);
  memset(stringout, '\0', 15000);
  memset(filename, '\0', 250);
  memset(fileout, '\0', 255);
  memset(logmessage, '\0', 2000);

  strcpy(filename, argv[1]);
  cont=strlen(filename);
  memcpy(fileout,filename,cont);
  strcat(fileout,"_out");

  sprintf(logmessage,"%s - %s\n",filename, fileout);
  debug(logmessage,0);
  
  fin = fopen(filename, "r");
  fou = fopen(fileout, "w+");
  if (fin == NULL || fou == NULL) {
	  debug("ERROR OPENING FUCKING FILES",2);
	  return(1);
  }
	  
  lines=linhagrande=copialinha=0;
  fseek(fin, 0, SEEK_SET);
  fseek(fou, 0, SEEK_END);
  
  while( fgets (string, 15000, fin)!=NULL ) {
	  lines++;
	  sizet=strlen(string);
	  
	  memset(logmessage, '\0', 2000);
	  sprintf(logmessage,"Line %d:%c -- %s\n",lines,string[sizet-1],string);
      debug(logmessage,0);
	  
	  cont = memcmp(string, "<path d=", 8);
	  contout = memcmp(string, "<path id=", 9);
	  
	  memset(logmessage, '\0', 2000);
	  sprintf(logmessage,"String compare: %d:%d\n",cont,contout);
      debug(logmessage,0);
	  
	  if (cont==0) copialinha=1;
	  if (contout==0) copialinha=2;

	  // We need to control if the fgets read the entire line
	  if(string[sizet-1]!='\n' && copialinha>0) linhagrande=1;	
	  
	  if(copialinha>0 || linhagrande==1) {
	      /* aqui vai o loop para tirar os pontos */
		  if(linhagrande==1 && string[sizet-1]=='\n') linhagrande=0;
	      copia=1;
	      contout=0;
		  contaspa=0;
          for(cont=0;cont<sizet;cont++) {
		      chr=string[cont];
		      if(chr=='.') copia=0;
	          if(chr!='0' && chr!='1' && chr!='2' && chr!='3' && chr!='4' && chr!='5' && chr!='6' && chr!='7' && chr!='8' && chr!='9' && copia==0 && chr!='.') copia=1;
		      if(chr=='"') contaspa++;
			  if(contaspa>=4 && copialinha==2) copia=1;
			  if(contaspa>=2 && copialinha==1) copia=1;
			  if(copia==1) {
		    	  stringout[contout]=chr;
		    	  stringout[contout+1]='\0';
		    	  contout++;
		      }			 
	      }
		  copialinha=0;
	  } else {
		  memcpy(stringout, string, sizet+1);
	  }
	  fprintf(fou,"%s",stringout);
	  memset(string, '\0', 15000);
	  memset(stringout, '\0', 15000);
   }
   fclose(fin);
   fflush(fou);
   fclose(fou);
   
  return(0);
}
