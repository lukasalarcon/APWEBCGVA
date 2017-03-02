#start the tweek project

#IMPORTS

import xml.sax
import os
import shutil
import time
from urllib2 import Request, urlopen, URLError, HTTPError
from xml.dom.minidom import parse
import xml.dom.minidom
import sys

try:
	import xml.etree.cElementTree as ET
except ImportError:
	import xml.etree.ElementTree as ET
#try:
	import pacparser
#except 
#	print "Please, compile pacparser into python"



#Class
class O365:
		def __init__(self, Name):
			self.ProductName = ""

		def ReadFile(self, theFile):
			Fo = open(theFile,"wb")
			str = Fo.read(100)
			return str
			Fo.close()

		def PrintFile(self, toPrint):
			print toPrint

		def SaveFile(self,toSave,newName):
			# Open a file
			try:
				fo = open(newName, "wb")
			except IOFile as e:
				self.PrintFile("Error open File toRead" + e.code + e.reason)
				return 0
			try:		
				fo.write(toSave);
			except IOFile as e:
				self.PrintFile("Error wrinting file" + e.code + e.reason)
				return 0
	
			try:
				# Close opend file
				fo.close()
			except IOFIle as e:
				self.PrintFile("Error Closing File" + e.code + e.reason)

			#Total success to Save File
			return 1
 

		def ReadXML(self, URL):
			req = Request(URL)
			bufferlc = ""
			try:
    				response = urlopen(req)
			except HTTPError as e:
    				print 'The server couldn\'t fulfill the request'
    				print 'Error code: ', e.code
				return 0
			except URLError as e:
    				print 'We failed to reach a server.'
    				print 'Reason: ', e.reason
				return 0
			else:
    				print "Reading File Buffer"
			    	bufferlc =  response.read()
				
			if self.SaveFile(bufferlc,"o365.xml"): 
				#Total Success in Reading and saving File
				return 1
			else:
				return 0



	
		def ParseO365Names(self, XML):
			DOMTree = xml.dom.minidom.parse(XML)
			collection = DOMTree.documentElement
			menu = {}
			i = 0	
			if collection.hasAttribute("o365"):
   				print "Root element : %s" % collection.getAttribute("o365")
			
			# Get all the products in the collection
			oProducts = collection.getElementsByTagName("product")


			#DEBERIA RETORNAR oProducts

			# Print detail of each Product.
		 	return oProducts 


		def CreateMenu(self,oPrd):
			menu = {}
			i = 0
			for product in oPrd:
				if product.hasAttribute("name"):
					print "Title: %s" % product.getAttribute("name")
					menu[i] =  product.getAttribute("name")
					i = i + 1
			return menu



		def CreateIPv4List(self,XML):
		

			IPv4 = {} 
			i = 0
			tree = ET.ElementTree(file = XML)	
			for elem in tree.iterfind('product/addresslist[@type="IPv4"]/address'):
				IPv4[i] = elem.text
				#print elem.text, IPv4[i]
				i = i + 1
			return IPv4		

		def AppendFile(self,theFile,theText):
			#print "Append FIle...!"
                        try:
				#print theFile
			 	fo = open(theFile, "a")

			except ExceptionI: 
				print "Failed to Open File"
				return 0

			try:
                        	fo.write(theText)
                        	fo.close()
			except ExceptionI:
				print "Failed to Write File!"
				return 0
			
			return 1



		def CreateUserAgentO365(self,XML):
			
			IPv4 = {}
			self.theText = ""
			self.myline = ""
			IPv4 = self.CreateIPv4List(XML)
			self.i = 0
			self.theText = "#:.START\n"	
			self.theText = self.theText + "#:." + time.asctime( time.localtime(time.time()) ) +"\n"
			for elem in IPv4:
				self.myline = 'dest_ip=' + IPv4[self.i] + ' user_agent=' + ' action=allow\n'
                        	self.theText = self.theText + self.myline
				self.i = self.i + 1
			#print self.theText
			self.theText = self.theText + "#:. " + time.asctime( time.localtime(time.time()) )+ "\n"
			self.theText = self.theText + "#:.END\n" 
			
			return self.theText
	
			


		def TransactOperateO365(self,XML,ConfigFile):

			self.FilterConfig = ""	
	
			if self.GetXMLFile():
				print "Got File!. Keep on Working!"
			else:
				print "Couldn't get the Microsoft File. Aborting Operation"

			self.FilterConfig = self.CreateUserAgentO365(XML)

			if not self.DeleteOldLines(ConfigFile):
                                        return 0
			
			if not self.AppendFile(os.getcwd() + '/' + ConfigFile,self.theText):
					return 0

			return 1

		def GetXMLFile(self):
		
			self.URL = "http://support.content.office.net/en-us/static/O365IPAddresses.xml" 
			self.ret = 0
			self.lcFileName = "o365.xml"

			#Wait for Success in Reading XML
			self.ret = self.ReadXML(self.URL)		

			return self.ret


		def DeleteOldLines(self,ConfigFile):
			self.del_line = 0	
			self.start_line = 0
			self.end_line = 0
			self.counter = 0
			self.found = 0
			
			self.PrintFile("Reading Old Config File:" + ConfigFile)	
			
			try:
				with open(ConfigFile,"r") as textobj:
					self.list = list(textobj)
					#print self.list
			except IOFile as e:
				self.PrintFile("Can't open " + ConfigFile + " " + e.reason)
				return 0

			for line in self.list:
				#print line
				if line == "#:.START\n":
					self.start_line = self.counter
					self.found = 1
					self.PrintFile("Detecting START in old file line at: " + str(self.start_line))
					
				if self.found == 1:
					print "Deleting " + self.list[self.counter]	
					del self.list[self.counter]


				if line == "#:.END\n":
                                       self.end_line = self.counter
				       self.PrintFile("Detecting END line at: " + str(self.end_line))
				       break 
				self.counter = self.counter + 1
			
			self.PrintFile("Detecting LENGHT: " + str(len(self.list)))


			try:

				if self.found == 1:
					self.PrintFile("Saving File with excluded lines:" + ConfigFile)
					with open(ConfigFile,"w") as WriteFile:
						for n in self.list:
							print "IMPRIMIENDO " + n
							WriteFile.write(n)			
			except IOFile as e:
				self.PrintFile("Can't close " + ConfigFile + " " + e.reason)
				return 0

			return 1















