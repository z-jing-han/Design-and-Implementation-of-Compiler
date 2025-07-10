%define parse.error verbose
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#define SIZE 50
typedef enum Type TYPE;
enum Type{
	CLASSNAME = 0,
	FUNCTION = 1,
	VARIABLE = 2,
};

int yylex();
extern unsigned charCount, lineCount;

bool DeclareBefore = false;
int UndefineNum = 0, LastLayer[3] = {0}, TableLength[3] = {0}, ScopeRecord[3][SIZE] = {{0}, {0}, {0}}, DeclareBeforeNum = 0;
char ErrorIdentifier[SIZE][SIZE], SymbolTable[3][SIZE][SIZE];
bool VariableUsed[3][SIZE];

void yyerror(const char*);
bool IsDeclare(TYPE, char*);
bool Insert(TYPE, char*);
void PrintSymbolTable();
void ClassPostIdentify();
void checkDeclare(char*);
void printUndefineClass();
void useidentifier(TYPE, char*);
void ScopeStart();
void ScopeEnd();

%}
%union{
    char *strval;
}
%token AND OR ADDONE SUBONE ADD SUB MUL DIV BT LT ASSIGN BEQ LEQ EQ
%token BOOLEAN CHAR CLASS ELSE FINAL FLOAT FOR IF INT MAIN NEW PRINT RETURN STATIC VOID WHILE
%token COMMA SEMI LP RP LB RB LC RC
%token NUM STR
%token <strval> ID
%start classList
%%
/*Start: a Java program is bulit up by many classes, and it can be empty. Error Handle also*/
classList:/*empty*/
	| classList class
	| error
	;

/*Class grammar: class ID{classbody}*/
class: CLASS ID{ Insert(CLASSNAME, $2); } LC{ ScopeStart(); } classbodys RC{ ScopeEnd(); }
	;
classbodys:/*empty*/
	| classbodys classbody
	;
classbody: class
	| field
	| method
	;

/*static (const or final) int variableList; int [] ID = new int [3]; Point a = new Point();*/
field: STATIC type variableList SEMI
	| FINAL type variableList SEMI
	| type variableList SEMI
	| type LB RB ID ASSIGN NEW type LB NUM RB SEMI{ Insert(VARIABLE, $4); }
	| ID ID ASSIGN NEW ID LP RP SEMI{ if(IsDeclare(CLASSNAME, $1) && IsDeclare(CLASSNAME, $5)) Insert(CLASSNAME, $2); }
	;
type: INT | FLOAT | BOOLEAN | CHAR | VOID;

//ID or ID1, ID2
variableList: ID{ Insert(VARIABLE, $1); }
	| ID ASSIGN expr{ Insert(VARIABLE, $1); }
	| variableList COMMA ID{ Insert(VARIABLE, $3); }
	| variableList COMMA ID ASSIGN expr{ Insert(VARIABLE, $3); }
	;

/*public int FUNCNAME(argument) {...} void main() main()*/
method:type ID{ Insert(FUNCTION, $2); } LP arguments RP compound
	| VOID MAIN{ Insert(FUNCTION, "main"); } LP arguments RP compound
	| MAIN{ Insert(FUNCTION, "main"); } LP arguments RP compound
	;
	
/*int a, int b ... */
arguments: argument
	| arguments COMMA argument
	;
/*int a */
argument:/*empty*/
	| type ID{ DeclareBefore = 1; Insert(VARIABLE, $2); DeclareBeforeNum++; }
	;

/* { ... }*/
compound: LC{ ScopeStart(); } statements RC{ ScopeEnd(); }
	;

statements: /*empty*/
	| statements field
	| statements statement
	;
/* new scope, simple if-else, for, while, return*/
statement: compound | class | simple | ifelse | for | while| return;

/*simple: ID = expr; print(expr); expr;*/
simple: ID ASSIGN expr SEMI{ IsDeclare(VARIABLE, $1); }
	| PRINT LP expr RP SEMI
	| expr SEMI
	;

expr: term | expr ADD term | expr SUB term;
term: factor | term MUL factor | term DIV factor;

/*ID, ++ID, ID--, ID[expr]++, --ID[expr], ID[expr]*/
factor: ID{ useidentifier(CLASSNAME, $1);useidentifier(FUNCTION, $1);useidentifier(VARIABLE, $1); }
	| constexpr
	| preOp ID{ useidentifier(VARIABLE, $2); }
	| LP expr RP
	| ID postOp{ useidentifier(VARIABLE, $1); }
	| ID arrayIndex{ useidentifier(VARIABLE, $1); }
	| preOp ID arrayIndex{ useidentifier(VARIABLE, $2); }
	| ID arrayIndex postOp{ useidentifier(VARIABLE, $1); }
	| methodInvocation
	;
