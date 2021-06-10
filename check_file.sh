#!/usr/bin/env bash
	
# Script to check and fix tdaccess files for workday import
# Cian Phillips <cianphillips@gmail.com>
# to lint: shellcheck -x check_file.sh  --shell=bash


## Regular Expression used for checking the all space line
## For some reason regex only allows 255 count of the previous string
## Works well enough for our purposes
padding_test="^[[:space:]]{255}"

all_lines=""
file_line=""
bad_lines=""
good_lines=""
header_count=""
footer_count=""

## fail if pipe returns a non-zero status
set -euo pipefail

### Make sure the script is being called with an existing file as an argument
if [[ -e $1 ]]; then
	input_file="$1"
else
	echo "No filename given as an argument or the file doesn't exist."
	echo "Usage: $0 <path to file you want to check>"
	exit
fi

### Check to see if the lines in the file are 4300 characters
while IFS= read -r -u9 line; do
	((file_line+=1))
	((all_lines+=1))
	if [[ ${#line} != 4300 ]]; then
		echo "$file_line":${#line}
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

## Check to see if file has the padding row of spaces after the header
	if [[ ${line} =~ ${padding_test} ]]; then
		echo "Line $file_line starts with 255 spaces."
		if [[ $file_line = 1 ]]; then
			echo "First line of all spaces looks good."
		elif [[ $file_line = 2 ]]; then
			echo "Second line looks like the padding, should be fine after stripping the header."
		else
			echo "Odd, found a space padded line found where not expected, check file."
			exit
		fi
	fi
done 9< "$input_file"

### If there are more than one header or one footer warn and quit
if [[ $header_count -gt 1 ]]; then
	echo "$input_file has $header_count headers and will need to be split."
	exit
elif [[ ${footer_count} -gt 1 ]]; then
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
if [[ $bad_lines -gt 0 ]]; then
	while true
	do
	 read -r -p "Would you like to pad all lines with spaces? [Y/n] " input
	 case $input in
	     [yY][eE][sS]|[yY])
	echo "Adding spaces, this may take awhile..."
	awk '{printf "%-4300s\n", $0}' "${input_file}" > tmp && mv tmp "${input_file}"
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
	sed -i '/^O\*N05/ d' "${input_file}"
	sed -i '/^O\*N95/ d' "${input_file}"
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
elif [[ $header_count -gt 1 ]] || [[ $footer_count -gt 1 ]]; then
	echo "Found more than one record in the file, it should be split before processing."
	exit
else
	echo "No headers or footers found!"
fi
