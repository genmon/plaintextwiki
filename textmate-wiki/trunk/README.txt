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

Insert a list of pages by typing 'pagelist' and hitting tab.


Export as HTML
--------------

Choose 'Export Wiki as HTML' from the Plain Text Wiki commands menu. You will 
be prompted for a directory where the Web pages will be saved (please make 
sure it's empty).

For converting text to HTML, Plain Text Wiki understands Markdown: 
http://daringfireball.net/projects/markdown/syntax

To customise the HTML of the wiki, add wiki-styles.css to the project 
directory--it'll be copied to the export directory and included.

For more control, add wiki-header.html and wiki-footer.html to the project 
directory. Include the string "%s" in wiki-header.html to have that replaced 
with the page title on export.


Bugs and issues
---------------

Please let me know about any bugs. Patches are welcome!

Issues:

* The text.html.markdown language grammar, and grammar to underline http-style 
  URLs, should be included
* Bundle needs to adhere to http://macromates.com/wiki/Bundles/StyleGuide
* Grammar binds to a number of file extensions, but exports only '.txt'


Changes
-------

2007-06-10:

* Fixed Create New Wiki command (which was not working)

2007-06-09:

* Added 'Insert Page List'
* 'Follow Page Link' now ignores case when looking for a text file to open
* Export now looks for wiki-styles.css, wiki-header.html and wiki-footer.html
* Various bugs fixed in way Export adds HTML links
* Export prompts to replace files in the export directory


Miscellaneous
-------------

More background to Plain Text Wiki:
http://interconnected.org/home/2007/05/20/plain_text_wiki
