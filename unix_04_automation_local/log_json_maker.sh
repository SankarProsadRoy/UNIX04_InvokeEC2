CUR_DIR="$(dirname "$0")"
cd $CUR_DIR
VAR=$(cat logs/unix04_main.sh.log)

JSON_FORMAT=$( echo {'"type"': '"mixed"', '"value1"': '"log val"', '"value2"' : '"'$VAR'"'})
echo $JSON_FORMAT

