# workday-tdaccess-tools

Some colleges moving from Colleague to Workday use the TDAccess tool instead of some of the other commercial tools used by larger schools. Apparently the file format(s) used for the Colleague integration are different than those used for the Workday ingest. 

For more information on the formats for the various ISIR files. (e.g. IDSA22OP starts on page 40)
https://fsapartners.ed.gov/sites/default/files/attachments/2020-06/2122EDETechRef0620Final.pdf



__Workday requires:__
1. All lines must be 4300 characters
	1. Header and footer lines introduced by the tdclient must be removed
1. The first line must be all spaces
1. The file name must end in the correct suffix (.txt / .xml)

The __check_file.sh__ script verifies the above and attempts to fix any problems. It takes the filename of the file to be checked as an argument. (e.g., check_file.sh ISR_to_check) __WARNING: it does *not* create a backup of the file before making changes__.

__Next:__
1. Script(s) that we use to download the files from DOE and prep them for Workday to pick up.
2. Instructions for adding to cron
