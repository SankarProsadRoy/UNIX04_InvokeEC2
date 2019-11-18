#echo "Current file-system utilization of $1 is: `df -k $1 | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' | sed 's/^[ *\t]//'| sed 's/[ \t]$//'`%"


VAR=$(echo "Current file-system utilization of $1 is: `df -k $1 | awk -F"%" '{print $1}' | tail -1 | awk '{print substr($0,length($0)-3)}' | sed 's/^[ *\t]//'| sed 's/[ \t]$//'`%")

JSON_FORMAT=$(echo {'"type"' : '"plainText"', '"value"': '"'$VAR'"'})

echo $JSON_FORMAT
