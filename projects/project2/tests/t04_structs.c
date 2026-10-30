struct Empty {};
struct Node {
    int value;
    char label[8];
    struct Node *next;
};
struct Node;
struct Node head;
struct Node *tail;
struct Node nodes[3];
struct Wrapper { struct Node item; } wrapper;
