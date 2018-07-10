# Cache System

Prototyping a cache system for the HTML Pages Builder.


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Introduction](#introduction)
    - [Caching Challenges](#caching-challenges)
    - [What Needs to Be Cached?](#what-needs-to-be-cached)
    - [Caching Resources Data](#caching-resources-data)
    - [Avoiding Redundant File Accesses](#avoiding-redundant-file-accesses)
- [Fingerprinting](#fingerprinting)
    - [PB Cipher Lib](#pb-cipher-lib)
    - [Alogrithms Comparison](#alogrithms-comparison)
- [Tracking Files/Folder Changes](#tracking-filesfolder-changes)
    - [PureBasic Commands](#purebasic-commands)
        - [File Changes](#file-changes)
        - [Time-Stamping](#time-stamping)
    - [Monitoring File Changes Under Windows](#monitoring-file-changes-under-windows)
    - [File Monitoring Libs](#file-monitoring-libs)
        - [fswatch](#fswatch)
    - [The Windows archive bit](#the-windows-archive-bit)
- [PB Tests TODOs List](#pb-tests-todos-list)
    - [Files Finger Printing](#files-finger-printing)
    - [DirectoryEntryDate\(\)](#directoryentrydate)
- [Reference Links](#reference-links)
    - [Wikipedia](#wikipedia)
    - [PureBasic Documentation](#purebasic-documentation)

<!-- /MarkdownTOC -->

-----

# Introduction

Because of the numerous integrity checks that Pages Builder has to carry out, and due to the large (and growing) number of resource files hosted in the [PureBasic CodeArchiv Rebirth] project, a cache system seems inevitable to optimize checks and build operations down to a reasonable execution time. Also, the various checks and preparatory stages for building the HTML website introduce redundant file access operations which could benefit greatly from caching and memoization.

Having not worked with cache systems before, I'll be collecting here links to external resources on the topic as well as notes of interest.

## Caching Challenges

The need to introduce a cache system has brought in a series of new challenges which (alongside the problems introduced with modularization of code) have considerably slowed down the development of this project — whereas the standalone __HTMLPagesCreator__ app was almost production ready, the new system of independent modules shared by different tools has added a lot of complexity to the code, and the need to abstract into modules functions which were previously implement in a linear fashion. When working on modular code, PureBasic's intrinsic limitations as a language start to show up, and the code gets really verbose. 

The main problem with the caching system is that it's going to affect the development of the resources modules from its onset — so much so that it might not be worthy writing the res module without the caching system in place, for the risk would be to have to rewrite the whole thing from scratch.

## What Needs to Be Cached?

So far, there are only two aspects of the project which are worth caching, and they both pertain to resources:

- resources' header metadata (key-vals)
- resources' HTML cards

The latter depends on the former (ie, if the former has changed the latter should be rebuilt too). So, for the moment we'll only focus on the former.

## Caching Resources Data

For the purpose of manipulating resources metadata, all the app needs is access to the list of key-value pairs (string) which results from parsing the header comments. 

Since this metadata is simply a structured List where each entry holds two strings (key and val), caching the data is easily achieved by iterating through the list and saving every string in the pair to file via `WriteStringN()`. Retriving the cached metadata is just a matter of reading the file one line at the time via `ReadString()` and populating the List until there is data. For an example implementation, see:

- [`cache-write-metadata.pb`](./cache-write-metadata.pb)
- [`cache-read-metadata.pb`](./cache-read-metadata.pb)
- [`cached`](./cached) (the cached data)


The cache should save the List in into a file whose name is the MD5 checksum of the resource file. This way, the cache system will only need to fingerprint a resource file and look for the presence of a corresponding file named with MD5 hash of the resource:

- if a file named as the MD5 has of the resource it means that the resource had passed all tests and was cahced; 
- if not, it means that either:
    + the last time the resource was validated it failed some tests
    + the resource file was changed since its last chaching

This approach is simple, and it allows to retrive the cached binary metadata of the resource and skip all validation and processing steps when cached data is available, otherwise the usual processing steps will need to be carried out.



## Avoiding Redundant File Accesses

Resource files might be accessed more than once by some tools:

- Resource integrity checks:
    + header comments are extracted, parsed and validated
    + the whole file (if a PB source) is parsed to check for:
        * correct enconding
        * presence of compiler options
        * presence of `CompilerIf #PB_Compiler_IsMainFile` block (PB inc files only)
- HTML page creation:
    + header comments are extracted, parsed and validated
    + HTML card is generated from extracted key-vals

It's clear from the above list that without a cache system there could be a huge overhead of multiple file accesses, parsing and computations. Every procedure used to carry out any of the above passages should try to retrive cached data if available, and all checks should be reported as having passed if a cached file is present for the resource.

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

## Alogrithms Comparison

See also:

- [Evaluation of CRC32 for Hash Tables] — explains why CRC32 shouldn't be used for hash tables.
- [A Painless Guide to CRC Error Detection Algorithms]
- [CRCs vs Hash Functions]


# Tracking Files/Folder Changes

Because some tools will allow to carry out project scanning and HTML pages conversion in different steps, a system should be implemented to check if folders and files have been changed since the last project scan --- the project scanner functions and cache system could also benefit from this by allow further scans of the project/cache to avoid redundant operations.

I must tread carefully with this feature, as different OSs might handle this feature differently. So, great care must be taken to make sure that tracking changes works on all supported OSs, especially if resorting to OS native functionality.

Most likely, the simplest approach is to just check that a single resource hans't changed before employing it — especially before critical operations that would rely on the cached data, but it might also affect tracking resources count and iterating them (eg, if a resource was deleted or renamed).

Ideally, events could be used to track if the categories folder has been changed, and trigget some background function to detect significant changes and update the cache and the current data in memory. This might require OS specific code branching, or an external library tool, so unless it's strictly needed I should avoid it (at least for now) — but for the sake of completeness, links to such libraries are provided below.

## PureBasic Commands

### File Changes

Some PB native commands that might help to track files/and folder changes:

- [`GetFileDate(Filename$, DateType)`][GetFileDate()]
- [`DirectoryEntryDate(#Directory, DateType)`][DirectoryEntryDate()]

... where `DateType` represents the kind of date to return:

- `#PB_Date_Created`: returns the file creation date.
- `#PB_Date_Accessed`: returns the last file access date.
- `#PB_Date_Modified`: returns the last file modification date.

The the requested date is in the format of the PureBasic [Date library].

> __REMARKS__ — On __Linux__ and __Mac OSX__, the date returned for `#PB_Date_Created` is the same as the date for `#PB_Date_Modified`, because most file systems do not store a file creation date.

(this isn't a problem, we're only interested in tracking when files where last modified)

The big question here — which requires some testing! — is how the different OSs behave regarding a folder's `#PB_Date_Modified` attribute:

- If a file inside that folder (or its subfolders) is changed, does the folder's `#PB_Date_Modified` attribute get updated?

This would be a good way to track just the main project's folder (instad of every resource file) to detect if any files where changed and, if it changed, then we'd need to check what files have changed and if they affect the cache system or project structure.

I vaguely remember having read that the three OSs behave differently in this respect (and that there were some limitations with Windows, but I might be wrong on this one), so this must verified before implementing. Unfortunately, macOS testing is always a problem with cross platform projects (for a lack of contributors who could test it for us).

### Time-Stamping

PureBasic doesn't seem to have dedicated time-stamp commands, but these can easily be achieved via the [Date library] and the [`FormatDate()`][FormatDate()] command:

```
Text$ = FormatDate(Mask$, Date)

Mask$   The mask used to format the date. The following tokens in the mask 
        string will be replaced according to the given date: 

            %yyyy : Will be replaced by the year value, on 4 digits.
            %yy   : Will be replaced by the year value, on 2 digits.
            %mm   : Will be replaced by the month value, on 2 digits.
            %dd   : Will be replaced by the day value, on 2 digits.
            %hh   : Will be replaced by the hour value, on 2 digits.
            %ii   : Will be replaced by the minute value, on 2 digits.
            %ss   : Will be replaced by the second value, on 2 digits.

Date    The date value to use.  
```



## Monitoring File Changes Under Windows

- [MS Docs » Obtaining Directory Change Notifications]


## File Monitoring Libs

Here are some links to cross-platform libraries to track file changes. Their documentation provides useful insights into cross-platform differences and specific OS limitations.

### fswatch

- [fswatch website] | [repo][fswatch repo] | [docs][fswatch docs] | [wiki][fswatch wiki]


#### Useful Quotations

The [fswatch docs] contain some useful information:

> ### [5.6 The Windows monitor](http://emcrisostomo.github.io/fswatch/doc/1.12.0/fswatch.html/Monitors.html#The-Windows-monitor-1)
> 
> The Windows monitor uses the Windows’ `ReadDirectoryChangesW` function for each watched path and asynchronously waits for change events using overlapped I/O. The Windows monitor is the default choice on Windows because it is the best performing monitor on that platform and it is affected by virtually no limitations.

## The Windows archive bit

The Windows archive bit can be read/set via PB's [`DirectoryEntryAttributes()`][DirectoryEntryAttributes()], [`GetFileAttributes()`][GetFileAttributes()] and [`SetFileAttributes()`][SetFileAttributes()] commands.

It doesn't seem to be relevant to the topic at hand.

From [Wikipedia][WP Archive bit]:

> The archive bit is a file attribute used by Microsoft operating systems, OS/2, and AmigaOS. It is used to indicate whether or not the file has been backed up (archived). [...] when a file is created or modified, the archive bit is set (i.e. turned on), and when the file has been backed up, the archive bit is cleared (i.e. turned off). [...] The operating system never clears the archive bit unless explicitly told to do so by the user.
> 
> When a file with a clear archive bit is moved from one place on a file system to another, the archive bit reverts to being set.
> 
> As the archive bit is a file attribute and not part of the file itself; the contents of the file remain unchanged when the status of the archive bit changes.

See:

- [Wikipedia » Archive bit][WP Archive bit]
- [The Windows archive bit is evil and must be stopped]

-------------------------------------------------------

# PB Tests TODOs List

## Files Finger Printing

Some tests need to be carried out for fingerprinting files with PB using MD5. 

## DirectoryEntryDate()

The following tests must be carried out for the [`DirectoryEntryDate(#Directory, #PB_Date_Modified)`][DirectoryEntryDate()] command:

- [ ] Check that if a file inside that folder (or its subfolders) is changed the folder's `#PB_Date_Modified` attribute is changed too in:
    + [ ] Windows
    + [ ] Linux
    + [ ] macOS

If not, it means that all the critical project files need to be tracked individually (or a custom procedure has to be written, leveraging each OS API).



-------------------------------------------------------

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
    - [FileSystem library]
        * [`DirectoryEntryAttributes()`][DirectoryEntryAttributes()]
        * [`DirectoryEntryDate()`][DirectoryEntryDate()]
        * [`GetFileAttributes()`][GetFileAttributes()]
        * [`GetFileDate()`][GetFileDate()]
        * [`SetFileAttributes()`][SetFileAttributes()]
    - [Date library]
        * [`FormatDate()`][FormatDate()]

<!-----------------------------------------------------------------------------
                               REFERENCE LINKS                                
------------------------------------------------------------------------------>

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
[WP Archive bit]: https://en.wikipedia.org/wiki/Archive_bit

<!-- PureBasic Documentation -->

[PB Docs]: http://www.purebasic.com/documentation/index.html
[Cipher library]: http://www.purebasic.com/documentation/cipher/index.html
[FileFingerprint()]: http://www.purebasic.com/documentation/cipher/filefingerprint.html
[Fingerprint()]: http://www.purebasic.com/documentation/cipher/fingerprint.html
[StringFingerprint()]: http://www.purebasic.com/documentation/cipher/stringfingerprint.html

[FileSystem library]: https://www.purebasic.com/documentation/filesystem/index.html
[DirectoryEntryAttributes()]: https://www.purebasic.com/documentation/filesystem/directoryentryattributes.html
[DirectoryEntryDate()]: https://www.purebasic.com/documentation/filesystem/directoryentrydate.html
[GetFileAttributes()]: https://www.purebasic.com/documentation/filesystem/getfileattributes.html
[GetFileDate()]: https://www.purebasic.com/documentation/filesystem/getfiledate.html
[SetFileAttributes()]: https://www.purebasic.com/documentation/filesystem/setfileattributes.html

[Date library]: https://www.purebasic.com/documentation/date/index.html
[FormatDate()]: https://www.purebasic.com/documentation/date/formatdate.html

<!-- ARTICLES, POSTS, TUTORIALS -->

[A Painless Guide to CRC Error Detection Algorithms]: http://www.ross.net/crc/crcpaper.html
[CRCs vs Hash Functions]: https://eklitzke.org/crcs-vs-hash-functions
[Evaluation of CRC32 for Hash Tables]: https://web.archive.org/web/20120722074858/http://bretm.home.comcast.net/~bretm/hash/8.html
[The Windows archive bit is evil and must be stopped]: https://www.computerworld.com/article/2598081/data-center/the-windows-archive-bit-is-evil-and-must-be-stopped.html

<!-- MS/MSDN Articles -->

[MS Docs » Obtaining Directory Change Notifications]: https://docs.microsoft.com/en-us/windows/desktop/fileio/obtaining-directory-change-notifications


<!-- FILE CHANGE WATCH LIBS -->

[fswatch website]: http://emcrisostomo.github.io/fswatch/ "Visit fswatch website"
[fswatch repo]: https://github.com/emcrisostomo/fswatch "Visit fswatch repository"
[fswatch docs]: http://emcrisostomo.github.io/fswatch/doc/1.12.0/fswatch.html/ "Read fswatch documentation"
[fswatch wiki]: https://github.com/emcrisostomo/fswatch/wiki "Visit fswatch's Wiki"