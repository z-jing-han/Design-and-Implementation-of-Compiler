%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
unsigned charCount = 1, lineCount = 1;
%}
space [ \t]
eol [\r]?\n
operator \+[\+]?|\-[\-]?|\*|\/|[<>=][=]?
reserved_word boolean|char|class|else|final|float|for|if|int|main|new|print|return|static|void|while
symbol [,;()\[\]{}]
int [0-9]+
id [\$_A-Za-z]+[\$_A-Za-z0-9]*
string \"([^\r\n\\\"]|([\\][\\\"bfnrt0]))*\"
comment (\/\/[^\n\r]*)|(\/\*([^*]|\*+[^*\/])*\*+\/)

%%
{space} {
	printf("%s",yytext);
	charCount++;
}
{eol} {
	if(*(yytext+2) == 0)
		printf("\n");
	else
		printf("\nline %2d:", ++lineCount);
	charCount = 1;
}
{operator} {
	printf(" %s", yytext);
	charCount += yyleng;
	if(strcmp(yytext, "++") == 0)
		return ADDONE;
	if(strcmp(yytext, "--") == 0)
		return SUBONE;
	if(strcmp(yytext, "+") == 0)
		return ADD;
	if(strcmp(yytext, "-") == 0)
		return SUB;
	if(strcmp(yytext, "*") == 0)
		return MUL;
	if(strcmp(yytext, "/") == 0)
		return DIV;
	if(strcmp(yytext, ">") == 0)
		return BT;
	if(strcmp(yytext, "<") == 0)
		return LT;
	if(strcmp(yytext, "=") == 0)
		return ASSIGN;
	if(strcmp(yytext, ">=") == 0)
		return BEQ;
	if(strcmp(yytext, "<=") == 0)
		return LEQ;
	if(strcmp(yytext, "==") == 0)
		return EQ;
}
{reserved_word} {
	printf(" %s", yytext);
	charCount += yyleng;
	
	if(strcmp(yytext, "boolean") == 0)
		return BOOLEAN;
	if(strcmp(yytext, "char") == 0)
		return CHAR;
	if(strcmp(yytext, "class") == 0)
		return CLASS;
	if(strcmp(yytext, "else") == 0)
		return ELSE;
	if(strcmp(yytext, "final") == 0)
		return FINAL;
	if(strcmp(yytext, "float") == 0)
		return FLOAT;
	if(strcmp(yytext, "for") == 0)
		return FOR;
	if(strcmp(yytext, "if") == 0)
		return IF;
	if(strcmp(yytext, "int") == 0)
		return INT;
	if(strcmp(yytext, "main") == 0)
		return MAIN;
	if(strcmp(yytext, "new") == 0)
		return NEW;
	if(strcmp(yytext, "print") == 0)
		return PRINT;
	if(strcmp(yytext, "return") == 0)
		return RETURN;
	if(strcmp(yytext, "static") == 0)
		return STATIC;
	if(strcmp(yytext, "void") == 0)
		return VOID;
	if(strcmp(yytext, "while") == 0)
		return WHILE;
}
{symbol} {
	printf(" %s", yytext);
	charCount += yyleng;
	if(strcmp(yytext, ",") == 0)
		return COMMA;
	if(strcmp(yytext, ";") == 0)
		return SEMI;
	if(strcmp(yytext, "(") == 0)
		return LP;
	if(strcmp(yytext, ")") == 0)
		return RP;
	if(strcmp(yytext, "[") == 0)
		return LB;
	if(strcmp(yytext, "]") == 0)
		return RB;
	if(strcmp(yytext, "{") == 0)
		return LC;
	if(strcmp(yytext, "}") == 0)
		return RC;
}
{int} {
	printf(" %s", yytext);
	charCount += yyleng;
	return NUM;
}
{id} {
	printf(" %s", yytext);
	charCount += yyleng;
	yylval.strval = strdup(yytext);
	return ID;
}
{string} {
	printf(" %s", yytext);
	charCount += yyleng;
	return STR;
}
{comment} {
	printf(" ");
	for(int i = 0; yytext[i]; i++){
		if(yytext[i] == '\n'){
			printf("\nline %2d:", ++lineCount);
			charCount = 1;
		}
		charCount++;
		if(yytext[i] != '\r' && yytext[i] != '\n')
			printf("%c", yytext[i]);
	}
}
. {
	printf(" %s (, in char: %d, which is an \"Undefined pattern\")", yytext, charCount);
	charCount += yyleng;
}
%%

