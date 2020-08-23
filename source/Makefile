all: tw_lex

tw_lex: tw_lex.tab.c lex.yy.c tw_lex.tab.h
	gcc -o tw_lex tw_lex.tab.c lex.yy.c

tw_lex.tab.c tw_lex.tab.h: tw_lex.y
	bison -d tw_lex.y

lex.yy.c: tw_lex.l tw_lex.tab.h
	flex tw_lex.l
	
clean:
	rm tw_lex tw_lex.tab.c lex.yy.c tw_lex.tab.h

ltest: tw_lex_test.l
	flex tests/tw_lex_test.l
	gcc -o test lex.yy.c

test: flagtest.c
	gcc -o test tests/flagtest.c

exe: tw_lex.tab.c lex.yy.c tw_lex.tab.h
	i686-w64-mingw32-gcc -o tw_lex.exe tw_lex.tab.c lex.yy.c

exe64: tw_lex.tab.c lex.yy.c tw_lex.tab.h
	x86_64-w64-mingw32-gcc -o tw_lex_64.exe tw_lex.tab.c lex.yy.c
