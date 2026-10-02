#include "subc.h"

/* Optional layout for separate chaining:
 *
 *     typedef struct Entry {
 *         Symbol symbol;
 *         struct Entry *next;
 *     } Entry;
 *
 *     enum { BUCKET_COUNT = 101 };
 *     static Entry *buckets[BUCKET_COUNT];
 */

/* TODO: implement your own hash function, buckets, collision handling,
 * entry lookup/insertion, owned name storage, and cleanup.
 * Any correct hash-table design is allowed. Do not use a library hash map.
 * See subc.h for the interface contract.
 */

typedef struct Entry {
    Symbol *symbol;
    struct Entry *next;
} Entry;

enum { BUCKET_COUNT = 101 };
static Entry *buckets[BUCKET_COUNT];

Symbol *enter(TokenKind kind, const char *name, size_t length)
{

    int h = 0;
    for (size_t i = 0; i<length; i++) {
        h = h*3 + name[i];
    }
    h %= BUCKET_COUNT;

    Entry *current = buckets[h];
    while(current != NULL) {
        Symbol *sym = current->symbol;
        if(strcmp(name, sym->name)==0) {
            return sym;
        }
        current = current->next;
    }

    Entry *new_entry = (Entry *)malloc(sizeof(Entry));
    Symbol *new_symbol = (Symbol *)malloc(sizeof(Symbol));
    new_symbol->name = (char *)malloc(length + 1);
    strcpy(new_symbol->name, name);
    new_symbol->count = 0;
    new_symbol->kind = kind;
    new_entry->symbol = new_symbol;
    new_entry->next = buckets[h];
    buckets[h] = new_entry;

    return new_symbol; /* Deliberate incomplete-implementation signal. */
}

void symbols_destroy(void)
{
    /* TODO: free all table-owned memory and reset the table to empty. */
    for (int i=0;i<BUCKET_COUNT;i++) {
        Entry *current = buckets[i];
        while(current != NULL) {
            if (current->symbol != NULL) {
                free(current->symbol->name);
            }
            free(current->symbol);
            Entry *next_entry = current->next;
            free(current);
            current = next_entry;
        }

        buckets[i] = NULL;
    }
}