arrayIndex: LB expr RB;
preOp: ADDONE | SUBONE | ADD | SUB; 
postOp: ADDONE | SUBONE;
constexpr: NUM | ADD NUM | SUB NUM | STR;

/*method body*/
methodInvocation: ID LP exprs RP{ IsDeclare(FUNCTION, $1); }
	;
exprs:/*empty*/
	| expr
	| exprs COMMA expr
	;

//if-else
ifelse: IF LP boolexpr RP simple
	| IF LP boolexpr RP simple ELSE compound
	| IF LP boolexpr RP simple ELSE simple
	| IF LP boolexpr RP compound
	| IF LP boolexpr RP compound ELSE simple
	| IF LP boolexpr RP compound ELSE compound
	;
boolexpr: expr compare expr;
compare: EQ | LT | BT | LEQ | BEQ;

/*while(boolexpr)*/
while: WHILE LP boolexpr RP statement
	| error RC /*While Error Handle in test6.java*/
	;
/*for(init;boolexpr;update)statement*/
for:FOR LP forInit SEMI boolexpr SEMI forIndexUpdate RP statement
	;

/*i = 0, int i = 0, i[0] = 0 */
forInit: ID ASSIGN expr { IsDeclare(VARIABLE, $1); }
	| INT ID ASSIGN expr{ DeclareBefore = true; Insert(VARIABLE, $2); DeclareBeforeNum++; }
	| ID arrayIndex ASSIGN expr{ IsDeclare(VARIABLE, $1); }
	;

/*i++, i[0]++*/
forIndexUpdate: ID ADDONE{ IsDeclare(VARIABLE, $1); }
	| ID arrayIndex ADDONE{ IsDeclare(VARIABLE, $1); }
	;

/*return expr;*/
return: RETURN expr SEMI;

%%
int main() {
	printf("Line  1:");
    yyparse();
    printUndefineClass();
    return 0;
}

void yyerror(const char *str){
	fprintf(stderr, "*********Line %d: char %d has %s\n", lineCount, charCount, str+14);
}

bool IsDeclare(TYPE Type, char *s){
	for(int i = 0; i < TableLength[Type]; ++i)
		if(strcmp(SymbolTable[Type][i], s) == 0){
			VariableUsed[Type][i] = true;
			return true;
		}
	if(Type == CLASSNAME)
		strcpy(ErrorIdentifier[UndefineNum++], s);
	else
		fprintf(stderr, ">>>>>>>>> \"%s\" hasn't been declared yet.\n",s);
	return false;
}

bool Insert(TYPE Type, char *s){
	if(Type == VARIABLE && DeclareBefore){
		strcpy(SymbolTable[Type][TableLength[Type]], s);
		VariableUsed[Type][TableLength[Type]++] = false;
		return true;
	}
	for(int i = ScopeRecord[Type][LastLayer[Type]-1]; i < TableLength[Type]; ++i)
		if(strcmp(SymbolTable[Type][i], s) == 0){
			fprintf(stderr, ">>>>>>>>> \"%s\" is a duplicate identifier.\n",s);
			return false;
		}
	strcpy(SymbolTable[Type][TableLength[Type]], s);
	VariableUsed[Type][TableLength[Type]++] = strcmp(s, "main") == 0;
	if(Type == CLASSNAME)
		checkDeclare(s);
	return true;
}

void useidentifier(TYPE Type, char *s){
	for(int i = ScopeRecord[Type][LastLayer[Type]-1]; i < TableLength[Type]; ++i)
		if(strcmp(SymbolTable[Type][i], s) == 0)
			VariableUsed[Type][i] = true;
}

void checkDeclare(char *s){
	for(int i = 0; i < UndefineNum; ++i)
		if(strcmp(ErrorIdentifier[i], s) == 0)
			strcpy(ErrorIdentifier[i], "");
}

void ScopeStart(){
	for(int t = 0; t < 3; ++t)
		ScopeRecord[t][LastLayer[t]++ - (t == VARIABLE ? DeclareBeforeNum:0)] = TableLength[t];
}

void ScopeEnd(){
	for(int t = 0; t < 2; ++t)
		for(int i = ScopeRecord[t][LastLayer[t]-1]; i < TableLength[t]; ++i)
			if(!VariableUsed[t][i])
				fprintf(stderr, "========= \"%s\" is a unused identifier.\n",SymbolTable[t][i]);
			else
				VariableUsed[t][i] = false;
	for(int t = 0; t < 3; ++t)
		TableLength[t] = ScopeRecord[t][--LastLayer[t]];
}

void printUndefineClass(){
	for(int i = 0; i < UndefineNum; ++i)
		if(strcmp(ErrorIdentifier[i], "") != 0)
			fprintf(stderr, ">>>>>>>>> \"%s\" hasn't been declared yet.\n",ErrorIdentifier[i]);
}
