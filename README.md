# workday-tdaccess-tools

Some colleges moving from Colleague to Workday use the TDAccess tool instead of some of the other commercial tools used by larger schools. Apparently the file format(s) used for the Colleague integration are different than those used for the Workday ingest. 

Workday requires:
1. All lines must be 4300 characters
	1. Header and footer lines introduced by the tdclient must be removed
1. The first line must be all spaces
1. The file name must end in the correct suffix (.txt / .xml)

