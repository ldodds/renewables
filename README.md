This code crawls the Renewable Energy Federation website, scraping the ROC database available 
from:

[http://www.ref.org.uk/roc-generators][0]

The code builds a local cache of the pages which it then scrapes to generate an RDF model.

AUTHOR
------

Leigh Dodds (leigh@kasabi.com)


INSTALLATION
------------

The code is written in Ruby and relies on the Hpricot gem for parsing the HTML files, and 
the RDF.rb library for serializing the RDF as ntriples.

After downloading the code, run the following to pull in the required dependencies:

	sudo gem install hpricot rdf

USAGE
-----

A Rakefile is provided to run the converson.

To build a local cache of the datbase in data/cache run:

	rake cache

The file names are derived from the OFGEM identifier for the ROC installation.

To convert the files into RDF run:

	rake scrape
	
To run both the caching and conversion steps run:

	rake convert
	
It is recommended that when iterating over changes to the data model, that you run only the "scrape" 
stage repeatedly. This avoids unnecessary traffic to the REF website. 

The converted output is stored in data/nt as a single NTriples file.

There is also a script that can be used to dump an individual file. Useful for debugging:

	ruby bin/dump_generator data/cache/R00019SESC
	
DATA MODEL
----------

The code generates the following model from the cached web pages.

Every record in the database is modelled as a Generator.

A Generator has an Address.

A Generator may also have a Site Owner, Developer, and an Operator

A Generator may also have a Wind Turbine Installation

[0]: [http://www.ref.org.uk/roc-generators]