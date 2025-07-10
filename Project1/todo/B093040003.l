%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

unsigned charCount = 1, idCount = 0, lineCount = 1;
char **symbolTable;
int tableLen = 0;
bool preIsOperand, multiplecommentflag;

void endmultiplecomment();
void create();
int lookup(char* s);
int insert(char* s);
void dump();
void release();
%}
space [ \t]
eol \r\n|\n
operator ~|&&|\|\||\+\+|\-\-|([\+\-\*\/%\^\|\&<>=!]|[>]?>>|<<)[=]?
reserved_word abstract|assert|boolean|break|byte|case|char|catch|class|const|continue|default|do|double|else|enum|extends|exxports|false|final|finally|float|for|if|implements|int|import|instanceof|interface|long|module|main|native|new|null|print|println|package|private|protected|public|requires|return|short|static|strictfp|string|String|super|switch|synchronized|this|true|try|throw|throws|transient|volatile|var|void|volatile|while
symbol [,:;()\[\]{}]
int (([\+\-][ ]*)?0[xX])[0-9A-Fa-f]+|([\+\-][ ]*)?[0-9]+
float ([\+\-][ ]*)?([0-9]+[\.][0-9]*|[0-9]*[\.][0-9]+|[0-9]+)([Ee][\+\-]?[0-9]+)?[Ff]?
errorid [#^0-9]+[\$_A-Za-z]+
id [\$_A-Za-z]+[\$_A-Za-z0-9]*
string \"([^\r\n\\\"]|([\\][\\\"bfnrt0]))*\"
errorstring (\"([^\r\n\"]*)|(\"([\\][\\A-Za-z]))*\")
char \'([^\n\\\']|([\\][\\\'bfnrt0]))\'
errorchar \'([^\n]|([\\][\\\'a-z]))*\'
singlecomment \/\/[^\r\n]*
multiplecommentstart \/\*
multiplecommentend \*\/
%%
{space} {
	if(!multiplecommentflag){
		charCount++;
	}
}
{eol}   {
	if(!multiplecommentflag){
		lineCount++;
		charCount = 1;
		preIsOperand = false;
	}
}
{operator} {
	if(!multiplecommentflag){
		preIsOperand = false;
		printf("Line: %d, 1st char: %d, \"%s\" is a \"Operator\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
}
{reserved_word} {
	if(!multiplecommentflag){
		preIsOperand = false;
		printf("Line: %d, 1st char: %d, \"%s\" is a \"Reserved word\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
}
{symbol} {
	if(!multiplecommentflag){
		if(yytext[0] != ')')
			preIsOperand = false;
		printf("Line: %d, 1st char: %d, \"%s\" is a \"Symbol\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
}
{int} {
	if(!multiplecommentflag){
		int numberSpace = 0;
		if(preIsOperand && (yytext[0] == '+' || yytext[0] == '-')){
			printf("Line: %d, 1st char: %d, \"%c\" is an \"Operator\".\n", lineCount, charCount, yytext[0]);
			for(; yytext[numberSpace+1] == ' '; ++numberSpace);
			++numberSpace;
		}
		printf("Line: %d, 1st char: %d, \"%s\" is an \"Interger Constant\".\n", lineCount, charCount+numberSpace, yytext+numberSpace);
		charCount += yyleng;
		preIsOperand = true;
	}
}
{float} {
	if(!multiplecommentflag){
		int numberSpace = 0;
		if(preIsOperand && (yytext[0] == '+' || yytext[0] == '-')){
			printf("Line: %d, 1st char: %d, \"%c\" is an \"Operator\".\n", lineCount, charCount, yytext[0]);
			for(; yytext[numberSpace+1] == ' '; ++numberSpace);
			++numberSpace;
		}
		printf("Line: %d, 1st char: %d, \"%s\" is a \"Float Constant\".\n", lineCount, charCount+numberSpace, yytext+numberSpace);
		charCount += yyleng;
		preIsOperand = true;
	}
}
{id} {
	if(!multiplecommentflag){
		preIsOperand = true;
		printf("Line: %d, 1st char: %d, \"%s\" is an \"Identifier\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
		insert(yytext);
	}
}
{errorid} {
	if(!multiplecommentflag){
		printf("Line: %d, 1st char: %d, \"%s\" is an \"Invaild Identifier\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
}
{string} {
	if(!multiplecommentflag){
		preIsOperand = true;
		printf("Line: %d, 1st char: %d, %s is a \"String\".\n", lineCount, charCount+1, yytext);
		charCount += yyleng;
	}
}
{errorstring} {
	if(!multiplecommentflag){
		printf("Line: %d, 1st char: %d, %s is an \"Invaild String\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
}
{char} {
	if(!multiplecommentflag){
		preIsOperand = true;
		printf("Line: %d, 1st char: %d, %s is a \"Character\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
}
{errorchar} {
	if(!multiplecommentflag){
		printf("Line: %d, 1st char: %d, %s is an \"Invaild Character\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}	
}
{singlecomment} {
	if(!multiplecommentflag){
		printf("Line: %d, 1st char: %d, %s is a \"Single line Comment\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
	
	for(char* ptr = yytext; ptr < yytext + yyleng; ++ptr){
		if(*(ptr) == '*' && *(ptr+1) == '/'){
			multiplecommentflag = false;
			break;
		}
	}
}
{multiplecommentstart} {
	if(!multiplecommentflag){
		multiplecommentflag = true;
		printf("Line: %d, 1st char: %d,\n", lineCount, charCount);
		while(!(*(yytext) == '*' && *(yytext+1) == '/')){
			if(*(yytext) != '\r' && *(yytext) != '\0')
				printf("%c", *(yytext));
			yytext++;
			charCount++;
			if((*yytext) == '\n'){
				lineCount++;
				charCount = 1;
			}
		}
		printf("%c%c\n", *(yytext), *(yytext+1));
		printf("is a \"multiple line Comment\".\n");
	}
}
{multiplecommentend} {
	multiplecommentflag = false;
}
. {
	if(!multiplecommentflag){
		printf("%d\n", yytext[0]);
		printf("Line: %d, 1st char: %d, \"%s\" is an \"Invaild token\".\n", lineCount, charCount, yytext);
		charCount += yyleng;
	}
}
%%
int main() {
	create();
	yylex();
	dump();
	release();
	return 0;
}
 
void create() {
	symbolTable = NULL;
	multiplecommentflag = false;
}

int lookup(char* s){
	for(int i = 0; i < tableLen; ++i)
		if(strcmp(*(symbolTable+i), s) == 0)
			return i;
	return -1;
}

int insert(char* s){
	int index = lookup(s);
	if(index != -1)
		return index;
	symbolTable = (char**)realloc(symbolTable, sizeof(char*) * (tableLen + 1));
	symbolTable[tableLen] = (char*)malloc(sizeof(char) * strlen(s));
	strcpy(symbolTable[tableLen], s);
	return tableLen++;
}

void dump(){
	printf("The symbol table contains:%s\n", (tableLen == 0 ? " zero item":""));
	for(int i = 0; i < tableLen; ++i)
		printf("%s\n", *(symbolTable+i));
}

void release(){
	for(int i = 0; i < tableLen; ++i)
		free(*(symbolTable+i));
	free(symbolTable);
}
