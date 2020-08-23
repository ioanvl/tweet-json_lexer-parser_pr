
%{
#include <stdio.h>
#include <string.h>
#include <stdbool.h>	

#define __USE_XOPEN 
#define _GNU_SOURCE
#include <time.h>

#define HEADROOM 20


//epekteinoume tis aparaithtes synarthseis apo ton parser
extern int yylex();
extern int yyparse();
extern void yyerror();
extern FILE *yyin;
extern char* yytext;

bool dprint=false;		//metavlhth gia kapoia generic debuging mynhmata ston kwdika


bool flags[8];	
/*array that ensures the necessary entries appear
0: created at
1: id string
2: text field
3: user field
4: id
5: name
6: screen name
7: location*/


char * tweet_text;				//metavlhtes gia thn katagrafh ths eisodou
int indentation;
extern int indent_flag;
void add_text(char*,int);		//synarthsh 	>> 		>>		>>

int line=1;
int tweet_number=0;


struct tm tm;						//struct needed to check timestamp


char**stringid_array;		//table to hold tweet string_ids
long int*id_array;				//table to hold tweet ids
void add_id(char*);				//funcions to search and add IDs
void add_stringid(char*);



char errorm [50];		//metavlhth pou 8a krataei proswrina to error message gia na perasei stn antistoixh synarthsh
int error_num=0;
typedef struct 			//structure pou apo8ykeuetai kapoio error
{
	int line;
	int tweet;
	char* error_msg;
} error_data;
error_data * er_pointer;	//dynamiko array gia ta errors
void error_report();		//ektypwnei ta errors sto telos ths ekteleshs
void t_reset();


%}

%union{
	char *c_val;
	int i_val;
}

%start tweet_file
%token CREATED ID_ST TXT USER ID NAME SCREEN LOC OTHER 
%token  NL
%token <c_val>TEXT ALNUM NUM

%left OPEN_B CLOSE_B CLOSE_A OPEN_A

%%

tweet_file:
	tweets					{printf("\n__PARSE Complete\n");}
	;

tweets:
	tweet
	| tweets tweet
	;

tweet:
	OPEN_B body CLOSE_B 		{printf("\n+----- \nTWEET %d READ \n+-----\n\n\n", tweet_number);
									//otan diavastei ena tweet, elegxoume an yparxan ola ta aparaithta stoixeia 
									if (flags[0] & flags[1] & flags[2] & flags[3]){;}
									else{
										yyerror ("Missing MAIN body elements");
									}
									t_reset(); 		//reset values gia to epomeno tweet
								}
	|OPEN_B body error 			{yyerror("!- Tweet entry could not recover and was discarded"); //sthn periptwsh pou de mporei na ginei recover, aporiptetai olo to tweet kai shmeiwnetai to la8os
									printf("\n+----- \nTWEET %d FAILED \n+-----\n\n\n", tweet_number);
									t_reset();
								}
	|OPEN_B error CLOSE_B		{yyerror("!- Tweet entry could not recover and was discarded"); //sthn periptwsh pou de mporei na ginei recover, aporiptetai olo to tweet kai shmeiwnetai to la8os
									printf("\n+----- \nTWEET %d FAILED \n+-----\n\n\n", tweet_number);
									t_reset();
								}
	;


body:
	entry
	| body entry
	| body error			{yyerror("Bad entry in main body");}
	;

entry:
	created_e
	| id_string
	| text_e
	| user_entry
	| other_pair
	;


user_entry:
	USER OPEN_B user_body CLOSE_B	{
										//molis diavastei oloklhro to entry 'body' elegxoume an perieixe ta aparaithta entries
										if (flags[4] & flags[5] & flags[6] & flags[7]){;}
										else{
											yyerror ("Missing USER body elements");
										}
									}
	|USER OPEN_B user_body error 	{yyerror("Bad format in user body");}
	;

user_body:
	user_item
	| user_body user_item
	| user_body error 			{yyerror("Bad term in user body");}
	;

user_item:
	id_entry
	| name_e
	| screen_name
	| location
	| other_pair
	;


