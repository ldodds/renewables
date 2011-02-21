require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'pho'

BASE_DIR="data"

CACHE_DIR="#{BASE_DIR}/cache"
DATA_DIR="#{BASE_DIR}/nt"

STATIC_DATA_DIR="etc/static"

CLEAN.include ["#{DATA_DIR}/*.nt"]

task :download do
 sh %{ruby bin/cache_roc_database.rb #{CACHE_DIR}}
end

task :convert_locations do
 sh %{ruby bin/convert.rb #{CACHE_DIR} #{DATA_DIR} }
end

task :convert_static do
    Dir.glob("etc/static/*.ttl").each do |src|
      sh %{rapper -i turtle -o ntriples #{src} >#{DATA_DIR}/#{File.basename(src, ".ttl")}.nt}
    end
end

task :convert => [:download, :convert_locations, :convert_static]

