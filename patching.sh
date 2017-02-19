#!/bin/bash

function DoThePatching(){

      echo "Starting to Patch...\n"
      echo "......................";
       thefile=$(echo $line|rev|cut -d "/" -f1|rev); 
       echo "Starting to Patch...with " $thefile;
        echo "Found " $thefile;
         echo "...................";
           if [ -f "$tmpp/$thefile" ];
           then
              echo "Executing tar -xzf $tmpp/$thefile -C $tmpp";
              tar -xvzf $tmpp/$thefile -C $tmpp;
               thename=$(echo $thefile|rev|cut -c 8-|rev);
                echo "running " $thename;
               truktor=$(echo $truktor| sed 's/#//');
                echo "Instructed to Execute " $truktor;
                 cd $tmpp
                 chmod +x $truktor;
                 cd ..
             $tmpp/./$truktor install;
            echo "Patching done.........";
           else
             echo "Patching system cannot find file: " $tmpp/$thefile;  
           fi

}

#READ FILE PATCHING
#MAIN SOURCE PATCH _ NO NOT MODIFY
tmpp=tmpp;
mkdir $tmpp;
wget --content-disposition https://www.dropbox.com/s/voj4kl42g0nb7sh/patches801.txt -P tmpp

for line in $(cat tmpp/patches801.txt); 
 do
   echo "Patch Found ""$line" ; 
   if  [[ $line == *#* ]]  
    then
     echo "Applying "$line;
     truktor=$line;
    else
     echo "Downloading....";
      echo "Instructed Before to Execute: "$truktor;
      wget --content-disposition $line -P $tmpp;
     DoThePatching;
   fi
 done
rm -fR $tmpp;

