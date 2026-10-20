#
# Regular cron jobs for the count-files package.
#
0 4	* * *	root	[ -x /usr/bin/count-files_maintenance ] && /usr/bin/count-files_maintenance
