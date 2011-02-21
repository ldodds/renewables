require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'hpricot/xchar'

cache_dir = ARGV[0]
if !File.exists?(cache_dir)
  d = Dir.mkdir(cache_dir)  
end

#Map nbsp to spaces
Hpricot::XChar::PREDEFINED_U.merge!({"&nbsp;" => 32})

def process_page(cache_dir, doc)
  #process page and write out links
  doc.search("#mainlist tbody td a").each do |link|
    rid = link.inner_text
    begin
      url = URI.parse( "http://www.ref.org.uk/roc-generators/view.php?rid=#{rid}" )
      puts "Fetching #{url}"
      page_data = url.read
      puts "Writing #{rid}"
      cache_file = File.new( File.join( cache_dir, rid ), "w" )
      cache_file.puts( page_data )      
      cache_file.close()      
      
      url = URI.parse( "http://www.ref.org.uk/roc-generators/view.php?rid=#{rid}&tab=map" )
      puts "Fetching #{url} Map"
      page_data = url.read
      puts "Writing #{rid}-map"
      cache_file = File.new( File.join( cache_dir, "#{rid}-map" ), "w" )
      cache_file.puts( page_data )      
      cache_file.close()      
      
    rescue Errno::ETIMEDOUT
        puts "Timeout!"
    end 
  end
end

url = "http://www.ref.org.uk/roc-generators/"

doc = Hpricot( open(url) )

#Extract number of results
#There are 200 results per page
size = doc.search("div[2]").inner_text.match(/There are currently ([0-9]+) rows in the database/)[1]
size = size.to_i
start = 200

#first page
process_page(cache_dir, doc)

#rest of pages
while start < size
  url = "http://www.ref.org.uk/roc-generators/index.php?mode=client&start=#{start}&order=priority&dir=DESC"
  doc = Hpricot( open(url) )
  process_page(cache_dir, doc)
  start = start + 200
end
