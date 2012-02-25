Annotatedit
===========

Proof-of-concept work-in-progress for a "literate programming" code editor. Literate programming means different things to different people. All this editor intends to do is display comment blocks in a separate column adjacent to the code blocks they document. The plan is not to promote yet another new text editor but to experiment with interface designs that may facilitate more detailed documentation without unduly obscuring the code.

The main code file is `annotatedit.vfs/lib/annotatedit/annotated.tcl`. (The directory structure can later be used to package the code plus third party dependencies in a single file.)

Status
------

Not yet interactive. Displays text read from `stdin` on startup and applies formatting once. Future development will of course need to focus on maintaining formatting when edited.
