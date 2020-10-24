 /*
  *  The scanner definition for seal.
  */

 /*
  *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
  *  output, so headers and global definitions are placed here to be visible
  * to the code in the file.  Don't remove anything that was here initially
  */
%{

#include <seal-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <stdint.h>
#include <stdlib.h>

/* The compiler assumes these identifiers. */
#define yylval seal_yylval
#define yylex  seal_yylex

/* Max size of string constants */
#define MAX_STR_CONST 256
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the seal compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE seal_yylval;

/*
 *  Add Your own definitions here
 */
#include <string>
std::string examination_of_string(char * yytext, int yyleng);
 
%}

%option noyywrap
 /*
  * Define names for regular expressions here.
  */
typeid Int|Float|String|Bool|Void
punctuation ";"|","|"("|")"|"{"|"}"|":"
bool "true"|"false"
%%
 /*	
 *	Add Rules here. Error function has been given.
 */
 /*匹配多行注释*/
"/\*"([^*]|\*+[^/])*\*+"/" {for(int i = 0;i < yyleng;i++){
                     if(yytext[i] == '\n') curr_lineno ++;
                    }
                    }

" "|"\t" {}
 /*匹配单行注释*/ 
"/\*"   {char* error = "lose match of annotation */ .";
                strcpy(seal_yylval.error_msg, error);
                return(ERROR);}
"\*/"   {char* error = "lose match of annotation */ .";
                strcpy(seal_yylval.error_msg, error);
                return(ERROR);}
\n       {curr_lineno += 1;}
"var"    {return(VAR);}
"if"     {return(IF);}
"else"   {return(ELSE);}
"while"  {return(WHILE);}
"for"    {return(FOR);}
"break"  {return(BREAK);}
"continue"  {return(CONTINUE);}
"func"      {return(FUNC);}
"return"    {return(RETURN);}
"struct"   {return(STRUCT);}

"=" {return('=');}
"+" {return('+');}
"/" {return('/');}
"-" {return('-');}
"*" {return('*');}
"<" {return('<');}
"~" {return('~');}
"%" {return('%');}
">" {return('>');}
"&" {return('&');}
"!" {return('!');}
"^" {return('^');}
"|" {return('|');}
"&&" {return(AND);}
"||" {return(OR);}
"==" {return(EQUAL);}
"!=" {return(NE);}
">=" {return(GE);}
"<=" {return(LE);}

{typeid} {seal_yylval.symbol = idtable.add_string(yytext);
          return(TYPEID);}
{punctuation} {
                  if(yytext[0] ==  ',') return(',');
                  if(yytext[0] ==  ':') return(':');
                  if(yytext[0] ==  '(') return('(');
                  if(yytext[0] ==  ')') return(')');
                  if(yytext[0] ==  ';') return(';');
                  if(yytext[0] ==  '{') return('{');
                  if(yytext[0] ==  '}') return('}');
                }
  /*
  *匹配字符串采取的策略是，先分类讨论，按照合法的规则进行匹配，最后写debug规则，效果是先把
  *合法的规则匹配到的字符串给保留，剩下的那些不合法的再按照debug规则报错
  *
  */
`(.|\n)*` {
              for(int i = 0;i < yyleng;i++){
                     if(yytext[i] == '\n') curr_lineno ++;
                    }
              if (yyleng > 258) {char* error = "String too long to store!";
                strcpy(seal_yylval.error_msg, error);
                return(ERROR);}

            std::string temp = yytext;
            temp = temp.substr(1,yyleng-2);  //截取不含``的部分
            char* result = (char*) temp.data();
            seal_yylval.symbol = stringtable.add_string(result);
            return(CONST_STRING);}

\"(.*\\0.*)\" { char* error = "String contains null character '\\0'";
                strcpy(seal_yylval.error_msg, error);
                return(ERROR);}//String contains null character '\\0'

\"((\\\")|(\\\n)|[^\"])*\\?\"  {//匹配""所括起来的所有内容
            if (yyleng > 258) {char* error = "String too long to store!";
                strcpy(seal_yylval.error_msg, error);
                return(ERROR);}//超长报错
            if(yytext[yyleng-2]=='\\') 
                { char* error = "string should not end with \\";
                  strcpy(seal_yylval.error_msg, error);
                  return(ERROR);}//末尾\报错
            for(int i= 1 ; i < yyleng-1;i++){
              if (yytext[i] == '\n' && yytext[i-1] != '\\'){
                char* error = "Want to use \n in string? Use \\ before it!";
                strcpy(seal_yylval.error_msg, error);
                return(ERROR);}//含有未加\而换行的错误
            }
            
            std::string temp1 = yytext;  
            temp1 = temp1.substr(1,yyleng-2);  //截取不含""的部分
            char* temp2 = (char*) temp1.data();

            std::string temp3 = examination_of_string(temp2, yyleng-2);
            char* result = (char*) temp3.data();
            seal_yylval.symbol = stringtable.add_string(result);
            return(CONST_STRING);}   //如何处理双引号字符串？里面的转义字符怎么处理,含有换行符如何处理
