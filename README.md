# MantisBT backup script (1.0.0)
Creates a backup of your MantisBT installation and MySQL data

Official support sites: [Official Github Repo](https://github.com/fstltna/mantisbackup)

---

1. Edit the settings at the top of minebackup.pl if needed
2. create a cron job like this:

        1 1 * * * /root/mantisbackup/mantisbackup.pl

3. This will back up your Mantis BT installation at 1:01am each day, and keep the last 5 backups.

4. Edit the backup config:
 	Run a manual backup and it will ask you for the mysql config info. If you need to reconfigure it use the "-prefs" command-line option

5. If you want to run a one-off snapshot use the "-snapshot" option

If you need more help visit https://mantisbthosting.retro-os.live
