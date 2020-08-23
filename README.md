# tweet-json_lexer-parser_pr
A "tweet" lexer/parser created as part of a university compiler class project. Written in C++, Flex and Bison (though probably _mostly_ compatible with the original lex/yacc stack).

-------------------

## General
Goal of the assingment was to parse a text file with "tweets" and output them on the screen, along with proper error messages, or an OK message if both the structure and contents seem to be ok - the content checks though are not that strong, and mostly simply alphanumeric - or date/emptyness checks.
A sample default 'input' file is provided, with a 'correct' entry, that's also read by default if no file is provided by the user on call.

### Fles - tw_lex.l
The lexer part, expects specific words or regular expressions and tokenizes the input to pass them on to the parser. 'States' are used to ease up the proccess a little - practicaly in the default state if you read  [ *":* ] means you just had a label and move on to read its content.

### Bison - tw_lex.y
The parser is a more generic json parser, with added checks and specific entries to ensure the structure validity of the "tweet". Can be made into a generic json parser with some light edits, mostly removing those specific checks.

#### BNF Grammar
<tweet_file> ::= <tweets>
<tweets> ::= <tweet> | <tweet>
<tweets> <tweet> ::= “{“ <body> “}”

<body> ::= <entry> | <body> <entry>
<entry> ::= <created_e> | <id_string> | <text_e> | <user_entry> | <other_pair>

<user_entry> ::= “{” <user_body> “}"
<user_body>::= <user_item> | <user_body> <user_item>
<user_item> ::= <id_entry> | <name_e> | <screen_name> | <location> | <other_pair>

<created_e> ::= <CREATED> <TEXT>
<id_string> ::= <ID_ST> <ALNUM>
<text_e> ::= <TXT> <TEXT>
<id_entry> ::= <ID> <NUM>
<name_e> ::= <NAME> <alphanum> <screen_name> ::=<SCREEN> <alphanum>
<location> ::= <LOC> <alphanum>

<other_pair> ::= |<pair> | <other_pair> <pair>
<pair> ::= <OTHER> <value>
<value> ::= <text_field> | <object>| <list>

<object> ::= “{“ “}” | “{” <other_pair> “}”
<list> ::= “[“ “]” | “[“ <list_items> “]”
<list_items> ::= <value> | <list_items> <value>
<alphanum> ::= <ALNUM> | <ALNUM> <alphanum>
<text_field> ::= <TEXT> | <text_field> <TEXT>