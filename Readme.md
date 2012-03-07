Annotatedit
===========

Proof-of-concept work-in-progress for a "[literate programming](http://vasc.ri.cmu.edu/old_help/Programming/Literate/literate.html)" code editor. Literate programming means different things to different people. All this editor intends to do is display comment blocks in a separate column adjacent to the code blocks they document. The plan is not to promote yet another new text editor but to experiment with interface designs that may facilitate more detailed documentation without unduly obscuring the code.

The main code file is `annotatedit.vfs/lib/annotatedit/annotated.tcl`. Run with `tclsh annotatedit.vfs/main.tcl </path/to/input/file.txt` (The directory structure will later be used to package the code plus dependencies in a single file.) 

Status
------

Performs a single formatting pass when text is loaded. This consists of iteratively searching the text for comment blocks, tagging them as such, and also tagging certain lines at code/comment block boundaries. `-spacing` and `-elide` text widget styles are manipulated for these tags to yield the desired appearance.

Formatting is lost when the text is edited. The single-pass formatting needs to be retooled to work like syntax highlighting, so that it is updated in response to edit events.

Here's a screenshot. Extended comment blocks are displayed adjacent to the following code. As an aid to debugging and to visualize how alignment is achieved, areas with modified linespacing are highlighted in blue.

![Sample screenshot](https://github.com/anoved/Annotatedit/raw/master/Screenshots/5.png)
