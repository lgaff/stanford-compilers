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
bool strconst_err = false;
int char_count;

/*
 *  Add Your own definitions here
 */

int comment_nest = 0;

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
TYPEID    [A-Z][a-zA-Z0-9_]*
OBJECTID [a-z][a-zA-Z0-9_]*
QUOTE    [\"]
SLOSH \\

/* operators */
DARROW    => 
ASSIGN <-
LTE <=

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
BTRUE     t(?i:rue)
BFALSE    f(?i:alse)

WHITESPACE [\t\f\r\v ]+
%%

 /*
  *  Nested comments
  */
<INITIAL>--             { BEGIN LCMNT; }
<LCMNT>[^\n]*           { }
<LCMNT>\n               { curr_lineno++; BEGIN 0; } 
<INITIAL>\(\*           { comment_nest++; BEGIN BCMNT; }
<BCMNT>{BCMT_OP}        { comment_nest++; }
<BCMNT>{BCMT_CL}        { if(--comment_nest == 0) {  BEGIN 0; } }
<BCMNT>[^(*\n]*         { /* OM NOM NOM NOM */ }
<BCMNT>[*]/[^()\n]*     { /* OM NOM NOM NOM */ }
<BCMNT>\([^*\n]*        { /* OM NOM NOM NOM */ }
<BCMNT>\n               { curr_lineno++; }

<BCMNT><<EOF>>          { BEGIN 0; 
                        cool_yylval.error_msg = "EOF in comment"; 
                        return ERROR; 
                        }
<INITIAL>{BCMT_CL}      { cool_yylval.error_msg = "Unmatched *)"; 
                        return ERROR; 
                        }
                    /* Single character arithmetic operators */
<INITIAL>[\-+*/~]    { return ((char)yytext[0]); }
<INITIAL>[;:(){},.@]  { return ((char)yytext[0]); }
<INITIAL>[<=]  { return ((char)yytext[0]); }
                    /*
                    *  The multiple-character operators.
                        */
<INITIAL>{LTE} { return (LE); }
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
<STRCONST>[^\\\"\0\n]*  { add_to_buffer(yytext); }
<STRCONST>\0            { if(!strconst_err) 
                          { 
                               cool_yylval.error_msg = "lex String contains null character."; 
                               strconst_err = true; 
                          } 
                          
                        }
<STRCONST>\\.           { add_to_buffer(yytext); }
<STRCONST>\n            { curr_lineno++;
                          BEGIN 0; 
                          reset_buffer(); 
                          if(!strconst_err) 
                          { 
                               cool_yylval.error_msg = "Unterminated string constant."; 
                               return ERROR;

                          } 
                        }
<STRCONST>\\\n          { curr_lineno++; add_to_buffer(yytext); }
<STRCONST>{QUOTE}       { BEGIN 0; 
                          if(strconst_err) { 
                               reset_buffer();
                               return ERROR;
                          }
                          else {
                               cool_yylval.symbol = stringtable.add_string(string_buf);
                               reset_buffer();
                               return STR_CONST;
                          }
                        }
<STRCONST><<EOF>>       { BEGIN 0; 
                          if(!strconst_err) 
                          { 
                               cool_yylval.error_msg = "EOF in string constant."; 
                               return ERROR;
                          }
                          reset_buffer(); 
                          return ERROR; 
                        }

<INITIAL>{DIGIT}+       { cool_yylval.symbol = inttable.add_string(yytext); return (INT_CONST); }





{WHITESPACE} { /* Strip whitepace */ }
<INITIAL>\n { curr_lineno++; }
. { cool_yylval.error_msg = yytext; return ERROR; }
%%

int add_to_buffer(char *str)
{  
     char next;
     while((next = *str++) != '\0') {
          if(string_buf_ptr == &(string_buf[MAX_STR_CONST-1])) {
               if(!strconst_err) 
               {
                    cool_yylval.error_msg = "String constant too long.";
               }
               strconst_err = true;
               return 0;
          }
          else {
               if(next == '\n') {
                    if(!strconst_err)
                    {
                         cool_yylval.error_msg = "Unterminated string constant.";
                         printf("Unterminatador: \"%s\"\n", yytext);
                    }
                    strconst_err = true;
               }                    
               if(next == '\\') {
                    next = *str++;
                    switch(next) {
                    case 'n':
                         next = '\n';
                         break;
                    case 't':
                         next = '\t';
                         break;
                    case 'b':
                         next = '\b';
                         break;
                    case 'f':
                         next = '\f';
                         break;
                    case '\\':
                         next = '\\';
                         break;
                    case '0':
                         next = '0';
                         break;
                    case '\0':
                         if(!strconst_err)
                         {
                              cool_yylval.error_msg = "String contains null character.";
                         }
                         strconst_err = true;
                         break;
                    default:
                         /* next = next (Just pass it through) */
                         break;
                    }
               }
               *string_buf_ptr++ = next;
          }
     }
     return 1;
}

void reset_buffer()
{
     int i;
     for(i = 0;i <= MAX_STR_CONST;i++) { string_buf[i] = '\0'; }
     string_buf_ptr = string_buf;
     strconst_err = false;
}

