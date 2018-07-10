# MODULARIZATION NOTES

Some notes on how to convert the current [`HTMLPagesCreator.pb`][HTMLPagesCreator] from a single sourcefile to a modules-based project so that some of its functionality can be shared by other tools of the CodeArchiv.


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Source Files](#source-files)
- [Modules and Tools](#modules-and-tools)
- [Modules Description](#modules-description)
    - [Global Module](#global-module)
    - [CodeArchiv Module](#codearchiv-module)
    - [Errors Tracker](#errors-tracker)
        - [Required Vars Access](#required-vars-access)
        - [Some Considerations...](#some-considerations)
    - [Resources module](#resources-module)
        - [Resources Integrity Checks](#resources-integrity-checks)
- [Notes on Modules Usage](#notes-on-modules-usage)
    - [Global Enumerators](#global-enumerators)
- [New Converter Goal](#new-converter-goal)
    - [Gathering Statistic](#gathering-statistic)
    - [Integrity Check](#integrity-check)
    - [HTML Page Creation](#html-page-creation)
- [Modules Roadmap](#modules-roadmap)
    - [Errors Management](#errors-management)
        - [Current Status](#current-status)
        - [Possible Changes](#possible-changes)
    - [Log Module](#log-module)
    - [GUI Introduction](#gui-introduction)
        - [GUI Prototype](#gui-prototype)
        - [Brainstorming](#brainstorming)
- [Problems Ahead](#problems-ahead)
    - [Issues With Resource Files](#issues-with-resource-files)
        - [Memoization: A Possible Solution](#memoization-a-possible-solution)

<!-- /MarkdownTOC -->

-----

# Source Files

- [`HTMLPagesCreator.pb`][HTMLPagesCreator]
- [`mod_G.pbi`][mod_G] — (`G::`) __[Global module]__ for commonly shared data.
- [`mod_Errors.pbi`][mod_Errors] — (`Err::`) __[Errors Tracker]__ module.
- [`mod_CodeArchiv.pbi`][mod_CodeArchiv]  — (`Arc::`) __[CodeArchiv module]__.
- [`mod_Resources.pbi`][mod_Resources]  — (`Res::`) __[Resources module]__.

# Modules and Tools

Here is an outline of which modules will be reused by which tools.

|        module        | HTML Generator | Codes Checker | Codes Cleaner |
|----------------------|----------------|---------------|---------------|
| `mod_G.pbi`          | yes            | yes           | yes           |
| `mod_Errors.pbi`     | yes            | ???           | ???           |
| `mod_CodeArchiv.pbi` | yes            | no            | no            |
| `mod_Resources.pbi`  | yes            | yes           | yes           |

The presence of "???" in the above table indicates uncertainty on wether some tools should make use of a module or not.

For example, both the Codes Checker and Cleaner could use the Errors Tracker, even though they deal with single resources. The pros and cons have to be weighed. Using the Errors Tracker would simplify managing errors, but might also introduce the burden of updating the tool if the module is updated in backward compatibility breaking manner.

--------------------------------------

# Modules Description


## Global Module

[Global Module]: #global-module "Jump to this module's section"
[mod Global]:    #global-module "Jump to this module's section"

- [`mod_G.pbi`][mod_G]

This module (`G::`) holds data commonly shared by all tools.

- __Cross platform constants__ (`#EOL`, `#EOL_WRONG`, `#DSEP`, etc.)
- __[Global enumerators](#global-enumerators)__


## CodeArchiv Module

[CodeArchiv Module]: #codearchiv-module "Jump to this module's section"
[mod CodeArchiv]:    #codearchiv-module "Jump to this module's section"

- [`mod_CodeArchiv.pbi`][mod_CodeArchiv]

> This section was last updated according to `mod_CodeArchiv.pbi` __v0.0.19__ (2018/06/07)

This module (`Arc::`) is intended as an interface for all tools to handle the CodeArchiv categories and resources:

- `Arc::ScanProject()` — Scans the CodeArchiv project tree and
    + builds list of all Categories (`Arc::CategoriesL()`)
    + builds list of the Top-Level Categories (`Arc::RootCategoriesL()`)
    + builds list of all Resources (`Arc::ResourcesL()`)
    + carries out integrity checks on the CodeArchiv:
        * Check that "`_assets/meta.yaml`" file exists and is not 0 Kb.
        * Check that every category has a "`REAMDE.md`" file and is not 0 Kb.
        * Check that every category contains resources.
        * Returns the number of errors found (if any).
        * Stores in `info\Errors` the number of errors found.
        * Stores in `info\IntegrityReport` a report on the integrity checks. (if everything went fine, the report will either contain a standard "everything is OK" message, otherwise a detailed report on the encountered errors)
- Exposes statistics via `Arc::info` data structure:
    + `info\IsReady.i` — Boolean for querying the module's status (_currently unused!_).
    + `info\Errors` Total errors found during project scanning.
    + `info\IntegrityReport ` Integrity Checks Report (with Errors details, if any).
    + `info\totCategories.i` — Total Categories count (Root excluded)
    + `info\totRootCategories.i` — Total Top-Level Categories count
    + `info\totResources.i` — Total Resources count
    + `info\totResT_PBSrc.i` — Total Resources of PureBasic Source type
    + `info\totResT_PBInc.i` — Total Resources of PureBasic Include-file type
    + `info\totResT_Folder.i` — Total Resources of Subfolder type
- Provides some plaintext __Info Helpers__:
    + `Arc::GetStats()` — returns a str with rèsumè of CodeArchiv Categories and Resources.
    + `Arc::GetTree()` — returns a str with an Ascii-Art Tree representation of the CodeArchiv Categories and Resources.
    + `Arc::GetCategories()` — returns a str with numbered list of all Categories in the CodeeArchiv.
    + `Arc::GetRootCategories()` — returns a str with numbered list of Root Categories (top-level categories).
    + `Arc::GetResources()` — returns a str with numbered list of all resources in the CodeArchiv.
- Provide some __Iterators__ for invoking a CallBack procedure on iterated items:
    + `Arc::CategoriesIteratorCallback( *CallbackProc )` — iterate categories and invoke `CallbackProc()` at each iteration
    + `Arc::ResourcesIteratorCallback( *CallbackProc )` — iterate through resources and invoke `CallbackProc()` at each iteration
- Exposes to the `CallbackProc()` info about the current Resource and Category being iterated, via `Arc::Current` structure:
    + `Arc::Current\Resource` — a struct var containing all required info about the current resource:
        * `File.s` — Filename ( `<filename>.pb` | `<filename>.pbi` | "`<subfolder>/CodeInfo.txt`" )
        * `Path.s` — Path relative to CodeArchiv root (includes filename)
        * `Type.i` — ( `G::#ResT_PBSrc` | `G::#ResT_PBInc` | `G::#ResT_Folder` )
        * `*Category.Category` — pointer to its parent category
    + `Arc::Current\Category` — a struct var containing all required info about the current category being iterated, or the host category of the current resource being iterated
        * `Name.s` —  Folder name
        * `Path.s` —  Path relative to CodeArchiv root (includes folder name)
        * `Level.i` —  0-2 (Root, Top-Level Category, Subcategory)
        * `SubCategoriesL.s()` List —  Name/Link List to SubCategories
        * `FilesToParseL.s()` List —  List of files to parse (including "`<subf>/CodeInfo.txt`")

The above feature of the module's API are intended to offer flexible access to the CodeArchiv resources and categories via specific API procedures and vars that hide away the complexity of the Archiv internals, and could change in the future without requiring rewriting the code of the tools using this module — a few tweaks should suffice to adapt to major API changes.

Having separate lists and iterators for Categories and Resources allows the module to be useful for both tools dealing with Categories (eg, the HTML pages creator) and tools that focus on checking that resources meet the requirements.


## Errors Tracker

[Errors Tracker]: #error-tracker "Jump to this module's section"
[mod Errors]:     #error-tracker "Jump to this module's section"

- [`mod_Errors.pbi`][mod_Errors]
 
This module (`Err::`) tracks and handles all errors encountered during the processing stage of the project (validation, extraction, conversion, etc.). Every module that takes part in the Archiv processing should report errors to this module and let the module handle them.

- `Err::TrackError(ErrMessage.s)` — signal an error and carry on.
- `Err::Abort(ErrorMsg.s, ErrorType)` — signal a fatal error and request aborting processing the Archiv.

When requesting `Abort()`, the passed `ErrorType` should be one of the following

- `Err::#FATAL_ERR_GENERIC` (default if none specified)
- `Err::#FATAL_ERR_INTERNAL` — error due to App internals.
- `Err::#FATAL_ERR_FILE_ACCESS` — App can't get access to file resources.
- `Err::#FATAL_ERR_PANDOC` — any blocking error related to pandoc.

Before Aborting, the Errors Tracker will ensure that any statistics gathered so far are printed in the final report, so that the user can be made aware of all problems encountred (and not just the last one, which halted processing).

### Required Vars Access

The Errors Tracker needs to access the following vars, which will have to be placed either in its module or in a common module:

|       var name       |  type  | namespace  |
|----------------------|--------|------------|
| `FatalErrTypeInfo()` | Array  | `Err::`    |
| `ErrTrackL()`        | List   | `Err::`    |
| `currCat`            | string | `Err::`\* |
| `currRes`            | string | `Err::`\*  |

> __NOTE\*__ — `currCat` and `currRes` might be needed by other modules too, so I might need to move them in some common module later on. Since they refer to processing categories, they don't belong in G mod (which some tools might use for processing single resources only, like Codes Checker, etc.), so I should think of creating a module to store project-wide data (categories, etc.).
>
> For now, I just place them in Err mod so I can go ahead with the work, and after all this is the module that deals with tracking processing, so it might even be OK to keep them here.


### Some Considerations...

The error tracker is intended to gather statistics of any errors encountered during the actual processing of the project, in order to present a detailed report at the end. The way errors are stored should be independent of their final representation (ie: the app's GUI, the debug window, or a log file).

Also, I must keep in mind that the final app might implement a dry-run feature to actually test building the whole project without writing any changes to disk, only in order to check if any errors are encountered with pandoc or at other places. So the error tracker must be able to accomodate that too.

#### The Tracker is For Tools, not Modules?

_Here are some arguments in favor of the fact that the Errors Tracker should be used only by the main tools/apps, not by modules..._

The fact that we have a module dedicated to tracking Errors doesn't mean that _every_ error type should be delegated to the Error Tracker. For example, when [mod CodeArchiv] carries out its Integrity Checks, the number of errors found are stored in `Arc::info\Errors`, and a report is stored in  `Arc::info\IntegrityReport`, which will contain details of every error (if any). In this case, there seems to be no need for this type of check to rely on the Errors Tracker, for we're dealing with basic initialization of the CodeArchiv (project and module). Most tools will probably just need to know if the Archiv is ready for being processed, and the above vars suffice for this.

Usually, a tool will consider the Error Tracker as a way to track errors encountered during the main steps which the tool is specifically designed to perform, so that it can be produce a detailed custom report at the end. Modules initialization failures (like the example above) are subsidiary to the tool tasks, and instead of having those initialization procedures communicate directly with the Error Tracker, it should be up to the tool to decide if to include these errors and how. 

In other words: the Tracker should be fully controlled by the app/tool, not by the single modules; the latter should store their errors internally, and offer an interface to the main tool for examining such errors, but it's up to the main tool to fully control the Tracker.

The next section shows the complications that derive from having the modules use the Tracker — ie, the modules would have to register themselves with the Tracker in order to be managed.

#### Should Modules Register Themselves with mod Errors?

_Here are some considerations of the complications that would arise if the Tracker was to be used by modules too...._

Ideally, each module should store information about its errors, but the [Errors Tracker] module has to also track all the errors of all the modules, so that it can print out to the user/tool a report on all the errors encountered at any stage (wether it's just an integrity check stage or an actual attempt to build the HTML pages).

Probably, I'll have to devise a way to allow each module to "register" itself with the [Errors Tracker] at initialization time (like Sicro is doing with the logger module), so that the Errors module is able to handle errors from various modules separately (internally) and at the same time produce unified error reports from all modules. 

After all, different tools might use some modules and not others (eg, the Code Checker for single resources will not need the CodeArchiv module), so the Errors module shouldn't make assumptions about which modules will be present during use.

This topic introduces another need too, that of some global initialization system (via mod G) that allows all modules to initialize themselves according to other modules included by the app, and their settings. This might be especially true for the Errors and Logger modules. I should think of some simple way to handle registering modules via mod_G.

## Resources module

[Resources module]:  #resources-module "Jump to this module's section"
[mod Resources]:     #resources-module "Jump to this module's section"

- [`mod_Resources.pbi`][mod_Resources]

Currently an empty module that does nothing.

Eventually, it will offer an interface to manage and query all the resources of the CodeArchiv — and behind the scenes, it will also handle caching the parsed resources output to speed up processing time (See [Issue #18]).

### Resources Integrity Checks

These are the integrity checks that the module should carry out on each resource:

- 


See also:

- [Issue #10  — Integrating The Old Tools][Issue #10]
- [Issue #18  — Caching Proposal & Ideas][Issue #18]


--------------------------------------

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

# New Converter Goal

> _**BEWARE** — THIS SECTION IS OLD AND MIGHT NOT REFLECT THE LATEST CHANGES!_

Currently, the HTMLPageConvert has always been intended as a tool to merely create the HTML pages for the project; this was strongly determined by the fact that it was a "runnable" and guiless app. The upcoming introduction of the GUI lifts these limits, and the new app could be considered as a general purpose project maintainment tools providing this functionality:

1. Collect Statistics on the Archiv
2. Check Archiv Integrity
3. Create HTML Pages

... whereas these three are currently blended into a single operation, we can imagine project maintainers needing the tool to use them separately. Here are some practical examples

## Gathering Statistic

At any point in time a maintainer might wish to use the tool for the sole purpose of collecting some statistic on the CodeArchiv — how many Categories there are, how many resources, the full list of code authors, statistics on code licenses, etc.

Therefore, the Statistics functionality of the new App could be furthered developed in time, in order to allow finer statistics, even though these might not be used by the actual page creation process.

## Integrity Check

Maintainers should be able to check the CodeArchiv integrity even without creating the HTML pages. For example, when introducing changes in the project's prerequisites multiple resources and categories might require adaptation to the new standard, and the maintainer might wish to run Integrity Checks at multiple times, targeting specific aspects of the Project.

Likewise, when importing into the Archiv multiple new resources there would be a need to frequently run the integrity checks, until all resources and categories pass the tests.

Therefore, Integrity Checks should be a functionality that can be accessed from the GUI independently from page conversions — but obviously, any integrity check findings will also be available to the converter and other functionality so they can use the data to organize their tasks.

## HTML Page Creation

Creation of the HTML pages should have a panel of its own. Running this task will implicity also run tasks that are common to both Statistics and Integrity, because behing the scenes all functionality share some procedures and data. But as far as the end user should be concerned, HTML Creation is presented in a panel of its own, allowing the user to open the App and request stratight away to create/update all the HTML pages.

...

These three functionalities/panels are to be considered as representing three successive steps of the process — Integrity Checks implicitly require gathering Statistics, and HTML Conversion implicitly requires Integrity Checks to be run. Their separation into independent panel is simply a way to presen them to the end user and independently manageable features.

--------------------------------------

# Modules Roadmap

> _**BEWARE** — THIS SECTION IS OLD AND MIGHT NOT REFLECT THE LATEST CHANGES!_

I still need to work out properly how to move all the current functionality into separate modules. Presently, the main challenges are posed by the Error Tracking system, the Debug logging and the Final Report: in order to move any part of the current code to independent modules, I must first address these three systems so that they don't break down.

Then, I must decide which of the current HTML Creator functionality needs to be split in a module and which might be kept in main code — basically, it boils down to what might be needed by other tools.

Because in PureBasic modules can't access main code, moving any functionality to a module is likely to force me to move commonly shared data to an independent module too. For example, implementing the GUI as a separate module will have an avalanche effect in this regard (which is why I'm taking so long to decide how to go about splitting up the current code).

These are tricky issues, so I should plan it well.


## Errors Management

### Current Status

Currently the HTML Pages Creator has a dual approach to errors:

1. Check Project Integrity Step
2. Project processing errors managment

The two are independent from each other. The Project Integrity Step does some preliminary checks to verify if there are structural problems in the Archiv, but doesn't go as far as checking the integrity single resources. This is intended as a way to detect common problems before starting the conversion process. For this reason, errors are not tracked by this step, they are just reported to the user who is then asked if he still wants to go ahead.

The management of errors during processing is another thing altogether, and it's handled by the [Errors Tracker] Module, which is required to build a final report with statistics (which are useful to handle multiple errors).

### Possible Changes

The current approach might not be suitable for the new design that is about to be implemented. This is due to the fact that the user will be able to pick and choose settings of how the project should be processed, possibly requiring a different model for the Check Project Integrity Step (eg: it might require that all resources be tested to).

Furthermore, a __Dry Run__ option will also be available, which would allow to simulate the whole conversion process without actually writing to disk, in order to prevent chaning anything on disk until we're sure that the whole process is error free. It makes sense that a dry-run should redirect to a disk cache all the converted pages, so that after the test run it would be possible to confirm conversion without having to repeat the whole process froms scratch.

While the Error Track is not going to be affected by this, the Check Project Integrity Step is definitely going to be.

Also, I think that some data structures and/or functionality of the tracker could be reused by the new Project Integrity checker (but in a way that shouldn't affect the report).

Another thing to keep in mind is that some resource file checks will automatically correct some problems with the resource (eg: if in-file settings are found, they are removed on the spot).


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

## GUI Introduction

The introduction of a GUI is going to be a bing change, affecting both data access and storage as well as user options to control details of the various checks, the conversion process, and how errors should be handled (eg, allowing to ignore errors for maintainance/dev purposes).

If on the one hand a GUI simplifies controlling settings, on the other it introduces new problems too because the possible combinations of user choices must be kept under control to prevent unwise mixtures and redundant behaviours.

It seems worth of building the GUI as a module (`GUI::`) so to make it accessible from other modules too. I haven't decided yet if user settings for the project should be stored in the GUI's module or in a separate module — probably it's better to have a dedicated module for the Archiv data and info, settings included, just in case in future we might need a separate console tool for other purposes.

### GUI Prototype

Currently, GUI testing and prototyping is being done in:

- [`../_tempwork/GUI_prototype/`][GUI folder]
    + [`protoGUI.pb`][protoGUI] — codebase of GUI
    + [`dummyGUI.pb`][dummyGUI] — proof of concept via Form Designer
    + [`dummyGUI_screenshot.png`][dummyGUI img] — proof of concept screenshot

[GUI folder]: ../_tempwork/GUI_prototype/
[protoGUI]: ../_tempwork/GUI_prototype/protoGUI.pb
[dummyGUI]: ../_tempwork/GUI_prototype/dummyGUI.pbf
[dummyGUI img]: ../_tempwork/GUI_prototype/dummyGUI_screenshot.png

Different approaches are being considered. Once a satisfying result is achieved (visually speaking), it will be moved to this folder to start integration.

### Brainstorming

I need to brainstorm what the GUI should display to the user, and which options should be changeable and how.

As a general rule, the GUI should be divided in panel, each covering a given aspect of the project (info, error, conversion, etc.). Each panel should display elements resuming the overall status in a simple manner, and offer a button which can be clicked to get a pop-up window with detailed information. 

![Proto GUI imgs][dummyGUI img]

Also, each panel should have a timestamp displaying when it was last refreshed, since some panel will be connected to different level of functionality — refreshing one panel might render inactive other panels, depending on the cascading level of dependency amongst them, but the timestamp will always provide a visual clue to the last time it was updated (manually or automatically alike).

Some panels will also need to offer some button(s) to carry out actions, and maybe others to select options and settings.

The whole idea is to keep the GUI clean, avoiding too many entries (all that is not strictly necesary should be delegate to the pop-up window for details).

The tricky part is going to be keeping track of what changes, options and rereshes need to affect other panels and their settings — one more reason to keep it simple in design.

Conceivably, there should be a progess status panel to indicate when the app is doing something. It should have both a counter (of the type `n/n`, indicating current step out of total steps) and a progress bar.

A log gadget of sorts should also be available, to display log info on the latest operation(s) carried out in the background — the full log should be accessible in a pop-up window by clicking a button. Possibly, a WebGadget should be used, to allow basic text coloring to distinguish error and success messages (red, green) from neutral logs (grey). In the past I've already used the WebGadget for similar purposes, and it has always served me well (and comes with less problems than using other types of gadgets for the purpose).

The log gadget will have to communicate with the Log Module, most probably. A few intermediate procedures can easily handle this, and decide how to color the text, and when to reset the log gadget's text to make space for more recent log info — as for the pop-up with the full log, it will depend on how the log module works: the full log might be either stored by the GUI or the log module.

#### Project Info Panel

The GUI should have a panel displaying info on the Archiv structure:

- Total Number of Categories (n)
    + Number of Root Categories
    + Number of Sub-Categories (s/n)
- Total Number of Resources (n)
    + number of `.pb` resources
    + number of `.pbi` resources
    + number of `CodeInfo.txt` resources
- Last Updated (timestamp)

The above information should be gathered automatically at startup, but at any time the user can use a `refresh` button to update it (eg, if he has changed the files/folders in the meantime) — refreshment of this dialog might imply resetting other dialogs too, because some changes in the Archiv might require running again some functions.

The __Last Updated__ (timestamp: `YY/MM/DD-hh-mm-ss`) seems useful because different panels might be refreshed at different points in time, and if each panel has a timestamp it can be useful to keep track of their differences, and to work out why a panel is greyed out (ie, needs refreshing).

#### Project Errors Panel

Another panel should show statistic on problems found in the Archiv, either __structural problems__ (missing READMEs, etc.) or __resource problems__ (resources not passing the check tests). 

Some error information might not be available at all times, so there must be a way to visually represent uncertainity — eg, an entry might be `README.md`, intended to show if every Category has a `README.md` file, showing a green check if the test passed, a red cross if problems where found (and maybe also the number of errors), and a question mark if the matter is yet unknown.

So, the possible entries in such a panel could be:

- Project Structure:
    + __READMEs__ — all Categories must have a `README.md`
    + __YAML Settings__ — the Arhiv project needs a `meta.yaml` file.
- Resources:
    + __syntax__ — reporting on how compilable resources passed the `--check --thread` compiler test. This one is tricky because I haven't yet understood how accurately the PBCompiler can check a sourcefile destined for another OS!
    + __header comments__ — reporting if a resource passed all tests on its commented headers (obligatory keys, etc.)
    + __include files__ — reporting if `.pbi` files contain the required `CompilerIf #PB_Compiler_IsMainFile` block.

Although incomplete, the above list makes it clear that a similar panel would be too cluttered to be practical. I should summarize the different problems in a few useful categories:

-  __Proj Structure__ (n) — where `n` is the number of structural errors (if any)
-  __Resources__ (e/n) — where `e` is the number of faulty resource over `n` (total num of resources)
-  __Dependencies__ (n) — where `n` is the number of problems encountered with dependencies (pandoc, etc).

... and just assign to them a color based on status (green = ok, red = error, grey = unknown) and add next to them a number in braces showing the total count — eg: __Resources (80)__ in green = 80 resources, all passed the test; while __Resources (5/80)__ in red = 80 resources, 5 of which didn't pass the test; and __Resources (80)__ in grey = 80 resources, unknown status; while __Resources (?)__ would indicate unknown number of resources and status.

And so on.

Looking at the proof of concept screenshot:

![Proto GUI imgs][dummyGUI img]

... the GUI's "__Project Status__" panel is telling us that:

- __Categories__: 3 out of 21 categories have problems which must be addressed. It could be that each category has more than one error, and that the error is tied specifically to the category structure (READMEs, etc) or even to a resource therein — it ultimately depends on how we wish statistics to be shown.
- __Resources__: 10 out of 85 resources have problems that need to be addressed. It could be that a resource has more than one problem (invalid header, settings saved in file, and include file has no main block). In this case we can pinpoint the number of faulty resources OR the total number of resources related problems (it's a matter of choice).
- __Structure__: 0 structural problems found.
- __Dependencies__: 1/1 dependencies are OK.

This first prototype has brought to light that simplicity in the GUI could also introduce ambiguity of interpretation. We must decide how errors are counted — WHAT COUNTS AS A CATEGORY ERROR? ANY ERROR, INCLUDING RESOURCES?.

Of course, the `details` button will pop-up a detailed resume of all these problems, leaving no ambiguity of interpretations; nevertheless, __this has brought to attention the issue of how to classify and count problems in GUI panels__ — we can't create an entry for each separate problem, but grouping multiple problems under a same entry creates ambiguity.

The panel should then have an `Info` button which can be clicked to produce a pop-up window with a full status report — structure, resources and dependencies, listing all the known problems and statistics. This would be a much cleaner approach (instead of a cluttered panel) and still allow access to full status details from within the GUI.

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

### Memoization: A Possible Solution

The above mentioned issues could be resolved by employing momization in the module's procedures: if the resource has already been parsed, the stored data is returned instead of carrying out the full process of accessing the resource and extracting the data.

This does not solve the general problem of wehter or not any attempt to check a resource for a specific problem should make the module prefetch all potentially needed data. This second aspect could be handled by some settings passed to the module, to inform it of what checks the tools will carry out in the context — eg., a tool might inform the res module that it's not interested in dealing with PB settings that might be stored in the source file, but only with parsing header comments; in this case the module will not attempt to handle the in-file settings and memoize them. And so on. 

These two solutions together could optimize both the issue of redundant file access, as well as provide a single reusable module for all tools that will not carry out unnecessary actions.

The details of how these are going to be implemented are yet to be established, but they should not affect they module's API nor create problems when a cache system is introduced in the main code of the HTML Generator (file caching should filter invocations of the res module, and therefore not affect the res module's public interface).

With this in mind, I should start to move all resource related functionality to an independent module, even if it doesn't take care of optimizations at the onset — as long as it won't break its usage when these are introduced.



<!-----------------------------------------------------------------------------
                               REFERENCE LINKS                                
------------------------------------------------------------------------------>


[HTMLPagesCreator]: ./HTMLPagesCreator.pb
[mod_CodeArchiv]: ./pb-inc/mod_CodeArchiv.pbi "View sourcefile of CodeArchiv module"
[mod_Errors]:     ./pb-inc/mod_Errors.pbi "View sourcefile of Errors module"
[mod_G]:          ./pb-inc/mod_G.pbi "View sourcefile of Global module"
[mod_Resources]:  ./pb-inc/mod_Resources.pbi "View sourcefile of Resources module"

<!-- GitHub Issues -->

[Issue #10]: https://github.com/tajmone/PBCodeArcProto/issues/10 "Issue #10 — Integrating The Old Tools"
[Issue #18]: https://github.com/tajmone/PBCodeArcProto/issues/18 "Issue #18 — Caching Proposal & Ideas"