class Tweak:

		menuT = {}
		theText = ""
		home = ""
		def __init__(self,home):
                       	print "Creating Objets for Tweaking Project\n" 
			self.menuT = ""
			self.theText = ""
			self.home = home


		def TweakMenu(self):
			
			O365t = O365("tweak.py")
			myinput = ""			
			print "Printing the menu:"	
			while myinput != "5":
				self.menuT = {1:'User-Agents Bypass',2:'User-agent O365 Bypass',3:'Performance',4:'PAC',5:'O365 PAC Exceptions',6:'Exit'}
				print "Choose an option\n"
				options = self.menuT.keys()
				options.sort()
				for entry in options:
					print entry,self.menuT[entry]
				myinput = raw_input()
				try:
					val = int(myinput)
				except ValueError:
					print("Please, enter a number!")	
				if myinput == "1":
        				print "Generating User-Agents Exceptions"
        			        self.CreateUserAgents()	
				if myinput == "2":
					print "Generating O365 User-Agent Exceptions"
					O365t.TransactOperateO365("o365.xml","filter-default.config.tw")
    				if myinput == "3":
        				print "Modifying Performance Values"
        			        self.Perfo()	
    				if myinput == "4":
        				print "PAC Files"
					self.PAC()
    				if myinput == "5":
        				print "Generating O365 PAC Exceptions"
    				if myinput == "6":
        				print "Thanks for using Tweak Project"
        				exit()
			



			
		def CreateUserAgents(self):
			
			os.system("wget --content-disposition https://www.dropbox.com/s/6bw3jntb93og2iu/user-agents.xml -P .") 
			#tree = ET.parse(self.home + '\' + 'user-agents.xml')
			tree = ET.ElementTree(file='user-agents.xml')
			root = tree.getroot()
			
			filter = self.home + "\\" + "filter-default.config"
			newfilter = "filter-default.config.tw"
			
			#shutil.copy(self.home + "\" + filter, newfilter)			
			shutil.copy(filter, newfilter)			

			for agent in root.findall("./agents/useragent"):
			        print agent.text 
				self.myline = "dest_domain=. user_agent=\"" + agent.text +"\" action=allow\n"
				self.theText = self.theText + self.myline  
			self.AppendFile(self.home + '\\' + "filter-default.config.tw",self.theText)	


		def copyFile(self,src, dest):
    			try:
        			shutil.copy(src, dest)
				return 1
    			# eg. src and dest are the same file
    			except shutil.Error as e:
        			print('Error: %s' % e)
				return 0
    			# eg. source or destination doesn't exist
    			except IOError as e:
        			print('Error: %s' % e.strerror)
                        	return 0
               
		def AppendFile(self,theFile,theText):

			fo = open(theFile, "a")
			fo.write(theText)
			fo.close()


		def Perfo(self):
			if (os.path.isfile("/opt/WCG/bin/content_line")):
				print("Modifying WCG values")

				print ("Modifying Chunking\n")

				os.system("/opt/WCG/bin/./content_line -s proxy.config.http.chunking_enabled -v 0")
				print ("Modifying SHA from Low to High\n")	
				os.system("/opt/WCG/bin/./content_line -s proxy.config.ssl.cas_server.pki_ca_digest -v SHA256")
				print ("Modifying HTTP11\n")
				os.system("/opt/WCG/bin/./content_line -s proxy.config.http.send_http11_requests -v 1")
				print ("Modifying TimeOut Values\n")
				os.system("/opt/WCG/bin/./content_line -s proxy.config.http.connect_attempts_timeout -v 60")
			else:
			 	print("WCG Binaries not found\n")	
			

		def replace_all(self, text, dic):
    			for i, j in dic.iteritems():
        			text = text.replace(i, j)
    			return text

			
		def PAC(self):

			 
			
			print ("Please, add your main Internal Domain:\n")
			myinput = raw_input()
			
		  	print ("Please, add your proxy name:\n")
			myproxy = raw_input()	
					
			replacements = {'{DOM}':myinput, '{PROXYV}':myproxy}
			lines = []
			with open('p.pac') as infile:
    				for line in infile:
					aux = self.replace_all(line,replacements)
					lines.append(aux)


			with open('proxy.pac', 'w') as outfile:
    				for line in lines:
        				outfile.write(line)			
			
			self.copyFile(self.home + '\\' + "proxy.pac", self.home +'\\' + "wpad.dat")

			print ("Proxy Pac Created\n")
			pacparser.init()
			pacparser.parse_pac('proxy.pac')
			print "Testing Proxy with PACPARSER project\n"
			print ("Testing some URL to get PAC behavior\n")
			prox = pacparser.find_proxy('http://www2.manugarg.com', 'www2.manugarg.com')
			print prox
			print pacparser.just_find_proxy("proxy.pac", "http://www2.manugarg.com")
			print ("Do you like to replace WCG wpad.dat and proxy.pac?(y/n)\n ")
			myinput = raw_input()
			if myinput == "y":
				self.copyFile("proxy.pac","/opt/WCG/config/proxy.pac")
				self.copyFile("wpad.dat","/opt/WCG/config/wpad.dat")
				print ("Copy Done\n")


	
				
#MAIN CLASS
print "Starting: Tweak Project\n"

print "Under AS-IS Agreement\n"

print "Strong suggest to be an Qualified Forcepoint Personal\n"
O365t = O365("")	
#val = O365t.ReadXML(url)
#O365t.PrintFile(val)
#O365t.SaveFile(val,"o365.xml")
#oProducts = O365t.ParseO365Names("o365.xml")
#menu = O365t.CreateMenu(oProducts)

################
print len(sys.argv)

if len(sys.argv) > 1:
	print "Found Arguments. Go to Menu\n"
	print sys.argv[1:]

if sys.argv[1:] == 2:
	print "Argument" + sys.argv[1:]

################


print "Tweak"
mymenu = Tweak("tweak.py")
mymenu.TweakMenu()