created_e:
	CREATED TEXT	{
						//dinoume thn eisodo sthn sprtime pou epistrefei NULL an an to input ths DEN einai hmeromhnia 
						if ( strptime($2, "%a %b %d %H:%M:%S +%H%M %G", &tm) == NULL ){
							yyerror ("Wrongly formated timestamp");		//an apotyxei shmeiwnoume to la8os
						}
					}
				;

id_string:
	ID_ST ALNUM 	{	
						add_stringid($2);
					}
				;

text_e:
	TXT TEXT		{
						if (strlen($2) > 140)
						{
							yyerror ("Text entry too long");
						}
					}
				;

id_entry:
	ID NUM 			{
						add_id($2);
					}
	;

name_e:
	NAME alphanum;

screen_name:
	SCREEN alphanum;

location:
	LOC alphanum;

alphanum:
	ALNUM
	| ALNUM alphanum
	;

text_field:
	TEXT
	| text_field TEXT
	;

other_pair:
	pair
	| other_pair pair 
	| error;

pair:
	OTHER value;

value:
	text_field
	| object
	| list
	;

object:
	OPEN_B CLOSE_B
	| OPEN_B other_pair CLOSE_B
	| OPEN_B other_pair error
	| OPEN_B error
	;

list:
	OPEN_A CLOSE_A
	| OPEN_A list_items CLOSE_A
	| OPEN_A list_items error
	| OPEN_A error
	;

list_items:
	value
	| list_items value 
	;


%%


#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>


int main(int argc, char** argv){

//arxikopoioume ola ta arrays pou 8a xreiastoun kata thn ektelesh

	tweet_text=malloc(2);	//xrhsimopoieitai gia na ektypws8ei to teliko output
	tweet_text[0]='\0';		//initialize 'manually'
	indentation=0;	
	stringid_array=malloc(2*sizeof(char*));
	id_array=malloc(2*sizeof(int));
	er_pointer=malloc(2*sizeof(*er_pointer));

	bool file_flag=false;
	FILE *myfile;

	if (argc>1)
	{
		myfile = fopen(argv[1], "r");
		if (!myfile){												//an dw8ei file ws input elexoume an mporei na diavastei
			printf("\nCant open specified file...\n");
		}
		else{
			printf("\nReading from file: \"%s\"\n", argv[1]);
			file_flag=true;
		}
	}
	else{
		printf("\nNo file specified...\n");
	}

	if (!file_flag)				//an de dw8hke arxeio h de ginotan na diavastei, fallback sto default
	{	
		printf("Falling back to default, \"input\"\n+-----\n");
		myfile = fopen("input", "r");
		if (!myfile){
			printf("\n!! Cant open backup file, terminating\n");		//an gia kapoio logo de mporei na diavastei oute auto, termatizoume
			return -1;
		}
	}

	yyin = myfile;		//file ws eisodos tou parser

	do {				//parse mexri to telos ths eisodou
		yyparse();
	} while (!feof(yyin));

	error_report();		//report opoia la8h vre8hkan

	free(tweet_text);
	free(stringid_array);
	free(id_array);
	free(er_pointer);
	//eleu8erwnoume desmeumeno xwro

}


void error_report(){
	if(error_num == 0){
        printf("\n\n---------------------------------------\n");
	    printf("Syntax is correct!!!\n");
    } else {					//an yphr3an la8h, diatrexoume to array sto opoio apo8ykeuontai kai ta ektypwnoume
    	printf("\n\n================================\nSyntax had %d errors\n", error_num);
    	for (int i = 0; i < error_num; ++i)
    	{
    		if (i){ if(er_pointer[i].tweet != er_pointer[i-1].tweet){printf("*\n");}}
    		printf("ERROR_ Tweet#%d: %s in line %d\n", er_pointer[i].tweet, er_pointer[i].error_msg, er_pointer[i].line);
    	}
    }
}

