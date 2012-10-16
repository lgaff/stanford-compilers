/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int add_to_buffer(char *str);
void reset_buffer();

/*
 *  Add Your own definitions here
 */

%}
/* Line and block comment start conditions */
%Start LCMNT BCMNT STRCONST STRESC
/*
 * Define names for regular expressions here.
 */

 /* basic character classes */
DIGIT     [0-9]
UPCHAR    [A-Z]
DOWNCHAR  [a-z]
TYPEID    [A-Z][a-zA-Z0-9_]+
OBJECTID [a-z][a-zA-Z0-9_]+
QUOTE    [\"]
SLOSH \\

/* operators */
DARROW    => 
ASSIGN <-
/* punctuation */

LPAREN \(
RPAREN \)
LBRACE \{
RBRACE \}
TERMINATOR [;]
LCMNT     --
BCMT_OP   \(\*
BCMT_CL   \*\)

/* keywords and identifiers */
BTRUE     true
BFALSE    false

WHITESPACE [\t\n ]+
%%

 /*
  *  Nested comments
  */
--                      { BEGIN LCMNT; }
<LCMNT>[^\n]*           { }
<LCMNT>\n               { BEGIN 0; } 
\(\*                    { BEGIN BCMNT; }
<BCMNT>[^\*]/[^\)]*     { }
<BCMNT><<EOF>>          { BEGIN 0; 
                        cool_yylval.error_msg = "EOF in comment"; 
		        return ERROR; 
                        }
<BCMNT>{BCMT_CL}        { BEGIN 0; }   
{BCMT_CL}               { cool_yylval.error_msg = "Unmatched *)"; 
                        return ERROR; 
                        }
                        /*
                        *  The multiple-character operators.
                        */
<INITIAL>{DARROW}      	{ return (DARROW); }
<INITIAL>{ASSIGN}       { return (ASSIGN); }

                        /*
                        * Keywords are case-insensitive except for the values true and false,
                        * which must begin with a lower-case letter.
                        */
<INITIAL>{BTRUE}        { cool_yylval.boolean = true; return (BOOL_CONST); }
<INITIAL>{BFALSE}       { cool_yylval.boolean = false; return (BOOL_CONST); }
<INITIAL>(?i:class)     { cool_yylval.symbol = idtable.add_string(yytext); return (CLASS); }
<INITIAL>(?i:else)      { cool_yylval.symbol = idtable.add_string(yytext); return (ELSE); }
<INITIAL>(?i:fi)        { cool_yylval.symbol = idtable.add_string(yytext); return (FI); }
<INITIAL>(?i:if)        { cool_yylval.symbol = idtable.add_string(yytext); return (IF); }
<INITIAL>(?i:in)        { cool_yylval.symbol = idtable.add_string(yytext); return (IN); }
<INITIAL>(?i:inherits)  { cool_yylval.symbol = idtable.add_string(yytext); return (INHERITS); }
<INITIAL>(?i:let)       { cool_yylval.symbol = idtable.add_string(yytext); return (LET); }
<INITIAL>(?i:loop)      { cool_yylval.symbol = idtable.add_string(yytext); return (LOOP); }
<INITIAL>(?i:pool)      { cool_yylval.symbol = idtable.add_string(yytext); return (POOL); }
<INITIAL>(?i:then)      { cool_yylval.symbol = idtable.add_string(yytext); return (THEN); }
<INITIAL>(?i:while)     { cool_yylval.symbol = idtable.add_string(yytext); return (WHILE); }
<INITIAL>(?i:case)      { cool_yylval.symbol = idtable.add_string(yytext); return (CASE); }
<INITIAL>(?i:esac)      { cool_yylval.symbol = idtable.add_string(yytext); return (ESAC); }
<INITIAL>(?i:of)        { cool_yylval.symbol = idtable.add_string(yytext); return (OF); }
<INITIAL>(?i:new)       { cool_yylval.symbol = idtable.add_string(yytext); return (NEW); }
<INITIAL>(?i:isvoid)    { cool_yylval.symbol = idtable.add_string(yytext); return (ISVOID); }
<INITIAL>(?i:not)       { cool_yylval.symbol = idtable.add_string(yytext); return (NOT); }
<INITIAL>{TYPEID}       { cool_yylval.symbol = idtable.add_string(yytext); return (TYPEID); }
<INITIAL>{OBJECTID}     { cool_yylval.symbol = idtable.add_string(yytext); return (OBJECTID); }

                        /*
                        *  String constants (C syntax)
                        *  Escape sequence \c is accepted for all characters c. Except for 
                        *  \n \t \b \f, the result is c.
                        *
                        */
<INITIAL>{QUOTE}        { BEGIN STRCONST; string_buf_ptr = string_buf; }
<STRCONST>[^\\\"\0]* { printf("<STRCONST>[^\\\"\\0]*: %s\n", yytext); if(!add_to_buffer(yytext)) { BEGIN 0; return ERROR; } }
<STRCONST>\\. { printf("<STRCONST>\\.: %s\n", yytext); if(!add_to_buffer(yytext)) { BEGIN 0; return ERROR; } }
<STRCONST>\\\n { printf("<STRCONST>\\\\n: %s\n", yytext); if(!add_to_buffer(yytext)) { BEGIN 0; return ERROR; } }
<STRCONST>{QUOTE}       { BEGIN 0; 
                          cool_yylval.symbol = stringtable.add_string(string_buf);
                          reset_buffer();
                          return STR_CONST;
                        }
<STRCONST><<EOF>>       { BEGIN 0; cool_yylval.error_msg = "EOF in string constant."; return ERROR; }
<STRCONST>\0            { BEGIN 0; cool_yylval.error_msg = "String contains null character."; return ERROR; }

<INITIAL>{DIGIT}+       { cool_yylval.symbol = inttable.add_string(yytext); return (INT_CONST); }

 /* change this later. whitespace should be stripped */
 /*{WHITESPACE} { cool_yylval.symbol = stringtable.add_string(yytext); return STR_CONST; } */
%%

int add_to_buffer(char *str)
{
     printf("ENTER: %s\n", str);
     char next;
     while((next = *str++) != '\0') {
          printf("char(%c): ", next);
          if(string_buf_ptr == &(string_buf[MAX_STR_CONST])) {
               cool_yylval.error_msg = "String constant too long.";
               return 0;	
          }
          else {
               if(next == '\n') {
                    printf("Matched newline.\n");
                    cool_yylval.error_msg = "Unterminated string constant.";
                    return 0;
               }                    
               if(next == '\\') {
                    printf("Matched \\.\n");
                    next = *str++;
                    printf("switch char(%c): ", next);
                    switch(next) {
                    case 'n':
                         printf("matched n.\n");
                         next = '\n';
                         break;
                    case 't':
                         printf("matched t.\n");
                         next = '\t';
                         break;
                    case 'b':
                         printf("matched b.\n");
                         next = '\b';
                         break;
                    case 'f':
                         printf("matched f.\n");
                         next = '\f';
                         break;
                    case '\\':
                         printf("matched \\.\n");
                         next = '\\';
                         break;
                    case '0':
                         printf("matched 0.\n");
                         next = '\0';
                         break;
                    default:
                         printf("matched %c.\n", next);
                         /* next = next (Just pass it through) */
                         break;
                    }
               }
               printf("%c onto *string_buf_ptr, ", next);
               *string_buf_ptr++ = next;
               printf("Buffer contents now: %s\n", string_buf);
          }
     }
     return 1;
}

void reset_buffer()
{
     int i;
     for(i = 0;i <= MAX_STR_CONST;i++) { string_buf[i] = '\0'; }
     string_buf_ptr = string_buf;
}
