%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
int yyerror(char *s);

typedef struct Symbol {
    char* name;
    int value;
} Symbol;

#define MAX_SYMBOLS 100
Symbol symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

int findSymbolIndex(char* name);
void addSymbol(char* name, int value);
int getSymbolValue(char* name);
%}

%union {
    char* str;
    int num;
}

%left OR
%left AND
%right NOT
%left BOR
%left BXOR
%left BAND
%left LSHIFT RSHIFT
%left PLUS MINUS
%left TIMES DIVIDE
%right BNOT
%left UMINUS

%token MYTYPE SHOW
%token <str> IDENTIFIER
%token <num> NUMBER

%token PLUS MINUS TIMES DIVIDE
%token AND OR NOT
%token BAND BOR BXOR BNOT LSHIFT RSHIFT

%type <num> expression

%%

program:
    statements
    ;

statements:
    statements statement
    | statement
    ;

statement:
    MYTYPE declaration_list ';'     { printf("Declaration complete.\n"); }
    | SHOW '(' IDENTIFIER ')' ';'   { printf("Displaying value of %s: %d\n", $3, getSymbolValue($3)); }
    | IDENTIFIER '=' expression ';' { addSymbol($1, $3); printf("Assigned %d to variable %s\n", $3, $1); }
    | expression ';'                { printf("Expression result: %d\n", $1); }
    ;

declaration_list:
    IDENTIFIER                              { addSymbol($1, 0); printf("Declared %s with default 0\n", $1); }
    | IDENTIFIER '=' expression             { addSymbol($1, $3); printf("Declared %s with value %d\n", $1, $3); }
    | declaration_list ',' IDENTIFIER       { addSymbol($3, 0); printf("Declared %s with default 0\n", $3); }
    | declaration_list ',' IDENTIFIER '=' expression { addSymbol($3, $5); printf("Declared %s with value %d\n", $3, $5); }
    ;

expression:
    expression PLUS expression       { $$ = $1 + $3; }
    | expression MINUS expression    { $$ = $1 - $3; }
    | expression TIMES expression    { $$ = $1 * $3; }
    | expression DIVIDE expression   {
        if ($3 == 0) {
            yyerror("Division by zero");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
    | expression AND expression      { $$ = $1 && $3; }
    | expression OR expression       { $$ = $1 || $3; }
    | NOT expression                 { $$ = !$2; }

    | expression BAND expression     { $$ = $1 & $3; }
    | expression BOR expression      { $$ = $1 | $3; }
    | expression BXOR expression     { $$ = $1 ^ $3; }
    | BNOT expression                { $$ = ~$2; }
    | expression LSHIFT expression   { $$ = $1 << $3; }
    | expression RSHIFT expression   { $$ = $1 >> $3; }

    | NUMBER                         { $$ = $1; }
    | IDENTIFIER                     { $$ = getSymbolValue($1); }
    | '(' expression ')'             { $$ = $2; }
    ;

%%

int yyerror(char *s) {
    printf("Error: %s\n", s);
    return 0;
}

int main() {
    yyparse();
    return 0;
}

int findSymbolIndex(char* name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

void addSymbol(char* name, int value) {
    int index = findSymbolIndex(name);
    if (index == -1) {
        if (symbolCount < MAX_SYMBOLS) {
            symbolTable[symbolCount].name = strdup(name);
            symbolTable[symbolCount].value = value;
            symbolCount++;
        } else {
            printf("Symbol table full!\n");
        }
    } else {
        symbolTable[index].value = value;
    }
}

int getSymbolValue(char* name) {
    int index = findSymbolIndex(name);
    if (index != -1) {
        return symbolTable[index].value;
    } else {
        printf("Error: Symbol %s not found!\n", name);
        return 0;
    }
}
