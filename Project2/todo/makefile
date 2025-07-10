all:	clean y.tab.c lex.yy.c
	gcc lex.yy.c y.tab.c -lfl -o calc

y.tab.c:
	bison -y -Wcounterexamples -d B093040003.y

lex.yy.c:
	flex B093040003.l

clean:
	rm -f calc lex.yy.c y.tab.c y.tab.h 
