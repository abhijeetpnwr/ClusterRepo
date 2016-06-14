# Motive of this script is to keep cheking system for critical temperature situation

import subprocess
import re
import os 

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class processcontroller():
	def runcommand(self,command): 
		p = subprocess.Popen(command,shell=True,stdout=subprocess.PIPE)
		out,err = p.communicate()		
		return out 


EmailBody = " "

pcobj = processcontroller()

compute_results = pcobj.runcommand("/opt/ganglia/bin/ganglia CPU1_Temp")

for line in compute_results.split(os.linesep):
	temp_list = line.split("\t")
	if len(temp_list)>1 and temp_list[1].strip() and int(temp_list[1]) >= 100:
		EmailBody = ''.join(EmailBody)+"Node ",temp_list[0],"Is  critical"+"\n"
	elif len(temp_list)>1 and temp_list[1].strip() and int(temp_list[1]) > 90:
                EmailBody = ''.join(EmailBody)+"Node ",temp_list[0],"Is high"+"\n"

Emailtext = ''.join(EmailBody)

if Emailtext.strip():
	print "I need to send email"
	print subprocess.call('echo \" Dear Admin, \n It seems few nodes are high on temperature. \n \n '+Emailtext+"\" | mailx -v  -s \"Cluster temperature status\" abc@gmail.com", shell=True)
