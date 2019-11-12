# thc-btc-rng-bruteforce

A tool to determine if anyone ever used the Bitcoin client software to receive a Bitcoin payment on a system that uses the [CVE-2008-0166](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2008-0166) broken Random Number Generator. (The tool generates all possible combinations of bitcoin addresses using the broken RNG).

**Answer:** We did not find any. Thought, it was a lot of fun searching...

The broken version of OpenSSL was being seeded only by the process ID. Due to differences between endianness and sizeof(long), the output was architecture-specific: little-endian 32bit (e.g. i386), little-endian 64bit (e.g. amd64, ia64), big-endian 32bit (e.g. powerpc, sparc). PID 0 is the kernel and PID_MAX (32768) is not reached when wrapping, so there were 32767 possible random number streams per architecture.

Perhaps this research motivates somebody to check against other broken RNG's...

**Background:**
The Bitcoin client uses the OpenSSL library. In particular it uses the 'EC_KEY_generate_key()' function to generate bitcoin addresses (e.g. key) for receiving payments.

Older versions of the Bitcoin client generate and store 100 keys in wallet.dat. A new key is only generated whenever a Bitcoin payment is received. Thus the client keeps a pool of 100 unused Bitcoin keys (addresses).

The state of the internal Random Number Generator depends on what other calls were made to the OpenSSL Library before the call to 'EC_KEY_generate_key()'. The calls that affect the internal RNG state are "RAND_add(8)", "RAND_bytes(8)" and "RAND_bytes(32)". 

The research was thus to review *a lot of old* Bitcoin source to find out what calls were made that affected the internal RNG state before calling 'EC_KEY_generate_key()'. The call path changes between Bitcoin versions and there is a different call path if the GUI or text interface of the Bitcoin client is used.

The research focused on these version of the Bitcoin client:

| Release date | Version |
|--------------|---------|
|2009-DEC-14| v0.2.0| 
|2010-AUG-04| v0.3.8|
|2011-JUL-08| v0.3.24|
|2011-DEC-14| v0.5.1|
|2012-JUN-25| v0.6.3|
|2013-DEC-09| v0.8.6|
|2014-JUN-01| v0.9.1|
|2015-JAN-12| v0.9.4|
|2015-APR-09| v0.10.0|

The format of the Bitcoin addresses changed over time. First "Public Key Hash" (Pay2PKH) was used. Then "Compressed Public Key Hash" (Pay2CPKH) and finally "Compressed Script Hash" (Pay2CSH).

The task thus was to generate the Bitcoin keys for each bitcoin version, for each architecture (le32/le64), for each Process ID and for each of the 3 address variants (PKH, CPKH and CSH)...using the broken Random Number Generator.

This tool does all this.

**Setup / Compiling**

Make OpenSSL Vulnerable again
```
$ wget https://ftp.openssl.org/source/old/0.9.x/openssl-0.9.8c.tar.gz
$ tar xfz openssl-0.9.8c.tar.gz
$ mv openssl-0.9.8c openssl-0.9.8c-vuln
$ cd openssl-0.9.8c-vuln
$ patch -p1 <../make-OpenSSL-0-9-8c-vulnerable-again.diff
```

On a LE-32 system use:
```
$ ./Configure linux-generic32 shared no-ssl2 no-ssl3 no-comp no-asm
$ make depend all
```

On a LE-64 system use:
```
$ ./Configure linux-x86_64 shared no-ssl2 no-ssl3 no-comp no-asm
$ make depend all
```

Compile
```
$ gcc -o thc-btc-rng-bf thc-btc-rng-bruteforce.c -I./openssl-0.9.8c-vuln/include -L./openssl-0.9.8c-vuln -lssl -lcrypto
```

Run (also try -h and -l):
```
$ LD_LIBRARY_PATH=./openssl-0.9.8c-vuln/ ./thc-btc-rng-bf -v 0
```

The output will look something like this:
```
Stats: Version 0.3.24, Arch le32, keys 10, Pid 0-32768
A UPKH: 1f9zW98RUdaNUvpQCiFeWRz6Ns5GGTsyh
A CPKH: 1NCbVqf4fqPYNrbLEybUqukA71WXTgFPd8
A -CSH: 34S6vMKpjcuPmQT3D1o55bKq7z2agg7Qpe
A UPKH: 1HeXLUdkuC7pbwfuu7XRrhP5gVvzxGsoPL
A CPKH: 16uQGb6aEfxR4swV9ze6C4p5AGdFsAqZnQ
A -CSH: 34kA1xsgTwu5uSBm1GzSCcVEsCDjKegUrY
A UPKH: 16RdRFMHPdnbui54wm4Z9nVDMa3tnBpYG8
A CPKH: 11tSPNTXC8mkCWZaEYfqv5yhhefwXvxfv
[...]
```


**Checking**

We leave it as an exercise to the user to check wether the vulnerable addresses were recorded in the Bitcoin blockchain. We use [bitcore](https://github.com/bitpay/bitcore) and ran a full node and a dirty curl script for checking:

```
curl http://127.0.0.1:3000/api/BTC/mainnet/address/$addr
curl http://127.0.0.1:3000/api/BTC/mainnet/address/$addr/balance
```

