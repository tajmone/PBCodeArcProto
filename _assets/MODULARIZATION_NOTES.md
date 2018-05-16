# MODULARIZATION NOTES

Some notes on how to convert the current [`HTMLPagesCreator.pb`][HTMLPagesCreator] from a single sourcefile to a modules-based project so that some of its functionality can be shared by other tools of the CodeArchiv.


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Source Files](#source-files)
- [Modules Description](#modules-description)
    - [Global Module](#global-module)
- [Notes on Modules Usage](#notes-on-modules-usage)
    - [Global Enumerators](#global-enumerators)
- [Modules Roadmap](#modules-roadmap)
    - [Error Tracker](#error-tracker)
        - [Required Vars Access](#required-vars-access)
    - [Log Module](#log-module)

<!-- /MarkdownTOC -->

-----

# Source Files

- [`HTMLPagesCreator.pb`][HTMLPagesCreator]
- [`mod_G.pbi`][mod_G] — (`G::`) Global module for commonly shared data.

# Modules Description

## Global Module

- [`mod_G.pbi`][mod_G]

This module (`G::`) holds data commonly shared by all tools.

- __Cross platform constants__ (`#EOL`, `#EOL_WRONG`, `#DSEP`, etc.)
- __[Global enumerators](#global-enumerators)__


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

## Error Tracker

Error tracking should be handled by an independent module. Currently, the __Check Project Integrity__ step is independent of the error tracker: the former only detects errors before the processing stage, and its found errors are not tracked by the error tracker for the final report as this would created duplicate entries. Nevertheless, if some data structures and/or functionality of the tracker could also be used by the Project Integrity checker it would be better (but it shouldn't affect the report).

The error tracker is intended to gather statistics of any errors encountered during the actual processing of the project, in order to present a detailed report at the end. The way errors are stored should be independent of their final representation (ie: the app's GUI, the debug window, or a log file).

Also, I must keep in mind that the final app might implement a dry-run feature to actually test building the whole project without writing any changes to disk, only in order to check if any errors are encountered with pandoc or at other places. So the error tracker must be able to accomodate that too.

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



<!-- REEFERENCE LINKS -->

[HTMLPagesCreator]: ./HTMLPagesCreator.pb
[mod_G]: ./mod_G.pbi
