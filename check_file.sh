#!/bin/bash

### Make sure the script is being called with an existing file as an argument
if [[ -e $1 ]]; then
	input_file="$1"
else
	echo "No filename given as an argument or the file doesn't exist."
	echo "Usage: $0 <path to file you want to check>"
	exit
fi

### Check to see if files downloaded from the DOE with TDClient are formatted to work
### with Workday.
### Sed is broken on Mac - should at least warn folks
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux - we love linux!"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Looks like you are using a Mac."
        echo "The default version of sed for Mac is broken."
        echo "You can install GNU Sed via Homebrew to resolve the issue."
        echo '(1) ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
        echo "(2) brew update"
        echo "(3) brew install gsed"
        echo "(4) then you'll have to either rename sed to gsed below or make an alias pointing sed to gsed in your path."
        echo " - or run it on a linux server or virtual machine you have access to."
else
        echo "Can't identify the Operating System type."
fi


### Check to see if the lines in the file are 4300 characters
file_line=""
while IFS= read -r -u9 line; do
	((file_line+=1))
	((all_lines+=1))
	if [ ${#line} != 4300 ]; then
		echo $file_line:${#line}
		((bad_lines+=1))
	else
		((good_lines+=1))
	fi
### Check to see if the file has headers and/or footers that break the Workday import
	if [[ "${line}" =~ ^O\*N05 ]]; then
		echo "Line $file_line is a header"
		((header_count+=1))
	elif [[ "${line}" =~ ^O\*N95 ]]; then
		echo "Line $file_line is a footer"
		((footer_count+=1))
	fi
done 9< $input_file

### If there are more than one header or one footer warn and quit
if [[ $header_count > 1 ]]; then
	echo "$input_file has $header_count headers and will need to be split."
	exit
elif [[ ${footer_count} > 1 ]]; then
	echo "$input_file has $footer_count footers and will need to be split."
	exit
fi

### Tell us how many good and bad lines there are
if [[ $good_lines ]]; then
	echo "$good_lines out of lines $all_lines have 4300 characters."
elif [[ $bad_lines ]]; then
	echo "$bad_lines out of $all_lines lines are not 4300 characters."
fi

### If there are bad lines, offer to pad them with spaces
if [[ $bad_lines > 0 ]]; then
	while true
	do
	 read -r -p "Would you like to pad all lines with spaces? [Y/n] " input
	 case $input in
	     [yY][eE][sS]|[yY])
	echo "Adding spaces, this may take awhile..."
### If you are using the Mac built-in version of sed this will fail
### If you've installed gsed via Homebrew you can change sed to gsed
### in the following line and it should work.
	 sed -i ':a;/.\{4300\}/!{s/$/ /;ba}' ${input_file}
	echo "Done adding spaces!"
	 break
	 ;;
	     [nN][oO]|[nN])
	 echo "Leaving the line lengths the same."
	 break
	        ;;
	     *)
	 echo "Invalid input..."
	 ;;
	 esac
	done
fi

### If there is one header and/or one footer offer to remove them
if [[ $header_count = 1 ]] || [[ $footer_count = 1 ]]; then
	while true
	do
	 read -r -p "Would you like to attempt to strip the headers and footers? [Y/n] " input
	 case $input in
	     [yY][eE][sS]|[yY])
	echo "Removing headers and footers..."
	sed -i '/^O\*N05/ d' ${input_file}
	sed -i '/^O\*N95/ d' ${input_file}
	echo "Done stripping headers and footers!"
	 break
	 ;;
	     [nN][oO]|[nN])
	 echo "Leaving headers and footers alone."
	 break
	        ;;
	     *)
	 echo "Invalid input..."
	 ;;
	 esac
	done
### if there are more than one header or footer the file needs to be split
elif [[ $header_count > 1 ]] || [[ $footer_count > 1 ]]; then
	echo "Found more than one record in the file it should be split before processing."
	exit
else
	echo "No headers or footers found!"
fi