void yyerror(const char *s) {

	// h synarthsh auth katagrafei ta la8h kata thn ektelesh

	bool a_ok = true;

	if (error_num > 0)
	{
		if ((er_pointer[error_num-1].line == line)&&(strcmp(er_pointer[error_num-1].error_msg, s)== 0))
		{
			a_ok=false;		//apofeugoume diplotypa idia la8h, symvainei merikes fores otan
		}					//o parser xreiastei merikes prospa8eies prin epanel8ei
	}
	
	if (a_ok)
	{
	error_data *error_size;														//dhmiourgoume ena error struct pointer

	if (er_pointer=realloc(er_pointer, ((error_num+2)*sizeof(*error_size))))	//resize to array twn errors mesw tou parapanw temo (somehow htan o cleanest tropos oswn afora segfaults)
	{
		er_pointer[error_num].error_msg=malloc(strlen(s));			//efoson ginei to resize desmeuoume xwro gia ta epimerous entries
    	strcpy(er_pointer[error_num].error_msg, s);					//kai katagrafoume ta stoixeia
		er_pointer[error_num].line = line;
		er_pointer[error_num].tweet = tweet_number;
	}
	error_num++;
	}
}

void t_reset(){

//trexei sto telos ths anagnwshs ka8e tweet - ypo8etoume oti mporei na periexontai polla s ena arxeio

	tweet_text=realloc(tweet_text, (strlen(tweet_text)+2)*sizeof(char));
	//sthn periptwsh kapoiwn la8wn ginetai discard olh h eisodos kai mexri na epanel8oume se shmeio pou mporei na synexisei to parsing
	//mporei na diavastoun kapoioi oroi kai na dhmiourgh8oun kapoion 'mhdenika'-eikonika tweets
	//s auth thn periptwsh to tweet_text einai keno kai exoume segfault sto free 
	// gi auto vazoume th realloc , pou eite 8a prosferei 2 akoma byte sto text h 8a ana8esei, an den yparxei - opote h free douleuei swsta
	
	if (strlen(tweet_text)>2)printf("%s\n",tweet_text); 	//an yparxei keimeno to typwnoume
	free(tweet_text);										//eleu8erwnoume to xwro
	tweet_text=malloc(2);									//desmeuoume pali, gia to epomeno tweet
	tweet_text[0]='\0';										//init
	tweet_number++;
	for (int i = 0; i < 8; i++)
	{
		flags[i]=false;										//reset tis shmaies
	}
}

void add_id(char* enter_id){
	bool found=false;

	//printf("!!!!---------ADD_ID\n");
	long int id_num = atol(enter_id);		//metatreoume thn eisodo apo string se sri8mo
	//printf("%ld\n", id_num );

	for (int i = 0; i < tweet_number; ++i){	//4axnoume an exei ypar3ei kapoio allo tweet me idio ID
		if(id_array[i]==id_num){
			found=true;
		}
	}
	if (found)
	{										//an to ID einai duplicate shmeiwnetai ws error
		memset(errorm,0,sizeof(errorm));
		sprintf(errorm, "String_ID: %ld  duplicate", id_num);
		yyerror (errorm);
			
	}


	if (id_array=realloc(id_array, ((tweet_number+2)*sizeof(*id_array))))	//desmeuoume xwro sto array twn IDs gia to kainourgio entry
	{
		id_array[tweet_number]=id_num;										//an dw8ei xwros, apo8ykeuoume to ID
	}
	else
	{																		//alliws grafoume error
		memset(errorm,0,sizeof(errorm));
		sprintf(errorm, "!! - Couldn't add tweet#%d ID", tweet_number);
		yyerror (errorm);
	}
}


void add_stringid(char* enter_string){

	//ousiastika idia me thn add_id mono pou edw ta arrays einai char

	bool found=false;
	//printf("!!!!---------ADD_Str_ID\n");

	for (int i = 0; i < tweet_number; i++){
		if(strcmp(stringid_array[i],enter_string) == 0){
			found=true;
		}
	}
	if (found)
	{
		memset(errorm,0,sizeof(errorm));
		sprintf(errorm, "ID: %s  duplicate", enter_string);
		yyerror (errorm);
			
	}

	if (stringid_array=realloc(stringid_array, ((tweet_number+2)*sizeof(char*))))
	{
		stringid_array[tweet_number]=malloc(strlen(enter_string)+2);		//desmeuoume xwro sth 8esh tou array gia to string 
		stringid_array[tweet_number][0]='\0';
		strcat(stringid_array[tweet_number], enter_string);
	}
	else{
		memset(errorm,0,sizeof(errorm));
		sprintf(errorm, "!! - Couldn't add tweet#%d String_ID", tweet_number);
		yyerror (errorm);
	}

	



	
}

