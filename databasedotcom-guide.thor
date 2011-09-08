require 'rubygems'
require 'maruku'

require 'fileutils'

class Guide < Thor
  include FileUtils
  
  SUPPORTED_FORMATS = %w{html latex pdf}
  OUTPUT_DIR = File.join(File.dirname(__FILE__), "output")
  GUIDE_DIR = File.join(File.dirname(__FILE__), "guide")
  GUIDE_FILE_NAME = "databasedotcom-guide"
  OUTPUT_FILE_BASE_NAME = File.join(OUTPUT_DIR, GUIDE_FILE_NAME)

  desc "build [FORMAT]", "Build the guide. FORMAT specifies what format the output should have. Defaults to html. Valid options are: #{SUPPORTED_FORMATS.join(", ")}"
  def build(format = 'html')
    doc = Maruku.new(complete_markdown)
    
    mkdir_p OUTPUT_DIR
    Dir.glob File.expand_path('../{assets,images}/*', __FILE__) do |file|
      cp file, OUTPUT_DIR
    end
    
        
    if SUPPORTED_FORMATS.include?( format )
      self.send("build_#{format}", doc)
    else
      STDERR << "Error: Don't know how to build for format '#{format}'"
      exit 1
    end
    
  end

  desc "clean", "Delete the output directory, along with all contents"
  def clean
    rm_rf OUTPUT_DIR, :verbose => true
  end
  
  private
  
  
  def build_html(doc)
    File.open(OUTPUT_FILE_BASE_NAME + '.html', 'w+') do |file|
      file << doc.to_html_document
    end
  end
  
  def build_latex(doc)
    File.open(OUTPUT_FILE_BASE_NAME + '.tex', 'w+') do |file|
      file << doc.to_latex_document
    end
  end
  
  def build_pdf(doc)
    build_latex(doc)
    
    Dir.chdir(OUTPUT_DIR) do |dir|
      # Run twice to get cross-references right
      2.times { system("pdflatex #{OUTPUT_FILE_BASE_NAME + '.tex'} -output-directory=#{OUTPUT_DIR}") }
    
      # Clean up
      file_patterns = %w{*.aux *.out *.toc *.log}
      file_patterns.each do |pattern|
        FileUtils.rm(Dir.glob(pattern))
      end
    end
  end
  
  def complete_markdown
    # Collect all the markdown files in the correct order and squash them together into one big string
    s = [] 
    File.new("guide-order.txt").each_line do |line|
      line.strip!
      next if line =~ /^#/   # Skip comments
      next if line =~ /^$/   # Skip blank lines

      File.open(File.join(GUIDE_DIR, line)) do |f|
        # I have no idea if the double \n is needed, but seems safe
        s << f.read
      end
    end

    return s.join("\n\n* * *\n\n")
  end

end
