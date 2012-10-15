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

/*
 *  Add Your own definitions here
 */

%}
/* Line and block comment start conditions */
%Start LCMNT BCMNT
/*
 * Define names for regular expressions here.
 */

 /* basic character classes */
DIGIT           [0-9]
 /* operators */
DARROW          => 
 /* punctuation */

LCMNT           --
BCMT_OP         \(\*
BCMT_CL         \*\)

 /* keywords and identifiers */
BTRUE            true
BFALSE           false
%%

 /*
  *  Nested comments
  */
--                          { BEGIN LCMNT; }
<LCMNT>[^\n]*               { }
<LCMNT>\n                   { BEGIN 0; } 
\(\*                        { BEGIN BCMNT; }
<BCMNT>[^\*]/[^\)]*         { }
<BCMNT><<EOF>>              { BEGIN 0; 
                              cool_yylval.error_msg = "EOF in comment"; 
			      return ERROR; 
                            }
<BCMNT>{BCMT_CL}            { BEGIN 0; }   
{BCMT_CL}                   { cool_yylval.error_msg = "Unmatched *)"; 
                              return ERROR; 
                            }
 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{BTRUE}            { cool_yylval.boolean = true; return BOOL_CONST; }
{BFALSE}           { cool_yylval.boolean = false; return BOOL_CONST; }
(?i:class)         { cool_yylval.symbol = idtable.add_string(yytext); return CLASS; }
(?i:else)          { cool_yylval.symbol = idtable.add_string(yytext); return ELSE; }
(?i:fi)            { cool_yylval.symbol = idtable.add_string(yytext); return FI; }
(?i:if)            { cool_yylval.symbol = idtable.add_string(yytext); return IF; }
(?i:in)            { cool_yylval.symbol = idtable.add_string(yytext); return IN; }
(?i:inherits)      { cool_yylval.symbol = idtable.add_string(yytext); return INHERITS; }
(?i:let)           { cool_yylval.symbol = idtable.add_string(yytext); return LET; }
(?i:loop)          { cool_yylval.symbol = idtable.add_string(yytext); return LOOP; }
(?i:pool)          { cool_yylval.symbol = idtable.add_string(yytext); return POOL; }
(?i:then)          { cool_yylval.symbol = idtable.add_string(yytext); return THEN; }
(?i:while)         { cool_yylval.symbol = idtable.add_string(yytext); return WHILE; }
(?i:case)          { cool_yylval.symbol = idtable.add_string(yytext); return CASE; }
(?i:esac)          { cool_yylval.symbol = idtable.add_string(yytext); return ESAC; }
(?i:of)            { cool_yylval.symbol = idtable.add_string(yytext); return OF; }
(?i:new)           { cool_yylval.symbol = idtable.add_string(yytext); return NEW; }
(?i:isvoid)        { cool_yylval.symbol = idtable.add_string(yytext); return ISVOID; }
(?i:not)           { cool_yylval.symbol = idtable.add_string(yytext); return NOT; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */



%%