void add_text(char* text, int flag){

//h synarthsh auth katagrafei thn eisodo kai xeirizetai thn emfanish (indentation), h opoia einai ane3arthh auths ths eisodou

//flag - 0 generic text
//flag - 1 'titlos' ara xreiazetai identation
//flag - 2/3 opening/closing bracket gia na elegxoume to indentation

	char * temp_text; 	//temporary metavlhtes pou 8a xreiastoun
	char * new_entry;

	bool freedom_flag=false;
	//an xreiazetai na ginoun allages sto input, px pros8hkh tabs gia indentation tote auto de grafetai kateu8eian
	//alla prwta sthn endiamesh metavlhth new entry - an symvei auto, to flag mas enhmerwnei 
	//oti prepei na eleu8erwsoume auto to xwro sto telos


	if(dprint) printf("+++++++++%s  --  %d ===", text, indent_flag);

	if ((flag==3)&(indentation>0))		//flag = 3 -> aggylh pou kleinei 
	{
		indentation--;			//meiwnoume thn apostash tou keimenou apo thn arxh
	}


	if (flag==1)						//flag = 1 -> geniko text
	{
		if(dprint) printf("1-%d\n", flag); //DEBUG
		new_entry=malloc(strlen(text)+2+indentation);		//desmeuoume ton aparaithto xwro
		for (int i = 0; i < indentation; ++i)
		{
			new_entry[i]='\t';								//pros8etoume osa tabs xreiazontai sthn arxh ths grammhs
		}
		new_entry[indentation]='\0';
		strcat(new_entry, text);							//pros8eoume thn idia th grammh
		freedom_flag=true;
	}
	else if ((flag==2)&(indent_flag==0)){	//flag = 2 -> aggylh pou anoigei
		new_entry=malloc(strlen(text)+3);
		new_entry[0]='\0';
		strcat(new_entry, text);
		strcat(new_entry, "\n");	//efoson anoigei aggylh pame se nea grammh
		indent_flag=1;
		freedom_flag=true;
	}
	else if (((flag==2)&(indent_flag!=0))|(flag==3))	//aggylh pou kleinei h pollosth pou anoigie sth seira (no text inbetween)
	{
		if (tweet_text[strlen(tweet_text)-1]=='\n')		//afairoume extra newline an yparxei (px an prin anoi3e allh aggylh, h yphrxe sto text)
		{
			tweet_text[strlen(tweet_text)-1]='\0';		
		}
		new_entry=malloc(strlen(text)+3+indentation);
		new_entry[0]='\n';								//pros8etoume newline
		for (int i = 0; i < indentation; ++i)
		{
			new_entry[(i+1)]='\t';						//indentation sth new grammh
		}
		new_entry[(indentation+1)]='\0';
		strcat(new_entry, text);
		strcat(new_entry, "\n");
		freedom_flag=true;
	}
	else{
		if(dprint) printf("4-%d\n", flag);
		new_entry=text;
	}



	if (temp_text=malloc(strlen(tweet_text)+strlen(new_entry)+HEADROOM))	//desmeuoume xwro se mia endiamesh metavlhth gia to synoliko keimeno
	{
		temp_text[0]='\0';
		strcat(temp_text,tweet_text);			//efoson dw8ei pros8etoume to arxiko keimeno
		strcat(temp_text,new_entry);			//epeita th grammh
		free(tweet_text);						
		tweet_text=temp_text;					//swap
	}

	if (freedom_flag)
	{
		free(new_entry);						//eleu8erwnoume thn endiamesh metavlhth pou xrhsimopoihsame gia th grammh
	}

	if (flag!=2)
	{
		indent_flag=0;		//xrhsimopoieitai gia na doume an anoigoun polles aggyles sth 
							//seira, ousiastika gia n apofeugoume duplicate newlines kai 
							//voh8a gia na elegxoume thn apostasth tou keimenou ap thn arxh
	}

	if (flag==2)
	{
		indentation++;		//kampylh anoigei to text prepei na grafei pio eswterika
	}

	//printf("!!!!---------TEXT_____done\n");
}

