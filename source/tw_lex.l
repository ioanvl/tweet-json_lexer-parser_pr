%{

#include "tw_lex.tab.h"

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
extern int yylex();
extern void yyerror();

extern char * tweet_text;	//string pou periexei oloklro to tweet gia na ektypw8ei sto telos	
extern void add_text(char*, int );	//synarthsh pou grafei to tweet sthn parapanw metavlhth
extern int line;			//metavlhtes pou xrhsimopoiountai mesa sthn add_tet
extern int indentation;		// >>
int indent_flag=0;			// >>

extern bool flags[8]; 	/*flags elegxoun oti ta aparaithta entries emfanhsthkan sto tweet
0: created at
1: id string
2: text field
3: user field
4: id
5: name
6: screen name
7: location
*/

%}

%option noyywrap

ws		[ \t\r\f]+
nws		{ws}*

letter	[a-zA-Z]
digit	[0-9]
number	{digit}{digit}+

oper	[+\/\-\*]
gen_s	[\.\&\:\?\|\#\\,\!\@\$\%\^\*\(\)]
sl		\\\/
col		{nws}\:{nws}


text	({letter}|{digit}|{ws}|{oper}|{gen_s}|{sl})*
alnumer ({letter}|{digit}|{ws})*
name 	{letter}(({letter}|\_)*)


%x names
%x id_num
%x al_num


%%




<INITIAL,names,id_num,al_num>{nws}\{{nws}		{BEGIN(names); 				//efoson diavasoume aggyhlh perimenoume to epomeno stoixeio na einai onoma
																			//sto state auto -names- epistrefoume tokens-epikefalides, mexri na diavastei kapoio diaxwristiko
													add_text("{",2);
													indent_flag=1;
													return OPEN_B;}
<INITIAL,names,id_num,al_num>{nws}\}{nws}		{BEGIN(names); 
													add_text("}",3); 		//otidhpote diavastei apo ton parser stelnetai sthn add_text synarthsh pou kataskeuzei to teliko output 
													indent_flag=0;
													return CLOSE_B;}
<INITIAL,names,id_num,al_num>{nws}\[{nws}		{BEGIN(names); 
													add_text("[",2); 
													indent_flag=2;
													return OPEN_A;}
<INITIAL,names,id_num,al_num>{nws}\]{nws}		{BEGIN(names); 
													add_text("]",3); 
													indent_flag=0;
													return CLOSE_A;}



<names>\"created\_at\"	{flags[0]=true; add_text(yytext,1);		//diavazoume kai epistrefoume ka8e token pou perimenoume na vre8ei 
																//s ena tweet kai 8etoume to flag tou 
							BEGIN(0); 				//epistrefoume ton parser sto arxiko 'geniko' state anagnwshs - exoume diavasei onoma opote perimenoume content
							return CREATED; 
						}
<names>\"id_str\"		{flags[1]=true; add_text(yytext,1);
							BEGIN(al_num); 
							return ID_ST; 
						}
<names>\"text\"			{flags[2]=true; add_text(yytext,1);
							BEGIN(0); 
							return TXT; 
						}
<names>\"user\"			{flags[3]=true; add_text(yytext,1);
							BEGIN(0); 
							return USER; 

						}
<names>\"id\"			{flags[4]=true; add_text(yytext,1);
							BEGIN(id_num); 		//8etoume ton parser sto state 'id_num' h 'alnum' parakatw, gia dieukolynsh mas ws pros tous kanones anagnwshs
							return ID; 
						}
<names>\"name\"			{flags[5]=true; add_text(yytext,1);
							BEGIN(al_num);
							return NAME;
						}
<names>\"screen_name\"	{flags[6]=true; add_text(yytext,1);
							BEGIN(al_num); 
							return SCREEN;
						}
<names>\"location\"		{flags[7]=true; add_text(yytext,1);
							BEGIN(al_num); 
							return LOC;
						}
<names>\"{name}\"		{add_text(yytext,1);
							BEGIN(0); return OTHER;
						}


<al_num>{alnumer}		{yylval.c_val = strdup(yytext); add_text(yytext,0);		//to state alnum dexetai mono alfari8mitika, xwris symvola
						return ALNUM;
					}

<al_num,id_num>{nws}\"{nws}	{add_text("\"",0);
							}



<id_num>[\-\+]?{number}		{yylval.c_val = strdup(yytext); add_text(yytext,0);	//antistoixa to id num diavazei mono ari8mous me proshmo
							return NUM;
						}	

<id_num>,				{add_text(",\n",0);BEGIN(names);}



<INITIAL,names>\"		{add_text("\"",0);
						}


<INITIAL,al_num>{nws}\"\,{nws}		{add_text("\",\n",0);
									BEGIN(names);
								}

<INITIAL,id_num,al_num>{col}	{add_text(":",0);}

{text}	{yylval.c_val = strdup(yytext); add_text(yytext,0);
		return TEXT;
	}

<INITIAL,id_num,names,al_num>\n {line++;}


<INITIAL,id_num,names,al_num>.			;



%%

