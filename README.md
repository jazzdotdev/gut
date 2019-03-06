<p align="center"><img width="100" src="https://i.imgur.com/Vm9PyLX.png" alt="torchbear logo"></p>

# Gut

Gut makes it easy to create and manage patches.  This makes it easy to keep track of any changes you're working on and to integrate them across many development paths.  It does this by saving your project files and allowing you to freely edit them while being sure that you can jump back to your last saved version or add your new changes on top of it to take its place as the latest revision.

When you want to start working on a new change, you can see how it fits into your plans while working on new patches for it, and editing the change's notes along the way.  Once you have a group of changes and their patches, you can send those files to another Gut user, to easily drop them into their `.gut/` directory and work with these collaborators.

When you want to make multiple lines of development with several changes in them, just add a new line while you have that current version.  From there, you can see what other changes have already been started, and use them, or you can start making your own change with new patches.

## Terms

* patch: lines added and removed to one file or a group of files in a project 
* change: work done/todo, reference to an ordered list of patches, see change management about workflow
* line: a way to have multiple histories simultaneously which can themselves also go in other directions before merging back to prime or becoming a new prime line
* prime: a kind of line with the set of changes that takes an intial copy up to the current version - and likewise back to the original
* associate: a kind of line that start from any part of the prime line
* hash: blake2 of a file or dir
* .gutomit: leave out files or directories from your project (ignore/exclude)
* .gut/: directory that gut uses to run

## How Gut Works

* gut start copies your current working directory to .gut/current/
* // edit your files  //
* gut check: show what's changed compared to "last prime" patch or other picked line -- uses hashes, checks sanity before running
* gut diff: show differences
* gut patch: creates the patch and add it to current change
* gut change: a) show current change name and body (b) edit its name and body (c) show current patches (d) show which lines its on
* gut line: (a) show current (b) list available (c) graph where they come from and others associated (d) switch lines

## Current commands (this is a rough draft of the spec outlined above)

* `gut start` -- begin tracking project
* `gut save` -- save current project files
* `gut diff` -- see changes since last save
* `gut patches` -- show patches directory
* `gut series` -- show current chain of patches
* `gut forward|backward` -- navigate the chain of patches
* .gutomit - leave out files from patches

## Installation

* install [Torchbear](https://github.com/foundpatterns/torchbear)
* run `mp install gut`
