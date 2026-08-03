%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror (char *s);

/* AST Node */
typedef struct Node {
    char op;
    int value;
    char varname [32];
    struct Node *left;  /* must write 'struct Node' not just Node */
    struct Node *right; /* because typedef is not yet complete here */
} Node;

int temp_count = 0;

char *newTemp() {
    char *b = malloc (16);
    sprintf(b, "t%d", ++temp_count);
    return b;
}

Node *makeNode (char op, Node *L, Node *R) {
    Node *n = malloc(sizeof (Node));
    n->op = op; n->value = 0; n->varname [0] = '\0';
    n->left = L; n->right = R; return n;
}

Node *makeLeaf (int v){
    Node *n = malloc(sizeof (Node));
    n->op = '\0'; n->value = v; n->varname [0] = '\0';
    n->left = NULL; n->right = NULL; return n;
}

Node *makeVar (char *name) {
    Node *n = malloc(sizeof (Node));
    n->op = 'V'; n->value = 0;
    strncpy(n->varname, name, 31); n->varname [31] = '\0';
    n->left = NULL; n->right = NULL; return n;
}

/* OPTIMIZATION 1: Constant Folding */
Node *foldConstants (Node *n) {
    if (!n || n->op == '\0' || n->op == 'V') return n;
    
    n->left = foldConstants (n->left);
    n->right = foldConstants (n->right);
    
    if (n->left && n->left->op == '\0' && n->right && n->right->op == '\0') {
        int l = n->left->value, r = n->right->value, res = 0;
        
        if (n->op == '+') res = l + r;
        if (n->op == '-') res = l - r;
        if (n->op == '*') res = l * r;
        if (n->op == '/') {
            if (r == 0) { printf("; Warning: div by zero\n"); return n; }
            res = l / r;
        }
        
        printf("; Folded: %d %c %d = %d\n", l, n->op, r, res);
        free (n->left); free(n->right);
        n->op = '\0'; n->value = res;
        n->left = NULL; n->right = NULL;
    }
    return n;
}

/* OPTIMIZATION 2: Dead Code Detection */
#define MAX_VARS 64
typedef struct { char name [32]; int uses; } VarUse;
VarUse useTable [MAX_VARS];
int useCount = 0;

void markUse (char *name) {
    for (int i=0; i < useCount; i++)
        if (strcmp(useTable [i].name, name) == 0) { useTable [i].uses++; return; }
    
    strcpy(useTable [useCount].name, name);
    useTable [useCount++].uses = 1;
}

int getUses (char *name) {
    for (int i=0; i < useCount; i++)
        if (strcmp(useTable [i].name, name) == 0) return useTable [i].uses;
    return 0;
}

void markAllUses (Node *n) {
    if (!n) return;
    if (n->op == 'V') markUse (n->varname);
    markAllUses (n->left); markAllUses (n->right);
}

/* TAC Generator */
char *genTAC (Node *n) {
    if (!n) return strdup("0");
    if (n->op == '\0') { char *b = malloc (16); sprintf(b, "%d",n->value); return b; }
    if (n->op == 'V') return strdup (n->varname);
    
    char *L = genTAC (n->left), *R = genTAC (n->right), *t = newTemp();
    printf("%s = %s %c %s\n", t, L, n->op, R);
    free (L); free(R); return t;
}

void freeTree (Node *n) {
    if (!n) return;
    freeTree (n->left); freeTree (n->right); free(n);
}
%}

%union {
    int ival;
    char *sval;
    struct Node *nptr; /* must use 'struct Node' here too */
}

%token <ival> NUMBER
%token <sval> IDENTIFIER
%type <nptr> expr

%left '+' '-'
%left '*' '/'

%%
program: /* empty */ | program stmt;

stmt:
    IDENTIFIER '=' expr '\n' {
        markAllUses($3);
        Node *opt = foldConstants($3);
        if (getUses ($1) == 0)
            printf("; Dead: '%s' assigned but never used\n", $1);
        char *r = genTAC (opt);
        printf("%s = %s\n\n", $1, r);
        free(r); freeTree (opt); free($1);
    }
    | expr '\n' {
        markAllUses($1);
        Node *opt = foldConstants($1);
        char *r = genTAC (opt);
        printf("result = %s\n\n", r);
        free(r); freeTree (opt);
    }
    | '\n' {}
    ;

expr:
      expr '+' expr { $$ = makeNode('+', $1, $3); }
    | expr '-' expr { $$ = makeNode('-', $1, $3); }
    | expr '*' expr { $$ = makeNode('*', $1, $3); }
    | expr '/' expr { $$ = makeNode('/', $1, $3); }
    | NUMBER        { $$ = makeLeaf ($1); }
    | IDENTIFIER    { $$ = makeVar ($1); free($1); }
    ;
%%

int main() {
    printf("=== Mini Compiler (Optimizer + TAC) ===\n\n");
    yyparse();
    return 0;
}

void yyerror (char *s) { fprintf(stderr, "Syntax Error: %s\n", s); }