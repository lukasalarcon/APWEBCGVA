#start the tweek project

#IMPORTS

import xml.sax
import os
import shutil
from urllib2 import Request, urlopen, URLError, HTTPError
from xml.dom.minidom import parse
import xml.dom.minidom
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
			fo = open(newName, "wb")
			fo.write(toSave);
	
			# Close opend file
			fo.close()


		def ReadXML(self, URL):
			req = Request(URL)
			try:
    				response = urlopen(req)
			except HTTPError as e:
    				print 'The server couldn\'t fulfill the request'
    				print 'Error code: ', e.code
			except URLError as e:
    				print 'We failed to reach a server.'
    				print 'Reason: ', e.reason
			else:
    				print "Leyendo Archivo..."	
			    	return response.read()
	
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
				i = i + 1
			return IPv4		


		def CreateUserAgentO365(self,XML):
			
			theText = ""
			IPv4 = self.CreateIPv4List(XML)
			
			for elem in IPv4:
				#myline = "dest_domain=. user_agent=\"" + elem.text +"\" action=allow\n"
                        	self.theText = self.theText + myline
                        	#self.AppendFile(self.home + '\\' + "filter-default.config.tw",self.theText)





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
					O365t.CreateUserAgentO365("o365.xml")
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
        				exit
			



			
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
				myline = "dest_domain=. user_agent=\"" + agent.text +"\" action=allow\n"
				self.theText = self.theText + myline  
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
url = "http://support.content.office.net/en-us/static/O365IPAddresses.xml"
O365t = O365("")	
#val = O365t.ReadXML(url)
#O365t.PrintFile(val)
#O365t.SaveFile(val,"o365.xml")
#oProducts = O365t.ParseO365Names("o365.xml")
#menu = O365t.CreateMenu(oProducts)


print "Tweak"
mymenu = Tweak("tweak.py")
mymenu.TweakMenu()


