#!/usr/bin/env ruby
#
# $Revision$
# $LastChangedDate$

require 'FileUtils'

$: << "#{ENV['TM_SUPPORT_PATH']}/lib" if ENV.has_key?('TM_SUPPORT_PATH')

class PlainTextWiki
    # Default extension
    EXT = ".txt"
    
    # set by the initializer, passed in
    attr_reader :dir
    
    def initialize(dir)
        # Exit unless dir is set (usually from ENV['TM_DIRECTORY'])
        # The TextMate command will demand that the file is saved (and so the
        # directory will be set), but it's best to double check given the
        # failure mode
        unless dir
    	    puts "Save this file first."
    	    exit 206
    	end
        
        @dir = dir
        @pages = nil
    end
    
    def follow_link
       if ENV['TM_SCOPE'].include?('markup.other.pagename.delimited')
        	idx = ENV['TM_LINE_INDEX'].to_i
        	pagename = (((ENV['TM_CURRENT_LINE'][0..idx-1] || "").reverse)[/^[^\[]*/] || "").reverse + ENV['TM_CURRENT_LINE'][idx..-1][/^[^\]]*/]
        	pagename = pagename.sub(/\[+/, "");
        	pagename = pagename.sub(/\]+/, "");
        	pagename.capitalize!
        else
        	pagename = ENV['TM_CURRENT_WORD']
        end
        
        go_to pagename
    end

    def go_to_index_page
        go_to "IndexPage"
    end

    def go_to(pagename)
        fn = pagename + EXT
        
        require 'uri'

        # Touch the file if it doesn't exist
        all_files = Dir.entries(dir)
        unless all_files.include? fn
            # It may be the file exists but with a different case
            if all_files.map { |af| af.downcase }.include? fn.downcase
                # The filename is needed with the correct case because
                # otherwise it won't open properly in the project window
                fn = all_files.select { |af| af.downcase == fn.downcase }.first
            else
                FileUtils.touch("#{dir}/#{fn}")
                # switch away from TextMate and back to refresh the project drawer
        	    `osascript -e 'tell application "Dock" to activate'; osascript -e 'tell application "TextMate" to activate'`
            end
        end

        fn = "#{dir}/#{fn}"
        `open "txmt://open/?url=file://#{URI.escape(fn, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"`    
    end
    
    def export_as_html
        require 'Find'
        require "#{ENV['TM_SUPPORT_PATH']}/lib/bluecloth.rb"
        require "#{ENV['TM_SUPPORT_PATH']}/lib/rubypants.rb"

        # Ask the user for an export directory, exiting if cancelled
        cocoadialog = "#{ENV['TM_SUPPORT_PATH']}/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog"
        export_dir = `#{cocoadialog} fileselect --text "Choose a directory for wiki export" --select-only-directories`.strip
        exit if export_dir.empty?

        # Gather a list of source files, from the top level only
        files = [] # ([source, dest, title])
        extensions = ['.txt', '.markdown', '.mdown', '.markdn', '.md']
        Find.find(dir) do |path|
        	next if path == dir
        	File.prune if File.directory?(path)
        	next unless extensions.include?(File.extname(path))

        	old_fn = File.split(path)[1]
        	title = old_fn[0..(old_fn.length-File.extname(old_fn).length-1)]
        	new_fn = title + '.html'
        	files.push([path, File.join(export_dir, new_fn), title])
        end

        # Make sure there are no files in the way
        files_in_the_way = false
        files.each do |source, dest, title|
        	if File.file?(dest)
        	    files_in_the_way = true
       	    end
        end
        if File.file?("#{export_dir}/wiki-styles.css")
            files_in_the_way = true
        end
        
        if files_in_the_way
            res = `#{cocoadialog} msgbox --text "Export will replace files" --icon "x" --informative-text "There are files in the way in the export directory. They will be lost if you continue." --button1 "Cancel Export" --button2 "Replace All"`
            if res == 1
                puts "Cancelled Export Wiki as HTML"
                exit 206
            end
        end

        # For each file, HTML-ify the links, convert to HTML using Markdown, and save
        files.each do |source, dest, title|
        	s = with_html_links(open(source, 'r').read)
        	html = RubyPants.new(BlueCloth.new(s).to_html).to_html

        	File.open(dest, 'w') { |fh|
        		fh.puts(wiki_header % title)
        		fh.puts(html)
        		fh.puts(wiki_footer)
        	}
        end

        # Copy the stylesheet over
        FileUtils.copy("#{wiki_styles_path}", "#{export_dir}/wiki-styles.css")

        # Open the exported wiki in the default HTML viewer
        front = File.join(export_dir, "IndexPage.html")
        `open #{front}`
    end
   
    # protected instance methods
    
    protected
    
    def pages
        @pages ||= load_pages
        @pages
    end
    
    def load_pages
        extensions = [EXT]
        all_files = Dir.entries(dir)
        all_files.reject! { |fn| File.directory?("#{dir}/#{fn}") }
        all_files.reject! { |fn| ! extensions.include?(File.extname(fn)) }
        all_files.map! { |fn| fn[0..(fn.length-File.extname(fn).length-1)] }
        all_files.sort
    end
    
    def templates_dir
        "#{ENV['TM_BUNDLE_SUPPORT']}/templates"
    end
    
    def wiki_header
        d = File.file?("#{dir}/wiki-header.html") ? dir : templates_dir
        open("#{d}/wiki-header.html", "r").read
    end
    
    def wiki_footer
        d = File.file?("#{dir}/wiki-footer.html") ? dir : templates_dir
        open("#{d}/wiki-footer.html", "r").read
    end
    
    def wiki_styles_path
        d = File.file?("#{dir}/wiki-styles.css") ? dir : templates_dir
        "#{d}/wiki-styles.css"
    end
 
    def with_html_links(s)
        # This match recognises HTML links, and delimited then camelcase
        # pagenames. Each is treated differently
        # $1: HTML capture
        # $2: Delimited capture ($3 is the page name)
        # $4: Camelcase capture
        s.gsub(/(<a .+<\/a>)|(\[\[(.+)\]\])|(\b([A-Z][a-z]+([A-Z][a-z]*)+)\b)/) { |m|
            if $1
                $1
            else
                pagename = $2 ? $2.tr("[]", "").capitalize : $4
                if (!pages.include?(pagename)) and (pages.map { |p| p.downcase }.include? pagename.downcase)
                    pagename = pages.select { |p| p.downcase == pagename.downcase }.first
                end 
                "<a href=\"#{pagename}.html\">#{pagename}</a>"
            end
        }
    end

    # public class methods
    public
    def PlainTextWiki.create_new_wiki        
        # Ask the user for a new wiki directory, exiting if cancelled
        cocoadialog = "#{ENV['TM_SUPPORT_PATH']}/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog"
        dir = `#{cocoadialog} fileselect --text "Choose a directory for your new wiki (IndexPage.txt will be created automatically)" --select-only-directories`.strip
        exit if dir.empty?

        # Exit if IndexPage.txt already exists
        if File.file?("#{dir}/IndexPage.txt")
        	puts "IndexPage.txt already exists here"
        	exit 206
        end

        # Create and populate the index page by copying it from templates
        wiki = PlainTextWiki.new(dir)
        FileUtils.copy("#{wiki.templates_dir}/IndexPage.txt", "#{wiki.dir}/IndexPage.txt")

        # Open this wiki in a project window
        `open -a TextMate "#{dir}"`
        
        # Select the index page
        wiki.go_to_index_page
    end

end