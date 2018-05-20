# MODULARIZATION NOTES

Some notes on how to convert the current [`HTMLPagesCreator.pb`][HTMLPagesCreator] from a single sourcefile to a modules-based project so that some of its functionality can be shared by other tools of the CodeArchiv.


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Source Files](#source-files)
- [Modules Description](#modules-description)
    - [Global Module](#global-module)
    - [Error Tracker](#error-tracker)
- [Notes on Modules Usage](#notes-on-modules-usage)
    - [Global Enumerators](#global-enumerators)
- [Modules Roadmap](#modules-roadmap)
    - [Errors Management](#errors-management)
        - [Current Status](#current-status)
        - [Possible Changes](#possible-changes)
        - [Required Vars Access](#required-vars-access)
    - [Log Module](#log-module)
- [Problems Ahead](#problems-ahead)
    - [Issues With Resource Files](#issues-with-resource-files)

<!-- /MarkdownTOC -->

-----

# Source Files

- [`HTMLPagesCreator.pb`][HTMLPagesCreator]
- [`mod_G.pbi`][mod_G] — (`G::`) Global module for commonly shared data.
- [`mod_Errors.pbi`][mod_Errors] — (`Err::`) Error Tracking module.

# Modules Description

## Global Module

- [`mod_G.pbi`][mod_G]

This module (`G::`) holds data commonly shared by all tools.

- __Cross platform constants__ (`#EOL`, `#EOL_WRONG`, `#DSEP`, etc.)
- __[Global enumerators](#global-enumerators)__


## Error Tracker

[Error Tracker]: #error-tracker

- [`mod_Errors.pbi`][mod_Errors]
 
This module (`Err::`) tracks and handles all errors encountered during the processing stage of the project (validation, extraction, conversion, etc.). Every module that takes part in the Archiv processing should report errors to this module and let the module handle them.

- `Err::TrackError(ErrMessage.s)` — signal an error and carry on.
- `Err::Abort(ErrorMsg.s, ErrorType)` — signal a fatal error and request aborting processing the Archiv.

When requesting `Abort()`, the passed `ErrorType` should be one of the following

- `Err::#FATAL_ERR_GENERIC` (default if none specified)
- `Err::#FATAL_ERR_INTERNAL` — error due to App internals.
- `Err::#FATAL_ERR_FILE_ACCESS` — App can't get access to file resources.
- `Err::#FATAL_ERR_PANDOC` — any blocking error related to pandoc.

Before Aborting, the Error Tracker will ensure that any statistics gathered so far are printed in the final report, so that the user can be made aware of all problems encountred (and not just the last one, which halted processing).

_Some considerations..._

The error tracker is intended to gather statistics of any errors encountered during the actual processing of the project, in order to present a detailed report at the end. The way errors are stored should be independent of their final representation (ie: the app's GUI, the debug window, or a log file).

Also, I must keep in mind that the final app might implement a dry-run feature to actually test building the whole project without writing any changes to disk, only in order to check if any errors are encountered with pandoc or at other places. So the error tracker must be able to accomodate that too.

# Notes on Modules Usage

Since the whole purpose of splitting the app into modules, here are some important notes on how the modules should be used in custom tools for this project.

## Global Enumerators

Dynamic numbering of PB "objects" via `#PB_Any` works on a global scale, even when using modules; so, to avoid conflicts when creating RegExs, files, gadgets, etc., enumerations should be tracked globally by the G module.

For example, [`mod_G.pbi`][mod_G] defines in its public module interface:

```purebasic
Enumeration RegExsIDs
EndEnumeration
```

Where `RegExsIDs` is a common RegEx Enumeration Identifier to keep track of the RegExs ID across modules, otherwise Enums will start over from 0 and overwrite existing RegExs! Other modules' Enums will take on from there by using:

```purebasic
Enumeration G::RegExsIDs
```

This system allows working with enumerated "object" without conflicts, and to use constants instead of vars to refer to the various RegExs, files, gadgets, etc.

It also means that any third party tools willing to reuse some of the modules of this project will need to adhere to this enumeration scheme.

------------------------------

# Modules Roadmap

I still need to work out properly how to move all the current functionality into separate modules. Presently, the main challenges are posed by the Error Tracking system, the Debug logging and the Final Report: in order to move any part of the current code to independent modules, I must first address these three systems so that they don't break down.


## Errors Management

### Current Status

Currently the HTML Pages Creator has a dual approach to errors:

1. Check Project Integrity Step
2. Project processing errors managment

The two are independent from each other. The Project Integrity Step does some preliminary checks to verify if there are structural problems in the Archiv, but doesn't go as far as checking the integrity single resources. This is intended as a way to detect common problems before starting the conversion process. For this reason, errors are not tracked by this step, they are just reported to the user who is then asked if he still wants to go ahead.

The management of errors during processing is another thing altogether, and it's handled by the [Error Tracker] Module, which is required to build a final report with statistics (which are useful to handle multiple errors).

### Possible Changes

The current approach might not be suitable for the new design that is about to be implemented. This is due to the fact that the user will be able to pick and choose settings of how the project should be processed, possibly requiring a different model for the Check Project Integrity Step (eg: it might require that all resources be tested to).

Furthermore, a __Dry Run__ option will also be available, which would allow to simulate the whole conversion process without actually writing to disk, in order to prevent chaning anything on disk until we're sure that the whole process is error free. It makes sense that a dry-run should redirect to a disk cache all the converted pages, so that after the test run it would be possible to confirm conversion without having to repeat the whole process froms scratch.

While the Error Track is not going to be affected by this, the Check Project Integrity Step is definitely going to be.

Also, I think that some data structures and/or functionality of the tracker could be reused by the new Project Integrity checker (but in a way that shouldn't affect the report).

Another thing to keep in mind is that some resource file checks will automatically correct some problems with the resource (eg: if in-file settings are found, they are removed on the spot).



### Required Vars Access

The Error Tracker needs to access the following vars, which will have to be placed either in its module or in a common module:

|       var name       |  type  | namespace  |
|----------------------|--------|------------|
| `FatalErrTypeInfo()` | Array  | `Err::`    |
| `ErrTrackL()`        | List   | `Err::`    |
| `currCat`            | string | `Err::`\* |
| `currRes`            | string | `Err::`\*  |

> __NOTE\*__ — `currCat` and `currRes` might be needed by other modules too, so I might need to move them in some common module later on. Since they refer to processing categories, they don't belong in G mod (which some tools might use for processing single resources only, like Codes Checker, etc.), so I should think of creating a module to store project-wide data (categories, etc.).
>
> For now, I just place them in Err mod so I can go ahead with the work, and after all this is the module that deals with tracking processing, so it might even be OK to keep them here.



## Log Module

Currently all logging is directly printed to the debug window via `Debug`. Since the app is about to become a GUI app, chances are that it might also be used as a compiled binary instead of simply being Run from the IDE; so I should consider that the debug window won't necessary be available. After all, using a compiled binary might improve performance, so the original motives to keep the app IDE-runnable no longer apply (it was mainly to keep it simple, but this is no longer the case).

Therefore, an independent log module should be created, and wherever the current code prints out text to the debug window, it should instead pass that text to the log module, which will then decide if and how to display it.

Log messages should be passed to the module with something like:

```purebasic
log::logtext("some text", <DBG Level>)
```

... where `<DBG Level>` is a number representing the Debug Level of the text. This would allow the logger to decide if the text should be displayed or ignored, according to the current settings of the tool.

Maybe I could also add a third parameter, to indicate if the message should be considered as a `STDIN` or  `STDERR` message — so that console apps could redirect it correctly, and GUI apps might use this to handle text with different colors, etc, while other tools might just ignore this.

The whole point here seems to revolve around the fact that the Log module is probably going to be an intermediary between the various functionality modules and the main tool code; ie, the module is not going to actually handle the received text to produce some output, but instead make it available to the tool's main code, which will then decide how to display or store it.

So I might have to find a way to initialize the log module at startup, in order to register the procedures which the logger needs to interact with. Else, I could just store the data in the module namespace and expect the tool's maincode to retrive it on demand, by either accessing the raw data directly or by probing some exposed procedure of the log module. I must weigh the pros and cons of these diffrente approaches.

----------------------

# Problems Ahead

## Issues With Resource Files

There are some issues in dealing with resource files which require some thoughts in order to be implemented smartly, especially since they deal with functionality that will be shared by different apps.

Depending on the type of resource file, the number of operations that could be carried out on the resource may vary.

|     res type    | parse/validate header comments | check settings at end of file | `--check --thread` | ` CompilerIf #PB_Compiler_IsMainFile` block |
|-----------------|--------------------------------|-------------------------------|--------------------|---------------------------------------------|
| `<file>.pb`     | always                         | always                        | always             | _never_                                     |
| `<incfile>.pbi` | always                         | always                        | always             | always                                      |
| `CodeInfo.txt`  | always                         | _never_                       | _never_            | _never_                                     |

This brings to attention the fact that with include files (`.pbi`) there is a potential redundancy of file access if we were to keep separate functions for header comments parsing, checks for the presence of PB settings in the file and checks for a  `#PB_Compiler_IsMainFile` block.

Ideally, we could access the resource file just once:

1. Extract the raw header comments block (and store it to memory)
2. Check if PB settings are stored inside the file
3. Check that a `*.pbi` resource has a `#PB_Compiler_IsMainFile` block

This could be carried out indepedently of the desired actions — ie, the module dealing with resource files should carry out the above steps whenever it receives a request to do something with a given resource.

The downside of this approach is that any tools that don't wish to carry out all the checks might end up having some overhead due to this (potentially, steps 2 and 3 are the more time consuming ones).

Alternatively, the module could allow the user to register the intended actions he will need for any resource — ie, before actually carrying any of them out — so the module can smartly prefetch/preprocess the resource file accordingly.

This is worth considering, especially in view of the implementation of a cache system. In both cases, it's important that the module has some independent way of controlling file access, imposing a separation between the required actions on the resource and how and when the resource is accessed on disk. The tool should only worry about requesting to the module's API that the various checks are carried out, and leave it entirely to the module to decide when and how the resource should be retrived from disk, allowing therefore the module the freedom to prefetch data and store it to memory when this would prevent redundant disk accesses.

What emerges from these considerations is that all functionality dealing with resources is likely to be better handled by a single module — even if some tools will not use all of them.

<!-- REEFERENCE LINKS -->

[HTMLPagesCreator]: ./HTMLPagesCreator.pb
[mod_G]:      ./mod_G.pbi "View sourcefile of Global module"
[mod_Errors]: ./mod_Errors.pbi "View sourcefile of Errors module"
