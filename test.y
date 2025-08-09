%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
int yyerror(char *s);

typedef struct Symbol {
    char* name;
    int intValue;
    char* strValue;
    int type; // 0=int, 1=char, 2=string
} Symbol;

#define MAX_SYMBOLS 100
Symbol symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

int findSymbolIndex(char* name);
void addSymbol(char* name, int intVal, char* strVal, int type);
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

%token MYTYPE SHOW SWAP
%token <str> IDENTIFIER STRING_LITERAL CHAR_LITERAL
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
    | SHOW '(' IDENTIFIER ')' ';'   {
        int idx = findSymbolIndex($3);
        if (idx != -1) {
            if (symbolTable[idx].type == 0)
                printf("%s = %d\n", $3, symbolTable[idx].intValue);
            else
                printf("%s = %s\n", $3, symbolTable[idx].strValue);
        } else {
            printf("Variable %s not declared\n", $3);
        }
    }
    | SWAP '(' IDENTIFIER ',' IDENTIFIER ')' ';' {
        int idx1 = findSymbolIndex($3);
        int idx2 = findSymbolIndex($5);
        if (idx1 == -1 || idx2 == -1) {
            printf("Swap error: variable not declared.\n");
        } else if (symbolTable[idx1].type != symbolTable[idx2].type) {
            printf("Swap error: type mismatch.\n");
        } else {
            if (symbolTable[idx1].type == 0) {
                int temp = symbolTable[idx1].intValue;
                symbolTable[idx1].intValue = symbolTable[idx2].intValue;
                symbolTable[idx2].intValue = temp;
            } else {
                char* temp = symbolTable[idx1].strValue;
                symbolTable[idx1].strValue = symbolTable[idx2].strValue;
                symbolTable[idx2].strValue = temp;
            }
            printf("Swapped %s and %s\n", $3, $5);
        }
    }
    | IDENTIFIER '=' expression ';' { addSymbol($1, $3, NULL, 0); printf("Assigned %d to variable %s\n", $3, $1); }
    | IDENTIFIER '=' STRING_LITERAL ';' { addSymbol($1, 0, $3, 2); printf("Assigned string %s to variable %s\n", $3, $1); }
    | IDENTIFIER '=' CHAR_LITERAL ';' { addSymbol($1, 0, $3, 1); printf("Assigned char %s to variable %s\n", $3, $1); }
    | expression ';'                { printf("Expression result: %d\n", $1); }
    ;

declaration_list:
    IDENTIFIER                              { addSymbol($1, 0, NULL, 0); printf("Declared %s as int with default 0\n", $1); }
    | IDENTIFIER '=' expression             { addSymbol($1, $3, NULL, 0); printf("Declared %s with value %d\n", $1, $3); }
    | IDENTIFIER '=' STRING_LITERAL         { addSymbol($1, 0, $3, 2); printf("Declared %s with string %s\n", $1, $3); }
    | IDENTIFIER '=' CHAR_LITERAL           { addSymbol($1, 0, $3, 1); printf("Declared %s with char %s\n", $1, $3); }
    | declaration_list ',' IDENTIFIER       { addSymbol($3, 0, NULL, 0); printf("Declared %s as int with default 0\n", $3); }
    | declaration_list ',' IDENTIFIER '=' expression { addSymbol($3, $5, NULL, 0); printf("Declared %s with value %d\n", $3, $5); }
    | declaration_list ',' IDENTIFIER '=' STRING_LITERAL { addSymbol($3, 0, $5, 2); printf("Declared %s with string %s\n", $3, $5); }
    | declaration_list ',' IDENTIFIER '=' CHAR_LITERAL { addSymbol($3, 0, $5, 1); printf("Declared %s with char %s\n", $3, $5); }
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
    | IDENTIFIER                     {
        int idx = findSymbolIndex($1);
        if (idx == -1) {
            printf("Error: variable %s not declared\n", $1);
            $$ = 0;
        } else if(symbolTable[idx].type != 0) {
            printf("Error: variable %s is not an int\n", $1);
            $$ = 0;
        } else {
            $$ = symbolTable[idx].intValue;
        }
    }
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

void addSymbol(char* name, int intVal, char* strVal, int type) {
    int idx = findSymbolIndex(name);
    if (idx == -1) {
        if (symbolCount < MAX_SYMBOLS) {
            symbolTable[symbolCount].name = strdup(name);
            symbolTable[symbolCount].intValue = intVal;
            symbolTable[symbolCount].strValue = strVal ? strdup(strVal) : NULL;
            symbolTable[symbolCount].type = type;
            symbolCount++;
        } else {
            printf("Symbol table full!\n");
        }
    } else {
        symbolTable[idx].intValue = intVal;
        if(symbolTable[idx].strValue) free(symbolTable[idx].strValue);
        symbolTable[idx].strValue = strVal ? strdup(strVal) : NULL;
        symbolTable[idx].type = type;
    }
}

int getSymbolValue(char* name) {
    int idx = findSymbolIndex(name);
    if (idx != -1) {
        return symbolTable[idx].intValue;
    } else {
        printf("Error: Symbol %s not found!\n", name);
        return 0;
    }
}
