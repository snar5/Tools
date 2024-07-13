##
# A ruby program to provide some small functions to lookup information about websites 
# I found it useful in cases where dirb or DirBuster would error out. 
#  
# Author: mthorburn 12/29/2014 
#
# Requires gem whois and ipaddr 
# 
## 

require 'nokogiri'
require 'rubygems'
require 'uri'
require 'openssl'
require 'net/https'
require 'getopt/long'
require 'thread'
require 'ipaddr' 


def usage()

	puts "Usage:\n "
	puts " ruby rbGetInfo.rb [options]"
	puts ""
	puts "Main 'modes'" 
	puts " --title           Grabs title and response  information for a selected IP and can return hearder with -e option"
	puts " --direnum         Will cycle through a list of directories and return a code *dirbuster-ish*"
	puts "\n" 
	puts "title options --title\n"
	puts " --host   '-h'	 Do a single lookup for one host"
	puts " --file   '-f'	 Use a file for host (ip) input will grab a title for each page"
	puts " --out    '-o'	 output to a file (and onscreen) "
	puts " --ssl    '-s'	 Uses SSL for connection "
	puts " --expand '-e'	 Include headers from request"
	puts "\n\tex. rbGetInfo.rb --title -h google.com \n\n"
	puts "direnum options --direnum\n"
	puts " --host    '-h'	 Do a single lookup for one host "
	puts " --basedir '-b'	 The base directory to start "
	puts " --file    '-f'	 Use a file for directory inputs"
	puts " --ssl     '-s'	 Use an SSL connection" 
	puts " --out     '-o' 	 Output to a file " 
	puts "\n\tex. rbGetInfo.rb --direnum -h google.com --basedir /images --output list.out\n\n"
	puts "\n "
	return 


end
def getargs
	color = Colors.new()
	if ARGV.length == 0
	       	usage	
		exit 0
	end 
	include Getopt
	begin	
	opt = Long.getopts(
		["--title", OPTIONAL],
		["--direnum", OPTIONAL],
    		["--host", "-h", REQUIRED],
		["--ssl", "-s",BOOLEAN],
		["--expanded","-e",BOOLEAN],
		["--file","-f",REQUIRED],
		["--port","-p",REQUIRED],
		["--basedir","-b",REQUIRED],
		["--out", "-o",REQUIRED],
		["--whois", OPTIONAL],
		["--domain", "", REQUIRED],
		["--net", "", REQUIRED],
		["--type",REQUIRED],
		["--name", REQUIRED],
		["--pocid",REQUIRED],
		["--help",OPTIONAL]
		)
	rescue Exception => e 
	#	usage 
		puts e
	
		exit 
	end 
	return opt

end 

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


def out_to_file(response,outfile)
	puts "Wrote #{response}"
	output = File.open(outfile,"a")
	output.write(response)
	output.close 

end # End of output_to_file 

class Request

	attr_reader :file_formatted, :response , :success, :responsebody 

	def initialize (aURL, aSSL, aExpanded,aPort=80,aBaseDir)
		begin
			@url = aURL
			@ssl = aSSL
			@incheader = aExpanded
			@responsebody  = '' 
			@response = ''
			@basedir = aBaseDir
			@basedir = @basedir.nil? ? "/" : aBaseDir
			if @ssl 
				@port = 443 
				@header = 'https://'
			else 
				@port = aPort
				@header = 'http://'
			end 
	
		rescue
			puts "Error during request setup stage: " << e.message
		end 
	end 
	def send
		full_path = @header << @url << @basedir
		uri = URI.parse(full_path) 
		http = Net::HTTP.new(uri.host, @port)
		request = Net::HTTP::Get.new(uri.request_uri)
                request["User-Agent"] ="Mozilla/5.0"
                request["Connection"] = "keep-alive"
                request["Content-Type"] = "application/x-www-form-urlencoded"
		if @ssl then 
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end 
		http.open_timeout = 10  # Wait for Client to respond 
		begin
			response = http.request(request)
		rescue
			@response = "\033[31mConnection Error: Couldn't Connect to  #{@url}:#{@port}#{@basedir} \033[0m" 
			@success = false 
			return
		end

		case response
			when Net::HTTPSuccess, Net::HTTPRedirection	
				doc = Nokogiri::HTML(response.body)
				title = doc.css('title').text unless doc.css('title').text.nil? 	
				@response += "\033[32m[+] [#{response.code}] Host: #{@url}:#{@port}#{@basedir}:\033[34m #{title} \33[0m\n"
				@file_formatted  = "[#{response.code}] Host: #{@url}:#{@port}#{@basedir}:" << title << "\n"
				if @incheader then 
					response.each do |x|
						@response += "  " + x + ": " << response[x] << "\n"
						@file_formatted += "  " + x + ": " << response[x] << "\n" 
					end 
				end	
				@success = true
				@responsebody = response.body 

			when Net::HTTPUnauthorized,Net::HTTPNotFound
				@response = "\033[33m[-] Host:  #{@url}:#{@port}#{@basedir}: #{response.code}:#{response.message}\033[0m"
				@file_formatted = "Host:  #{@url}:#{@port}#{@basedir}: #{response.code}:#{response.message}\n"
				@success = true

			else
				@response = "\033[31m #{response.code} No Response from host: #{@url}:#{@port}#{@basedir} \033[0m" 
				@file_formatted = "No Response from host: #{@url}:#{@port}#{@basedir}\n"
		end
	end




