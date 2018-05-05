# Cache System

Prototyping a cache system for the HTML Pages Builder.


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Introduction](#introduction)
- [Fingerprinting](#fingerprinting)
    - [PB Cipher Lib](#pb-cipher-lib)
    - [ALogrithms Comparison](#alogrithms-comparison)
- [Reference Links](#reference-links)
    - [Wikipedia](#wikipedia)
    - [PureBasic Documentation](#purebasic-documentation)

<!-- /MarkdownTOC -->

-----

# Introduction

Because of the numerous integrity checks that Pages Builder has to carry out, and due to the large (and growing) number of resource files hosted in the [PureBasic CodeArchiv Rebirth] project, a cache system seems inevitable to optimize checks and build operations down to a reasonable execution time. Also, the various checks and preparatory stages for building the HTML website introduce redundant file access operations which could benefit greatly from caching and memoization.

Having not worked with cache systems before, I'll be collecting here links to external resources on the topic as well as notes of interest.

# Fingerprinting

> Fingerprint functions may be seen as high-performance hash functions used to uniquely identify substantial blocks of data where cryptographic hash functions may be unnecessary. [\[Wikipedia\]][WP Fingerprint]

## PB Cipher Lib

PureBasic's [Cipher library] offers various commands to handle fingerprint with a variety of algorithms:

|    Plugin const    | algorithm |        bitness        |
|--------------------|-----------|-----------------------|
| `#PB_Cipher_CRC32` | CRC32     |                       |
| `#PB_Cipher_MD5`   | MD5       |                       |
| `#PB_Cipher_SHA1`  | SHA1      |                       |
| `#PB_Cipher_SHA2`  | SHA2      | 224, 256, 384 or 512. |
| `#PB_Cipher_SHA3`  | SHA3      | 224, 256, 384 or 512. |

The above table reflects the order of the algorithms performance and security, the faster and less secure ones begin toward the top, the more expensive and secure one toward the bottom.

CRC32 is not intended as a hash function but for cyclic redundancy checks, so we might leave that out when it comes to hashing files for changes. All the others should be fine to detect files changes. Since security is not an issue here (and caches are locally stored), even MD5 could be a good choice.

Possibly, some other techniques might be employed to further speed up the checks.

__PB Docs Refrences__:

- [Cipher library]
    - [`Fingerprint()`][Fingerprint()]
    - [`FileFingerprint()`][FileFingerprint()]
    - [`StringFingerprint()`][StringFingerprint()]

## ALogrithms Comparison

See also:

- [Evaluation of CRC32 for Hash Tables] — explains why CRC32 shouldn't be used for hash tables.
- [A Painless Guide to CRC Error Detection Algorithms]
- [CRCs vs Hash Functions]




# Reference Links

## Wikipedia

- [Cache (computing)][WP Cache]
- [Page Cache][WP Page Cache]
- [Disk Buffer][WP Disk Buffer] — embedded memory in a hard disk drive
- [Memoization][WP Memoization]
    - [Lookup table][WP Lookup table]
- [Checksum][WP Checksum]
- [Fingerprint][WP Fingerprint]
- [Rabin's fingerprinting algorithm][WP Rabin's fingerprinting algorithm]
- [Hash Function][WP Hash Function]
    - [SHA-1][WP SHA-1]

## PureBasic Documentation

- [PureBasic Documentation][PB Docs]
    - [Cipher library]
        + [`Fingerprint()`][Fingerprint()]
        + [`FileFingerprint()`][FileFingerprint()]
        + [`StringFingerprint()`][StringFingerprint()]


<!-- REFERENCE LINKS -->


[PureBasic CodeArchiv Rebirth]: https://github.com/SicroAtGit/PureBasic-CodeArchive-Rebirth

<!-- WIKIPEDIA -->

[WP Cache]: https://en.wikipedia.org/wiki/Cache_(computing)
[WP Page Cache]: https://en.wikipedia.org/wiki/Page_cache
[WP Disk Buffer]: https://en.wikipedia.org/wiki/Disk_buffer
[WP Memoization]: https://en.wikipedia.org/wiki/Memoization
[WP Lookup table]: https://en.wikipedia.org/wiki/Lookup_table
[WP Hash Function]: https://en.wikipedia.org/wiki/Hash_function
[WP SHA-1]: https://en.wikipedia.org/wiki/SHA-1
[WP Checksum]: https://en.wikipedia.org/wiki/Checksum
[WP Fingerprint]: https://en.wikipedia.org/wiki/Fingerprint_(computing)
[WP Rabin's fingerprinting algorithm]: https://en.wikipedia.org/wiki/Rabin_fingerprint

<!-- PureBasic Documentation -->

[PB Docs]: http://www.purebasic.com/documentation/index.html
[Cipher library]: http://www.purebasic.com/documentation/cipher/index.html
[FileFingerprint()]: http://www.purebasic.com/documentation/cipher/filefingerprint.html
[Fingerprint()]: http://www.purebasic.com/documentation/cipher/fingerprint.html
[StringFingerprint()]: http://www.purebasic.com/documentation/cipher/stringfingerprint.html

<!-- ARTICLES, POSTS, TUTORIALS -->

[Evaluation of CRC32 for Hash Tables]: https://web.archive.org/web/20120722074858/http://bretm.home.comcast.net/~bretm/hash/8.html
[A Painless Guide to CRC Error Detection Algorithms]: http://www.ross.net/crc/crcpaper.html
[CRCs vs Hash Functions]: https://eklitzke.org/crcs-vs-hash-functions