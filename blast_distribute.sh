#!/bin/bash

#echo $a ;
#echo $b ;

user=`whoami`
my_home=`echo $HOME`
blastprogram="blastn"
echo "" >"logfile"

date >>"logfile"

fltr=`cut -d '=' -f 1 <<< $1`

if [ "$fltr" = "-i" ] 
then

input_file_path=`cut -d '=' -f 2 <<< $1`

echo $input_file_path;

else 

echo "You missed to provide input file for processing";

exit 1

fi

#cut -d '=' -f 2 <<< $1


#echo $1

if [[ $input_file_path == /* ]]

then

echo "This is path not direct file";

filename=`echo ${input_file_path##*/}`;
echo "Filename is: " $filename;

else

echo "This is a direct file";
filename=$input_file_path;
echo "Filename is: " $filename ;

fi

sequence=`grep -c ">" $filename`

mod=`expr $sequence % 27`

seqs=`expr $sequence / 27`


if [ $mod == 0 ]
then
   echo "No need to approximate "
fi

if [ $mod != 0 ]
then
   echo "Need to approximate sequence per count"
   seqs=`expr $seqs + 1`
fi

echo "Total seqs are $seqs"

timestamp=`date +%b%d%H%M`;

createdirectory=$filename-$timestamp-temp-files;

echo "creating temporary directory now"

mkdir $createdirectory

if [ $(echo $?) == "0" ]

then

echo "directory created successfully !!"

else 

echo "There is some probelm while creating directory. Termination now."
rm -rf $current_directory/$createdirectory
exit 0

fi

echo "Starting fasta file breakup procedure!"


current_directory=`pwd` ;

echo "Sequences in a file : $seqs"

/opt/system_packages/exprmntl_stuff/split_multifasta.pl -i=$input_file_path --seqs_per_file=$seqs -o=$current_directory/$filename-$timestamp-temp-files

if [ $(echo $?) == "0" ]

then

echo "Fragmentation successfull !!"

else

echo "There is some probelm while dividing fasta file. Terminating now."

rm -rf $current_directory/$createdirectory

rm -rf $current_directory/$filename-$timestamp-temp-files

exit 0

fi

ls $current_directory/$filename-$timestamp-temp-files > $current_directory/$filename-$timestamp-temp-files/fragment_list.txt ;

if [ $(echo $?) == "0" ]

then

echo "Fragment list written to file !!"

else

echo "There is some probelm while writing fragment list to file. Terminating now."

rm -rf $current_directory/$createdirectory

rm -rf $current_directory/$filename-$timestamp-temp-files

exit 0

fi
 
echo "Processing fragment file"

sed -i '/fragment_list.txt/d' $current_directory/$filename-$timestamp-temp-files/fragment_list.txt ;

if [ $(echo $?) == "0" ]

then

echo "File Processing Succesful !!"

else

echo "There is some problen in file processing. Terminating now."

rm -rf $current_directory/$createdirectory

rm -rf $current_directory/$filename-$timestamp-temp-files

exit 0

fi


counter=0;
filecounter=1;

filecounter=1;
counter=0;

NOW=$(date)
echo "Starting time is: $NOW" | tee -a "logfile"

read -e -p "Enter database to search, For e.g. nr etc: " db

echo -e "\nYou entered $db database\n" | tee -a "logfile"


read -e -p "Enter any additional parameters for blast search in given format
Format to enter parameters is: -parameter1 value parameter2 value.
For a list of all supported parameters visit following link; http://www.biomedcentral.com/content/supplementary/1471-2105-10-421-S1.PDF" addparameters

echo -e "\nYou entered following parameters $addparameters \n" | tee -a "logfile"

echo -e "Formulated the command as\n" | tee -a "logfile"

echo -e "$blastprogram -query $filename -num_threads $noofthreads -outfmt $outfmt -db $db -e $evalue -max_target_seqs $maxtrgtseqs $addparameters -out $filename-out-$timestamp.txt\n" | tee -a "logfile"

#read -e -p "Are you sure you want to start blast search with above mentioned command. Enter (y/n): " choice

#while true 

date >>"logfile"


echo -e "\n##################################################"
echo -e "Intiating command execution on compute nodes";
echo -e "##################################################\n"

echo "Startign time for submiittng on cluster :" >>"logfile"

while read line

do

if [ "$counter" -eq 25 ]
then
    echo "skipping compute-0-25 for now";
    counter=$[counter+1];
fi



echo " WILL SSH COMPUTE NODE: $counter"

#ssh -n -f compute-0-$counter "sh -c '/opt/ncbi-blast-2.2.29/bin/$blastprogram -task blastn  -query $current_directory/$filename-$timestamp-temp-files/$filecounter.fsa -db  SRR2952625.fasta -num_threads $noofthreads -evalue $evalue -outfmt \""6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs qcovhsp qlen slen"\" -max_target_seqs $maxtrgtseqs -out $current_directory/$filename-out-$timestamp-$counter.out'"

ssh -n -f compute-0-$counter "sh -c '/opt/ncbi-blast-2.2.29/bin/blastn -task blastn -query $current_directory/$filename-$timestamp-temp-files/$filecounter.fsa -db SRR2952625.fasta -num_threads 16 -evalue 10 -outfmt  \"6  qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs qcovhsp qlen slen\"  -max_target_seqs  2000000 -out $current_directory/$filename-out-$timestamp-$counter.out'" 

echo "excecute successfully"



filecounter=$[filecounter +1];
counter=$[counter+1] ;

#compute - node 25 is down so we need to skip that 
#counter=$[counter+1] ;

done < $current_directory/$filename-$timestamp-temp-files/fragment_list.txt

#else if [ "$choice" = "n" ];

#then 

#echo "Terminating"

echo -e "\n##########################################################"
echo -e "Initiating Deamon mode. Script will now check periodically for completed blast results.\nYou may continue other work."
echo -e "##########################################################\n"

tasks_finished=0;
#counter=0;

while true

do 

tasks_finished=0;

#echo "------- ReDaemon checl : Total tasks finished : $tasks_finished"

for ((k=0;k<=24;k++))
do
stat=`ssh compute-0-$k ps aux | grep $blastprogram | grep $user` ;
if [[ ! -n "$stat" ]];
then
tasks_finished=$[tasks_finished+1] ;
fi
done #this for loop ends

for ((k=26;k<28;k++))
do
stat=`ssh compute-0-$k ps aux | grep $blastprogram | grep $user` ;
if [[ ! -n "$stat" ]];
then
tasks_finished=$[tasks_finished+1] ;
fi

done #2nd for loop ends


if [ "$tasks_finished" -gt 26 ]; then
        echo " -------------- IT SEEMS , ALL TASKS FINIHED -------------"
        break
fi

echo "------- ReDaemon checl : Total tasks finished : $tasks_finished"


done #external while ends

echo "No. of tasks finished are: $tasks_finished"

if [ $tasks_finished -ge 27 ];
then
echo -e "\n#######################"
echo -e "Processing output files"
echo -e "#########################"

cat *.out > merged_`date +%d%m%Y%H%M`.txt

fi



if [ $tasks_finished -ge 27 ];
then
echo -e "\n#####################################"
echo -e "File processing complete. Cleaning temporary files"
echo -e "#######################################"

rm *.out

fi

date >>"logfile"