\"([^\"])*  {   char* error = "EOF in string constant";
                strcpy(seal_yylval.error_msg, error);
                return(ERROR);
              }
 /*测试用，可删*/
 /*\".*\"     {std::string temp = yytext;  //不包含转义的字符串常量
            temp = temp.substr(1,yyleng-2);  //截取不含""的部分
            char* result = (char*) temp.data();
            seal_yylval.symbol = stringtable.add_string(result);
            return(CONST_STRING);}   //如何处理双引号字符串？里面的转义字符怎么处理,含有换行符如何处理
            */
  /*
 \"[^"]*|(\\\")*\" {//匹配一对引号括起来的
                   std::string temp = yytext;
                    temp = temp.substr(1,yyleng-2);  //截取不含``的部分
                    char* result = (char*) temp.data();
                    seal_yylval.symbol = stringtable.add_string(result);
                    return(CONST_STRING);
                 }
                 */
{bool}  {if (yytext[0] == 't') seal_yylval.boolean = true;
          else seal_yylval.boolean = false;
         return(CONST_BOOL);}
0|[1-9][0-9]* {seal_yylval.symbol = inttable.add_string(yytext); 
        return(CONST_INT);
       }
0[x|X]([0-9]|[a-fA-F])+ { int i = 2, decimal = 0;     //先考虑16进制正数匹配
                   while (yytext[i]!= '\0'){
                     switch(yytext[i])
                     {
                       case '0': decimal = decimal*16 +0;break;
                       case '1': decimal = decimal*16 +1;break;
                       case '2': decimal = decimal*16 +2;break;
                       case '3': decimal = decimal*16 +3;break;
                       case '4': decimal = decimal*16 +4;break;
                       case '5': decimal = decimal*16 +5;break;
                       case '6': decimal = decimal*16 +6;break;
                       case '7': decimal = decimal*16 +7;break;
                       case '8': decimal = decimal*16 +8;break;
                       case '9': decimal = decimal*16 +9;break;
                       case 'a': decimal = decimal*16 +10;break;
                       case 'b': decimal = decimal*16 +11;break;
                       case 'c': decimal = decimal*16 +12;break;
                       case 'd': decimal = decimal*16 +13;break;
                       case 'e': decimal = decimal*16 +14;break;
                       case 'f': decimal = decimal*16 +15;break;
                       default:  break;
                     }
                     i++;
                   }
                   std::string result = std::to_string(decimal);
                   char *p =(char*) result.data();
                   seal_yylval.symbol = inttable.add_string(p); 
                   return(CONST_INT);
                          }

(([1-9][0-9]*)|0)\.[0-9]+ {seal_yylval.symbol = floattable.add_string(yytext); 
                              return(CONST_FLOAT);}//合法的浮点数匹配
                             

[a-zA-Z][0-9A-Za-z_]* {if (yytext[0] >= 65 && yytext[0]<= 90){
                          char* error = "Initial letter could not be capital.";
                          strcpy(seal_yylval.error_msg, error);
                          return(ERROR);//检测首字母大写错误
                          }
                       else
                          seal_yylval.symbol = idtable.add_string(yytext); 
                          return (OBJECTID);}//匹配变量需要放在保留字之后

.   {
  	strcpy(seal_yylval.error_msg, yytext); 
  	return (ERROR); 
       }
%%
/*
*此函数用来处理匹配到的""括起来的包含转义字符的字符串，输出处理过的string
*具有以下要求
*对于其中包含的"\\"，保存的时候保存\\但是打印的时候只打印"\\"而不是"\\\\"
*对于其中包含的
都保留其原始的值，即输出的时候不输出"\\n",而是"\n".
\a响铃(BEL)007
\b退格(BS) ，将当前位置移到前一列008
\f换页(FF)，将当前位置移到下页开头012
\n换行(LF) ，将当前位置移到下一行开头010
\r回车(CR) ，将当前位置移到本行开头013
\t水平制表(HT) （跳到下一个TAB位置）009
\v垂直制表(VT)    011
\\代表一个反斜线字符''\'092
\'代表一个单引号（撇号）字符039
\"代表一个双引号字符034
\?代表一个问号063
\0空字符(NUL)000
*/
std::string examination_of_string(char * yytext, int yyleng)
  { int i=0,j=0;
    char * fliter ;
    fliter = new char[yyleng+5];//存储处理结果,+5 防止溢出
      for(i=0;i < yyleng-1; i++){
          if(yytext[i] == '\\')
            {switch(yytext[i+1]){
                case 'a': fliter[j++] = 7;break;
                case 'b': fliter[j++] = 8;break;
                case 'f': fliter[j++] = 12;break;
                case 'n': fliter[j++] = 10;break;
                case 'r': fliter[j++] = 13;break;
                case 't': fliter[j++] = 9;break;
                case 'v': fliter[j++] = 11;break;
                case '\\': fliter[j++] = 92;break;
                case '\'': fliter[j++] = 39;break;
                case '\"': fliter[j++] = 34;break;
                case '?': fliter[j++] = 63;break;
                case '0': fliter[j++] = 0;break;
                case '\n':fliter[j++] = '\n';curr_lineno ++;break;
                default :break;
            }
            i++;
            }
          else fliter[j++] = yytext[i];
        }
      //if (yytext[i] == '\\') { char* error = "string should not end with \\";
      //          strcpy(seal_yylval.error_msg, error);
      //          return(ERROR);}
      {fliter[j++] = yytext[i];fliter[j++] = '\0';}
      std::string result = fliter;
      delete[] fliter;
      return result;
      
    }