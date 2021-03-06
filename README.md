# tweet-json_lexer-parser_pr
A "tweet" lexer/parser created as part of a university compiler class project. Written in C++, Flex and Bison (though probably _mostly_ compatible with the original lex/yacc stack).

-------------------

## General
The goal of the assingment was to parse a text file with "tweets" and output the entries on the screen, along with proper error messages, or an OK message if both the structure and contents seem to be correct - though the content checks are not that strong, and mostly simply alphanumeric, or date/emptyness checks.  
A sample default "input" file is provided, with a 'correct' entry, that's also read by default if no file is provided by the user on call.

-------------------

### I.Fles - tw_lex.l
The lexer part, expects specific words or regular expressions and tokenizes the input to pass them on to the parser. 'States' are used to ease up the proccess a little - practicaly in the default state if you read  [ *":* ] means you just had a label and move on to read its content.

### II.Bison - tw_lex.y
The parser is a more generic json parser, with added checks and specific grammar entries to ensure the structure validity of the "tweet".  
i.e. an 'entry', depending on the tokens returned from the lexer, can be a generic 'other pair' or one of the "id", "created", "user" (with "user" expecting its own preset inputs). Each of the "id", "created", "user_name" etc. entries raise a flag accordingly, with those flags used later for said checks.  
The parser can be made into a generic json parser with some light edits, mostly removing those checks and accompanying grammar entries.

#### BNF Grammar
tweet_file ::= tweets  
tweets ::= tweet | tweet  
tweets tweet ::= “{“ body “}”  

body ::= entry | body entry  
entry ::= created_e | id_string | text_e | user_entry | other_pair  

user_entry ::= “{” user_body “}"  
user_body::= user_item | user_body user_item  
user_item ::= id_entry | name_e | screen_name | location | other_pair  

created_e ::= CREATED TEXT  
id_string ::= ID_ST ALNUM  
text_e ::= TXT TEXT  
id_entry ::= ID NUM  
name_e ::= NAME alphanum screen_name ::=SCREEN alphanum  
location ::= LOC alphanum  

other_pair ::=  | pair | other_pair pair  
pair ::= OTHER value  
value ::= text_field | object| list  

object ::= “{“ “}” | “{” other_pair “}”  
list ::= “[“ “]” | “[“ list_items “]”  
list_items ::= value | list_items value  
alphanum ::= ALNUM | ALNUM alphanum  
text_field ::= TEXT | text_field TEXT  

### III.Example output
- File with no errors
![Alt text](/screeshots/correct.png?raw=true "correct")
- Example file with lines randomly deleted
![Alt text](/screeshots/err1.png?raw=true "correct")

### Requirements
- gcc  
- flex  
- bison

-------------------

#### Course:
University of Patras, Computer Engineering and Informatics Dept.  
Principles of Programming Languages and Compilers- 2019