end # End of Request Class l
#########################################################################################
#                                                                                       #
# Get Title of Webpage and header information (Optional) input/output to file (Optional)#
#                                                                                       #
#########################################################################################

def getTitle(options)


site = nil
expand = false
port = 80
basedir='/'
output = false
input = nil
ssl = false 
filein = 'file.in'
fileout = 'file.out' 


options.each do | opt, arg| 
	case opt
		when "host"
			site = arg
		when "ssl"
			ssl = arg
		when "port"
			port = arg
		when "output"
			output = arg
		when "file"
			input = arg
		when "out"
			fileout = arg 
		when "basedir"
			basedir = arg 
		
	end 
end

#Check to make sure we have either site or input file
 if site.nil? 
	if input.nil?  
	 	puts "No Site or File Specified!\n\n"
	 	exit	
	end
 end
#Check to make sure we don't have both 
 if !site.nil? && !input.nil?
	puts "Please check your options you can only have a host OR a file input!\n\n"
	exit
 end
		
#Setup Local Count Variables to return 
 	total_requests = 0 
	counts = 0 

  if !input # Single Request
	req = Request.new(site,options["ssl"],options["expanded"],options["port"],options["basedir"])
	req.send
        total_requests += 1           
        if req.success
              if fileout
                 out_to_file(req.file_formatted, fileout)
              end
              puts req.response
              counts += 1
         else
              puts "Something Happened, couldn't connect"
              puts req.response
         end

  else # Input hosts from file 
	begin
         File.foreach(input) {|x|
               req = Request.new(x.strip,ssl,options["expanded"],port,basedir)
               req.send
               total_requests += 1
               if req.success
                  if fileout
			 out_to_file( req.file_formatted, fileout) 
               	  end
               	  puts req.response
                  counts += 1
               end
	       if not req.success 
		  puts req.response
	       end 
		}
	rescue Exception => e 
		puts "Error reading file input: #{e}" 
	end 
  end 
	return counts,total_requests 
end

#########################################################################################
#                                                                                       #
# Enumerate Directories from file or individually                                       #
#                                                                                       #
#########################################################################################
def direnum(options)
	total_requests = 0
 	counts = 0

 	if options["file"] then
                 File.foreach(options["file"]) {|x|
		  	basedir = "/" << x.strip 
                 	
			req = Request.new(options["host"],options["ssl"],options["expanded"],options["port"],basedir)
                  req.send
                  total_requests += 1
                  if req.success
                         if options["out"]
                                if File.owned?(options["out"])
                                        output = File.open(options["out"], "a")
                                        output << req.response
                                        output.close
                                else
                                         output = File.open(options["out"], "w")
                                         output << req.response
                                         output.close
                                end
                         end
                         puts req.response
                         counts += 1
                  end
                  if not req.success
                        puts req.response
                  end
                         }
         else

                 req = Request.new(options["host"],options["ssl"],options["expanded"],options["port"],options["basedir"])
                 req.send
                 total_requests += 1

                         if req.success
                                 if options["out"]
                                         out_to_file(req.file_formatted, options["out"])
                                 end
                                 puts req.response
                                counts += 1
                         end
                        if not req.success
                                puts "Something Happened, couldn't connect"
                                puts req.response
                        end

         end

        return counts,total_requests
 
	
end
 
def display_banner
	system("clear")
	puts "\033[31m
--------------------------------------------

Get Title and Header information (-e) 

--------------------------------------------- 
	\n\033[0m"

end

def start
	counts = 0 
	total_requests = 0 
	display_banner

	options = getargs # Get Command line options 
	    options.each do | opt, arg|
		case opt
		when "title"
	 	counts,total_requests = getTitle(options)
		when "direnum"
		counts,total_requests =  direnum(options)
		when "help"
		usage
		end
    	end
	
end 


# Start of the main program 				
start		


