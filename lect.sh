#!binbash

function users() {
file=etcpasswd
list=$(grep home $file)
#echo $list
touch file.txt
for i in $list
do
echo $i  file.txt
done
sort file.txt -o sort_file.txt
file2=sort_file.txt
for str in $(cat $file2)
do
echo $str
done
rm file.txt
rm sort_file.txt
}

function processes() {
ps -a
}

function help() {
echo -u --users displays a list of users and their home directories
echo -p -- processes displays a list of running processes
echo -h --help displays help with a list and description of the arguments and stops work
echo -l PATH --log PATH replaces screen output with output to a file in the given PATH path
echo -e PATH --error PATH replaces error output from stderr to a file in the given PATH
exit 0
}

function output() {
echo $1
if [ -f $1 ]  [ ! -w $1 ]
then
exec 1$1
else
echo The file does not exist or you do not have permission to write to it&2
fi
}

function output_err() {
if [ -f $1 or -w $1 ]
then
exec 2$1
else
echo The file does not exist or you do not have permission to write to it&2
fi
}

count=2
file_name=
for arg in $@
do
if [ $arg == -e ]  [ $arg == --errors ]
then
file_name=${!count}
output_err $file_name
break
fi
count=$(( $count + 1 ))
done

count=2
file_name=
for arg in $@
do
if [ $arg == -l ]  [ $arg == --log ]
then
file_name=${!count}
output $file_name
break
fi
count=$(( $count + 1 ))
done


TEMP=$(getopt -o uphle --long users,processes,help,log,errors -- $@)
eval set -- $TEMP

while [ -n $1 ]
do
case $1 in
-u  --users)
users
shift
;;
-p  --processes)
processes
shift
;;
-h  --help)
help
shift
;;
)
shift
;;
esac
done