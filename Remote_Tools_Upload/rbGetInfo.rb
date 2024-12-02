     
##
# A ruby program to provide some small functions to lookup information about websites 
# I found it useful in cases where dirb or DirBuster would error out. 
#  
# Author: mthorburn 12/29/2014 
# Updated in 2024 ten years wow
# 
## 


require 'rubygems'
require 'uri'
require 'openssl'
require 'net/https'
require 'thread'
require 'ipaddr' 
require 'optparse'


def usage()

	puts "Usage:\n "
    puts
	puts " ruby rbGetInfo.rb [options]"
    puts
	puts " -h --host  Do a single lookup for one host"
	puts " -i --file  Use a file for host (ip) input will grab a title for each page"
	puts " -o --out   Output to a file (and onscreen) "
	puts " -s --ssl   Uses SSL for connection "
    puts " -p --port  Port to Use"
	puts "\n\tex. rbGetInfo.rb -h google.com -s -o output.txt\n\n"
	return 


end
def getargs
	color = Colors.new()
	if ARGV.length == 0
	       	usage	
		exit 0
	end 

	begin	
    options = {}
        OptionParser.new do |opt|
        opt.banner = "Usage: rbGetTitle.rb [options]"
          opt.on('-h', '--host HOST','single host') { |o| options[:HOST] = o }
          opt.on('-i', '--[no-]input_file INPUTFILE', 'filename') { |o| options[:INPUTFILE] = o }
          opt.on('-p', '--port PORT', 'port number') { |o| options[:PORT] = o }
          opt.on('-o', '--outfile OUTFILE', 'output file') { |o| options[:OUTFILE] = o }
          opt.on('-s', "--[no-]ssl", 'use ssl') { |o| options[:SSL] = o }
        end.parse!
	rescue Exception => e 
		usage 
		puts e
		exit 
	end 
	return options
    
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
	output = File.open(outfile,"a")
	output.write(response)
	output.close 

end # End of output_to_file 

class Request

	attr_reader :file_formatted, :response , :success, :responsebody 

	def initialize (aURL, aSSL,aPort=80)
		begin
			@url = aURL
			@ssl = aSSL
			@responsebody  = '' 
			@response = ''
            @port = aPort
			if @ssl
				@header = 'https://'
			else 
				@header = 'http://'
			end 
         
            
		rescue Exception => e 
			puts "Error during request setup stage: " << e.message
		end 
	end 
	def send
		full_path = @header << @url 
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
			@response = "\033[31mConnection Error: Couldn't Connect to  #{full_path}:#{@port} check port and protocol.  \033[0m"
			@success = false 
			return
		end

		case response
			when Net::HTTPSuccess, Net::HTTPRedirection	
				doc = Nokogiri::HTML(response.body)
				title = doc.css('title').text unless doc.css('title').text.nil? 	
				@response += "\033[32m[+] [#{response.code}] Host: #{@url}:#{@port}#{@basedir}:\033[34m #{title} \33[0m\n"
				@file_formatted  = "[#{response.code}] Host: #{@url}:#{@port}#{@basedir}:" << title << "\n"
				
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




end # End of Request Class


def getTitle(options)

# Local Variables 
    site = nil
    port = 80
    output = false
    input = nil
    ssl = false 
    inputfile = ''
    outputfile = '' 

#Parse Command line options 
    options.each do | opt, arg| 
	    case opt.to_s
		    when "HOST"
			    site = arg
		    when "ssl"
			    ssl = arg
		    when "PORT"
			    port = arg
		    when "OUTFILE"
			    outputfile = arg
		    when "INPUTFILE"
                inputfile = arg
            when "SSL"
                ssl = arg
	        end 
    end

#Check to make sure we have either site or input file
 if site.nil? 
	if inputfile.nil?  
	 	puts "No Site or File Specified!\n\n"
	 	exit	
	end
 end
#Check to make sure we don't have both 
 if !site.nil? && !inputfile.nil?
	puts "Please check your options you can only have a host OR a file input!\n\n"
	exit
 end
		
#Setup Local Count Variables to return 
    total_requests = 0 
    counts = 0 

  if inputfile.nil?  # Single Request
    puts "Running Single Request "
	req = Request.new(site,ssl,port)
	req.send
        total_requests += 1           
        if req.success
              puts req.response
              puts
              counts += 1
        else
              puts "Something Happened, couldn't connect"
              puts req.response
              puts
        end

  else # Input hosts from file 
    
    if !File.file?(inputfile) 
        puts "Oops, can't open the file, #{inputfile}"
        usage 
        exit 
    else 
	    begin
            puts "Running from file #{inputfile}"
            allrequests = 0 
            File.foreach(inputfile) {|x|
                req = Request.new(x.strip,ssl,port)
                req.send
                total_requests += 1
                if req.success
                    if outputfile.length > 0
			            out_to_file( req.file_formatted, outputfile ) 
               	    end
               	    puts req.response
                    counts += 1
                end
	            if not req.success 
		            puts req.response
	            end 
            allrequests +=1 
		    }
	    rescue Exception => e 
		    puts "Error reading file input: #{e}" 
	    end 
    end 
  end 
	return allrequests,counts,total_requests 

end


 
def display_banner
	system("clear")
	puts "\033[31m
    Grabbing Website(s) Titles
	\n\033[0m"

end

def start
	counts = 0 
	total_requests = 0 
	display_banner

	options = getargs # Get Command line options 
	allrequests,counts,total_requests = getTitle(options)
	puts ""
    puts "Finished collecting #{counts} website(s) out of #{allrequests} attempted."
end 


# Start of the main program 				
start		

