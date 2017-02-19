#set -x
FILE="results.txt"
#echo $1
key=$1

while  kill -0 $key 
do
        for i in $(seq 0 10 100) ; do sleep 1; echo $i | dialog --gauge "Getting some info...Please, be patient..." 10 70 0; done

done

