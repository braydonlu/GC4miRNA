#Code credit: The orginal code was written by abbykatb: https://github.com/abbykatb/Abbys-Amazing-GC-Calculator
#!/bin/bash

# Check for input file
echo "Calculating GC Content for $1 ..."
if [ $# != 1 ]; then
    echo "Please include a fasta input on the command line!"
    exit
fi

# Read headers and sequences
IFS=$'\n'
Headers=($(grep "^>" "$1"))
Sequences=($(grep -v "^>" "$1"))

# Calculate GC content
NL=${#Sequences[@]}
echo "Number of Sequences in File: $NL"
let NL=$NL-1
X=0

while [ $X -le $NL ]; do
    # Clean the sequence: remove spaces/newlines, uppercase, keep only A/U/G/C
    SEQ=$(echo "${Sequences[$X]}" | tr -d '\n\r ' | tr '[:lower:]' '[:upper:]')
    #echo "SEQ is $S
    CLEAN_SEQ=$(echo "$SEQ" | grep -o "[AUGC]" | tr -d '\n')
    #echo "CLEAN_SEQ is $CLEAN_SEQ"
    TOTAL=${#CLEAN_SEQ}

    G=$(echo "$CLEAN_SEQ" | grep -o "G" | wc -l)
    C=$(echo "$CLEAN_SEQ" | grep -o "C" | wc -l)
    #echo "G is $G, C is $C"
    #echo "Total is $TOTAL"
    GC=$((G + C))

    if [ "$TOTAL" -eq 0 ]; then
        Percent[$X]="0.00"
    else
        Percent[$X]=$(echo "scale=2; $GC * 100 / $TOTAL" | bc)
    fi

    let X=$X+1
done

# Output to file
echo "GC Content for $1 ...  " > "$1.gcoutput.txt"
NX=${#Headers[@]}
let NX=$NX-1
N=0
H=0
while [ $N -le $NX ]; do
    echo "*** " >> "$1.gcoutput.txt"
    echo "${Headers[$N]}" >> "$1.gcoutput.txt"
    echo "${Percent[$H]} % GC CONTENT" >> "$1.gcoutput.txt"
    let N=$N+1
    let H=$H+1
done

# Show the results
cat "$1.gcoutput.txt"

