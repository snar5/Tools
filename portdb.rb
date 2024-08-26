
module  Portlist
    def createlist()
        portlist = {}
        portlist = {

            21 =>['ftp.py'],
            22 =>['tel-ssh.py'],
            23 =>['tel-ssh.py'],
            139 =>['smb.py','netbios.py'],
            389 =>['ldap.rb'],
            445 => ['smb.py','enum4linux.py'],
            3389 => ['bluekeep.py'],
            8080 => ['tomcat.py']
    
    }
        return portlist
    end 
end 