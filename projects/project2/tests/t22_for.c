int main() {
    int i;
    for (i = 0; i < 10; i++) sum = sum + i;
    for (i = 0; i != 10; ++i) {
        if (i == 3) continue;
        if (i == 8) break;
    }
}
