all: tw_lex

tw_lex: tw_lex.tab.c lex.yy.c tw_lex.tab.h
	gcc -o tw_lex tw_lex.tab.c lex.yy.c

tw_lex.tab.c tw_lex.tab.h: tw_lex.y
	bison -d tw_lex.y

lex.yy.c: tw_lex.l tw_lex.tab.h
	flex tw_lex.l
	
clean:
	rm tw_lex.tab.c lex.yy.c tw_lex.tab.h

exe: tw_lex.tab.c lex.yy.c tw_lex.tab.h
	i686-w64-mingw32-gcc -o tw_lex.exe tw_lex.tab.c lex.yy.c

exe64: tw_lex.tab.c lex.yy.c tw_lex.tab.h
	x86_64-w64-mingw32-gcc -o tw_lex_64.exe tw_lex.tab.c lex.yy.c
