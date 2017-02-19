
regex="^$1$"
cmd="grep -i $regex $DICT"
echo $regex
echo $cmd
$cmd | while read word; do
    echo "$word"
done
