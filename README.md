This is a collection of scripts created by Timothy B. Lee while he was a grad student at Princeton University
in 2010-11. The code is released into the public domain, as described in the "LICENSE" file.

Thanks to Carl Malamud and Public.Resource.org for their support of this project.

# Installation

The scripts are written in the perl language, which is installed by default on Mac OS X and Linux systems.

Download the project folder to a directory that you want to use for this purpose.

You will also need a PDF library from a perl archive known as CPAN.  The name of the library is CAM::PDF.  On Mac OS X, you install this by typing the shell command (in Terminal.app):

    CPAN

This launches the program that manages which CPAN packages are installed on your machine.  If all goes well, this will bring up the prompt "cpan[1]>".  Type:

    install CAM::PDF

You may be asked if it's okay for the program to try to connect to the internet.  The answer is yes.

The package manager might ask you if it should install other related programs ("dependencies") such as "Crypt::RC4" and "Text::PDF."  The answer should also be yes.

You should see quite a bit of text fly by on the console as these packages are downloaded and installed on your system.  The last message should end with an "OK" if everything is, indeed, okay.

To check your installation, type:

    m CAM::PDF

You should see a listing that tells you, among other things, the local path in which the file was installed.  (On a Mac, this might look like "/Library/Perl/5.10.0/CAM/PDF.pm".)

When you're done with using CPAN, just type "quit" to return to the normal shell.

# Basic use from the Command Line

To check whether a particular PDF contains improper redactions, you will want to use the script "find_bad_redactions.pl".

In Mac OS X, you can type something like the following:

    ./find_bad_redactions.pl [FILENAME]

(The ./ tells the system to try to execute the file as if it were a script, which this file happens to be.  Alternatively, you could type out the word "perl" before the name of the script.)

If the PDF is not in the same folder as the script, the FILENAME needs to include enough information to tell the system which folder it's in.

Using Mac OS X, an easy shortcut is to drag an icon from the Finder onto the Terminal.app console window.  The system then inserts a complete file path, such as "/Users/dc/Desktop/rosenthal_redacted.pdf".

If the system detects a problem, you should see detailed output.  If the system does not detect a problem, it will not report anything at all.  (**TODO: It seems like a message that the file is safe would be better for most users.**)

# Using from the Services Menu / Automator Action
