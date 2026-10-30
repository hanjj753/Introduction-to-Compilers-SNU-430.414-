#include "subc.h"

/* Reuse your completed Project 1 hash.c, or complete this skeleton.
 * TODO: implement your own hash function, buckets, collision handling,
 * entry lookup/insertion, owned name storage, and cleanup.
 * Any correct hash-table design is allowed. Do not use a library hash map.
 * See subc.h for the interface contract.
 */

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

Symbol *enter(TokenKind kind, const char *name, size_t length)
{
    (void)kind;
    (void)name;
    (void)length;
    return NULL; /* Deliberate incomplete-implementation signal. */
}

void symbols_destroy(void)
{
    /* TODO: free all table-owned memory and reset the table to empty. */
}
