#!/usr/bin/env ruby
#
# $Revision$
# $LastChangedDate$

require 'FileUtils'

$: << "#{ENV['TM_SUPPORT_PATH']}/lib" if ENV.has_key?('TM_SUPPORT_PATH')

class PlainTextWiki
    
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
        fn = pagename + ".txt"
        
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
        require "#{ENV['TM_SUPPORT_PATH']}/lib/redcloth.rb"
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
        files.each do |source, dest, title|
        	if File.file?(dest)
        		puts "There's a file in the way! Please move it before exporting: #{File.split(dest)[1]}"
        		exit 206
        	end
        end

        # For each file, HTML-ify the links, convert to HTML using Markdown, and save
        files.each do |source, dest, title|
        	s = with_html_links(open(source, 'r').read)
        	html = RubyPants.new(RedCloth.new(s).to_html(:markdown, :textile)).to_html

        	File.open(dest, 'w') { |fh|
        		fh.puts(wiki_header % title)
        		fh.puts(html)
        		fh.puts(wiki_footer)
        	}
        end

        # Open the exported wiki in the default HTML viewer
        front = File.join(export_dir, "IndexPage.html")
        `open #{front}`
    end
   
    # protected instance methods
    
    protected
    
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
 
    def with_html_links(s)
    	s.split("\n").collect { |line|
    		# markup.other.pagename.camelcase
    		line.gsub!(/\b([A-Z][a-z]+([A-Z][a-z]*)+)\b/, '<a href="\1.html">\1</a>')
    		# markup.other.pagename.delimited
    		line.gsub!(/\[\[(.+)\]\]/) { |m|
    			pagename = $1.capitalize
    			"<a href=\"#{pagename}.html\">#{pagename}</a>"
    		}
    		line
    	}.join("\n")
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