Annotatedit
===========

Proof-of-concept work-in-progress for a "[literate programming](http://vasc.ri.cmu.edu/old_help/Programming/Literate/literate.html)" code editor. Literate programming means different things to different people. All this editor intends to do is display comment blocks in a separate column adjacent to the code blocks they document. The plan is not to promote yet another new text editor but to experiment with interface designs that may facilitate more detailed documentation without unduly obscuring the code.

The main code file is `annotatedit.vfs/lib/annotatedit/annotated.tcl`. Run with `tclsh annotatedit.vfs/main.tcl </path/to/input/file.txt` (The directory structure will later be used to package the code plus dependencies in a single file.) 

Status
------

Not yet interactive. Displays text read from `stdin` on startup and applies formatting once. Next major task is to maintaining code/comment tagging and formatting during editing. Other tasks include formatting (the annotations don't need to be displayed with indentation, although it should be retained in the code) and logical behavior for starting/splitting/deleting blocks (eg, switching input focus to the appropriate pane).

Here's a rough screenshot. The highlights in the code indicate where the adjacent blue comment blocks actually reside.

![Sample screenshot](https://github.com/anoved/Annotatedit/raw/master/Screenshots/4.png)
