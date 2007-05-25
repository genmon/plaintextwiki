$Revision$
$LastChangedDate$


Plain Text Wiki
===============

Plain Text Wiki is a TextMate bundle which allows you to use a directory of 
text files as a simple wiki.

The bundle is by Matt Webb <http://interconnected.org/home>.


Installation
------------

Download and unzip Plain-Text-Wiki.zip. Double-click on the bundle to install 
(the bundle requires TextMate: <http://macromates.com>).


Usage
-----

* Create a new directory
* In TextMate, choose 'Create New Wiki' from the menu 
  Bundles > Plain Text Wiki
* Select your new directory. A file 'IndexPage.txt' will be created and opened
* Reference new pages using CamelCase or [[like this]]. Page names will appear 
  underlined
* To follow a link, put the text cursor over a page name and hit Enter (not 
  Return)

Return to the index page at any time: Type shift+ctrl+i

Plain Text Wiki understands Markdown: 
http://daringfireball.net/projects/markdown/syntax

If the wiki is written in Markdown, choose 'Export Wiki as HTML' from the 
Plain Text Wiki commands menu. You will be prompted for a directory where the 
Web pages will be saved (please make sure it's empty).


Bugs and issues
---------------

Please let me know about any bugs. Patches are welcome!

Advice welcome on:

* How to include the text.html.markdown language grammar while still keeping 
  the underlined wiki page names
* How to make sure the shell and URI escaping really, *really* works
* Better Ruby idiom (I'm new to the language)
* Better TextMate bundle behaviour (ditto)


Miscellaneous
-------------

More background to Plain Text Wiki:
http://interconnected.org/home/2007/05/20/plain_text_wiki

