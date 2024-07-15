#!/usr/bin/env ruby


require 'nokogiri'
require 'yaml'
require './portdb.rb'


# Colors class for simplicy less require's
class Colors
	attr_accessor :red
	attr_accessor :green
	attr_accessor :reset
	attr_accessor :yellow
	attr_accessor :blue

	def initialize
		@red = "\033[31m"
		@green = "\033[32m"
		@reset = "\033[0m"
		@yellow = "\033[33m"
		@blue = "\033[34m"

	end

end # End color class

color = Colors.new
bags = {}
ips = []

if !ARGV[0]
  puts
  puts "* No XML File Specified Exiting... *"
  puts
  exit
else
  inputFile = ARGV[0]
end
doc = Nokogiri::XML (File.open(inputFile))

hosts_info = doc.xpath("//host")

# Process Each Host
  hostcount = 0
  hosts_info.each do | host |
    hostcount +=1
        addresses = host.xpath('address')
         addresses.each do | address |
            if address['addrtype'].include? "ipv4"
                @host = address['addr']
                #puts "Processing IP: #{@host}"
            end
         end
#Process each Port on host
    ports = host.xpath('ports')
        ports.each do | port |
             ipports = port.xpath('port')
                 ipports.each do | pid |
                   states = pid.xpath('state')
                    states.each do | state|
                      if state['state'] == 'open'
                        @portid = pid['portid']
                        if bags[@portid].nil?
		                      bags[@portid] = [@host]
	                      else
		                      bags[@portid] << @host
	                      end
                      end
                    end
                 end
	      end
    end
# Create File for each Bag (port)
  bags.each do |key, value|
    File.open(key + ".port", 'a') do |file |
	    value.each do | ip|
		    file.write(ip.to_s + "\n")
	    end
    end
  end
  # End of Processing
  # End Titles
  puts
  puts "Processed #{color.blue}#{hostcount}#{color.reset} hosts from file #{color.blue}#{inputFile}#{color.reset}"
  puts "Found #{color.blue}#{bags.count} #{color.reset}ports"


  ## This is post processing and suggesting scripts to run

  include Portlist
  pList = createlist
  puts "Suggested Scripts to Run:"

  bags.each do |p, value|
      if pList.has_key?(p.to_i)
        puts "Port #{color.blue} #{p}: #{color.reset}"
        pList[p.to_i].each do | hash|
           puts "\t#{hash}"
        end
      end

  end
