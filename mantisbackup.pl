#!/usr/bin/perl

# Set these for your situation
my $MTDIR = "/var/www/html/mantisbt";
my $BACKUPDIR = "/root/backups";
my $TARCMD = "/bin/tar chzf";
my $SQLDUMPCMD = "/usr/bin/mysqldump";
my $VERSION = "1.0.0";
my $OPTION_FILE = "/root/.mantisbackuprc";
my $LATESTFILE = "$BACKUPDIR/mantisbt.sql-1";
my $DOSNAPSHOT = 0;
my $MYSQLUSER = "";
my $MYSQLPSWD = "";
my $MYSQLDBNAME = "mantisbt";
my $FILEEDITOR = $ENV{EDITOR};

if ($FILEEDITOR eq "")
{
	$FILEEDITOR = "/usr/bin/nano";
}

my $templatefile = <<'END_TEMPLATE';
# Put mysql user here
mantisbt
# Put mysql password here
changeme
# Put database name here
mantisbt
# Put mantisbt directory here
/var/www/html/mantisbt
END_TEMPLATE


# Get if they said a option
my $CMDOPTION = shift;

sub ReadPrefs
{
	my $LineCount = 0;
	if (! -f $OPTION_FILE)
	{
		open my $fh, '>', "$OPTION_FILE";
		print ($fh $templatefile);
		close($fh);
		system("$FILEEDITOR $OPTION_FILE");
	}

	open(my $fh, '<:encoding(UTF-8)', $OPTION_FILE)
		or die "Could not open file '$OPTION_FILE' $!";

	while (my $row = <$fh>)
	{
		chomp $row;
		if (substr($row, 0, 1) eq "#")
		{
			# Skip comment lines
			next;
		}

		if ($LineCount == 0)
		{
			$MYSQLUSER = $row;
		}
		elsif ($LineCount == 1)
		{
			$MYSQLPSWD = $row;
		}
		elsif ($LineCount == 2)
		{
			$MYSQLDBNAME = $row;
		}
		elsif ($LineCount == 3)
		{
			$MTDIR = $row;
		}
		$LineCount += 1;
	}
	close($fh);
	# print "User = $MYSQLUSER, PSWD = $MYSQLPSWD\n";
}

sub DumpMysql
{
	my $DUMPFILE = $_[0];

	print "Backing up MYSQL data: ";
	if (-f "$DUMPFILE")
	{
		unlink("$DUMPFILE");
	}
	# print "User = $MYSQLUSER, PSWD = $MYSQLPSWD\n";
	system("$SQLDUMPCMD --user=$MYSQLUSER --password=$MYSQLPSWD --result-file=$DUMPFILE $MYSQLDBNAME");
	print "\n";
}

if (defined $CMDOPTION)
{
	if (($CMDOPTION ne "-snapshot") && ($CMDOPTION ne "-prefs"))
	{
		print "Unknown command line option: '$CMDOPTION'\nOnly allowed options are '-snapshot' and '-prefs'\n";
		exit 0;
	}
}

sub SnapShotFunc
{
	print "Backing up mantisbt files: ";
	if (-f "$BACKUPDIR/snapshot.tgz")
	{
		unlink("$BACKUPDIR/snapshot.tgz");
	}
	system("$TARCMD $BACKUPDIR/snapshot.tgz $MTDIR > /dev/null 2>\&1");
	print "\nBackup Completed.\nBacking up MYSQL data: ";
	if (-f "$BACKUPDIR/snapshot.sql")
	{
		unlink("$BACKUPDIR/snapshot.sql");
	}
	# print "User = $MYSQLUSER, PSWD = $MYSQLPSWD\n";
	DumpMysql("$BACKUPDIR/snapshot.sql");
	print "\n";
}

#-------------------
# No changes below here...
#-------------------

if ((defined $CMDOPTION) && ($CMDOPTION eq "-snapshot"))
{
	$DOSNAPSHOT = -1;
}

print "mantisbackup.pl version $VERSION\n";
if ($DOSNAPSHOT == -1)
{
	print "Running Manual Snapshot\n";
}
print "==============================\n";

if ((defined $CMDOPTION) && ($CMDOPTION eq "-prefs"))
{
	# Edit the prefs file
	print "Editing the prefs file\n";
	if (! -f $OPTION_FILE)
	{
		open my $fh, '>', "$OPTION_FILE";
		print ($fh $templatefile);
		close($fh);
	}
	system("$FILEEDITOR $OPTION_FILE");
	exit 0;
}

ReadPrefs();

if (! -d $BACKUPDIR)
{
	print "Backup dir $BACKUPDIR not found, creating...\n";
	system("mkdir -p $BACKUPDIR");
}
if ($DOSNAPSHOT == -1)
{
	SnapShotFunc();
	exit 0;
}

print "Moving existing backups: ";

if (-f "$BACKUPDIR/mantisbackup-5.tgz")
{
	unlink("$BACKUPDIR/mantisbackup-5.tgz") or warn "Could not unlink $BACKUPDIR/mantisbackup-5.tgz: $!";
}

my $FileRevision = 4;
while ($FileRevision > 0)
{
	if (-f "$BACKUPDIR/mantisbackup-$FileRevision.tgz")
	{
		my $NewVersion = $FileRevision + 1;
		rename("$BACKUPDIR/mantisbackup-$FileRevision.tgz", "$BACKUPDIR/mantisbackup-$NewVersion.tgz");
	}
	$FileRevision -= 1;
}

print "Done\nCreating New Backup: ";
system("$TARCMD $BACKUPDIR/mantisbackup-1.tgz $MTDIR");
print "Done\nMoving Existing MySQL data: ";
if (-f "$BACKUPDIR/mantisbt.sql-5")
{
	unlink("$BACKUPDIR/mantisbt.sql-5") or warn "Could not unlink $BACKUPDIR/mantisbt.sql-5: $!";
}

$FileRevision = 4;
while ($FileRevision > 0)
{
if (-f "$BACKUPDIR/mantisbt.sql-$FileRevision")
{
	my $NewVersion = $FileRevision + 1;
	rename("$BACKUPDIR/mantisbt.sql-$FileRevision", "$BACKUPDIR/mantisbt.sql-$NewVersion");
}
$FileRevision -= 1;
}
print "Done\n";

DumpMysql($LATESTFILE);
print("Done!\n");
exit 0;
