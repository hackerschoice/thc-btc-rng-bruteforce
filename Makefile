

all: thc-btc-rng-bruteforce.c
	gcc -o thc-btc-rng-bt thc-btc-rng-bruteforce.c -I./openssl-0.9.8c-vuln/include -L./openssl-0.9.8c-vuln -lssl -lcrypto

