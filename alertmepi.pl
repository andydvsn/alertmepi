#!/usr/bin/perl

# AlertMe Perl Interface v2.08 (16/05/12)
#
# http://code.google.com/p/alertmepi

use strict;
use warnings;
use Getopt::Std;
use RPC::XML::Client;
use Scalar::Util qw(looks_like_number);

our ($username, $password, $client, $cookie, $randomness, @devices, @eventlog, @status);

# Process options, so we know what we're doing.
my %options=();
getopts("QaA:b:cC:dDe:E:hI:kl:LmM:O:pP:rs:t:UwWz",\%options);

# Display help, if requested.
if($options{h}) {
	die "Usage: $0 [options]
Running with no options returns the current hub status.

Setup:
  -L                          Change AlertMe login details.
  -U                          Update cached devices list (necessary after modifying devices).

Commands:
  -M < home | away | night >  Change the hub to the requested mode.  

  -E < 'device name' | all >  [ -O on|off ] 
                              Toggle power relay state of smartplug(s). BE CAREFUL USING 'ALL'!
                              Include -O flag to specify the state.

Queries:
  -a                          List all hubs associated with account, with unique hub ID in raw mode.
                              NB: Interaction is limited to the first hub in an account.
                                  Not really a problem, as AlertMe only operate one hub per account.

  -b < 'device name' | 'device type' | all >  
                              Read battery voltage of specified device, device type, or all devices.

  -c                          List cached devices and their device type.
  -d                          List devices and their device type from AlertMe's servers.

  -e < 'device name' | all >  Return power relay state (usage if on) of one/all smartplugs, and/or
                              get the usage reading from a powerclamp. Usage reported in watts.

  -k                          Return which keyfobs are currently at home.
  -l < integer >              Output the last # log entries (up to 50) with human-readable time.
  -m                          Return the system mode and the length of time we've been in it.
  -p                          Return how long keyfobs have been present or absent.

  -s < available | power | connection | uptime | version | all >
                              Get specified hub status, or return everything status-related.

  -t < 'device name' | all >  Read temperature.
    
  -z                          Output any debug data that may be available.

Output Mode:
  -W                          Return simple hub status formatted in HTML (used independently).
    
  -w                          Return value formatted in HTML (used in conjunction with queries).

  -A                          Specify anchor tag 'href' value to be used in the HTML output.
  -D                          Appends the 'safe name' of a device to the end of the 'href' value.
                              Useful to control the device you just retrieved HTML data for.
                              
  -C                          Specify class values to be used in the HTML output.
  -P                          Specify which tag the result should be wrapped in for HTML output. eg. 'p'.

  -r                          Return query results as raw values.
  
  -h                          Display this help information.
\n";
}

# Generate a random number to identify this run.
$randomness = int(rand(99999999));

checklogin();
readlogin();
getdevicecache();

unless($options{c}) {	
	login();
}


#TEST OPTION
if($options{Q}) {
	getStatus();
}


# Our default output.
if (!%options) {
	my $result = getBehaviour();
	print "$result\n"
}


# Deal with web options.
if (!$options{A}) {
	$options{A} = "";
}
if (!$options{C}) {
	$options{C} = "";
}
if (!$options{P}) {
	$options{P} = "";
}


# Current status.
if ($options{W}) {
	
	my $result = getBehaviour();

	if ($options{W}) {
		if ($options{A}) { $result = "<a href=\"$options{A}\">$result</a>"; }
		if ($options{P}) { $result = "<$options{P}>$result</$options{P}>"; }
		print "<div id=\"ampi_status\" class=\"$options{C}\">$result</div>\n";
	}
}



# Set the system mode.
if ($options{M}) {

	if ($options{M} eq 'home') {
		my $result = setMode("disarm");
		if ($result eq 'ok') {
			$result = "System Disarmed";
			if ($options{w}) {
				if ($options{A}) { $result = "<a href=\"$options{A}\">$result</a>"; }
				if ($options{P}) { $result = "<$options{P}>$result</$options{P}>"; }
				print "<div id=\"ampi_mode\" class=\"$options{C}\">$result</div>\n";
			} else {
				print "System disarmed.\n";
			}
		} else {
			$result = "Unsuccessful";
			if ($options{w}) {
				if ($options{A}) { $result = "<a href=\"$options{A}\">$result</a>"; }
				if ($options{P}) { $result = "<$options{P}>$result</$options{P}>"; }
				print "<div id=\"ampi_mode\" class=\"$options{C} error\">$result</div>\n";
			} else {
				print "Command unsuccessful; please try again.\n";
			}
		}
	}
	
	if ($options{M} eq 'away') {
		my $result = setMode("arm");
		if ($result eq 'ok') {
			$result = "System Armed";
			if ($options{w}) {
				if ($options{A}) { $result = "<a href=\"$options{A}\">$result</a>"; }
				if ($options{P}) { $result = "<$options{P}>$result</$options{P}>"; }
				print "<div id=\"ampi_mode\" class=\"$options{C}\">$result</div>\n";
			} else {
				print "System armed.\n";
			}
		} else {
			$result = "Unsuccessful";
			if ($options{w}) {
				if ($options{A}) { $result = "<a href=\"$options{A}\">$result</a>"; }
				if ($options{P}) { $result = "<$options{P}>$result</$options{P}>"; }
				print "<div id=\"ampi_mode\" class=\"$options{C} error\">$result</div>\n";
			} else {
				print "Command unsuccessful; please try again.\n";
			}
		}
	}
	
	if ($options{M} eq 'night') {
		my $result = setMode("nightArm");
		if ($result eq 'ok') {
			$result = "System in Night Mode";
			if ($options{w}) {
				if ($options{A}) { $result = "<a href=\"$options{A}\">$result</a>"; }
				if ($options{P}) { $result = "<$options{P}>$result</$options{P}>"; }
				print "<div id=\"ampi_mode\" class=\"$options{C}\">$result</div>\n";
			} else {
				print "System now in Night Mode.\n";
			}
		} else {
			$result = "Unsuccessful";
			if ($options{w}) {
				if ($options{A}) { $result = "<a href=\"$options{A}\">$result</a>"; }
				if ($options{P}) { $result = "<$options{P}>$result</$options{P}>"; }
				print "<div id=\"ampi_mode\" class=\"$options{C} error\">$result</div>\n";
			} else {
				print "Command unsuccessful; is the system already armed?\n";
			}
		}
	}	

}



# List hubs.
if ($options{a}) {
	my $result = getAllHubs();
		my $pass = 0;
		foreach my $d ( split ',', $result ) {
		    my( $name, $id ) = split '\|', $d;
			my $namemush = mush($name);		
			
				my $ampi_highlight = $pass % 2 ? 'light' : 'dark';			
			
				output_a($pass,$name,$namemush,$id,$ampi_highlight);
				
				$pass++;
		}
}

sub output_a {
	
	my ($pass,$name,$namemush,$id,$ampi_highlight) = @_;
	$pass = ($pass += $randomness);
	
	if ($options{w}) {	
		
		if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
		if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
		print "<div id=\"ampi_allhubs$pass\" class=\"ampi_allhubs $ampi_highlight $options{C}\"><span class=\"ampi_reading\">$name</span></div>\n";
		
	} elsif ($options{r}) {
		print "$namemush|$id\n";
	} else {
		print "$name\n";			
	} 
	
}



# Fetch battery levels.
if ($options{b}) {
		
	my $pass = 0;
	
	if ($options{b} ne 'all') {
		@devices = grep(/$options{b}/i, @devices);
	} else {
		@devices = grep(!/camera/i, @devices);
		@devices = grep(!/power controller/i, @devices);
	}
	
	foreach my $d ( @devices ) {
	    my( $name, $id, $type ) = split '\|', $d;
		my $namemush = mush($name);
		my $typemush = mush($type);
					
		my $ampi_highlight = $pass % 2 ? 'light' : 'dark';
	 	my $status = 'ampi_online';
	
		my $devicestate = getBatteryLevel("$id");
	
		output_b($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$devicestate);
		
		$pass++;
			
	}	
		
}

sub output_b {
	
	my ($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$devicestate) = @_;
	$pass = ($pass += $randomness);
	
	if(looks_like_number($devicestate)) {

		if ($devicestate < 2.6) { $status = 'ampi_warning'; }
		if ($devicestate < 2.8 && $typemush eq 'powerclamp') { $status = 'ampi_warning'; }

		if ($options{w}) {
			
			if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_battery$pass\" class=\"ampi_battery $typemush $ampi_highlight $status $options{C}\">$name<span class=\"ampi_reading $status\">".$devicestate."V</span></div>\n";
						
		} elsif ($options{r}) {
			print "$namemush|$devicestate\n";
		} else {
			print "$name\'s ".lc($type)." battery is at ".$devicestate."V\n";
		}

	} else {
		
		$status = 'ampi_offline';
		
		if ($options{w}) {
			
			if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_battery$pass\" class=\"ampi_battery $typemush $ampi_highlight $status $options{C}\">$name<span class=\"ampi_reading $status\">Unavailable</span></div>\n";
			
		} elsif ($options{r}) {
			print "$namemush|unavailable\n";
		} else {
			print "$name\'s ".lc($type)." is unavailable.\n";
		}
	
	}
	
}



# List devices (cached).
if ($options{c}) {
		my $pass = 0;
		foreach my $d ( @devices ) {
		    my( $name, $id, $type ) = split '\|', $d;
			my $ampi_highlight = $pass % 2 ? 'light' : 'dark';
			my $namemush = mush($name);		
			my $typemush = mush($type);
			
			output_cd($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight);
			
			$pass++;
		}
}

# List devices (live, not cached).
if ($options{d}) {
	my $result = getAllDevices();
		my $pass = 0;
		foreach my $d ( split ',', $result ) {
		    my( $name, $id, $type ) = split '\|', $d;
			my $namemush = mush($name);		
			my $typemush = mush($type);
			
				my $ampi_highlight = $pass % 2 ? 'light' : 'dark';			
			
				output_cd($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight);
				
				$pass++;
		}
}

sub output_cd {
	
	my ($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight) = @_;
	$pass = ($pass += $randomness);
	
	if ($options{w}) {	
	
		if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
		if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
		print "<div id=\"ampi_device$pass\" class=\"ampi_device $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading\">$type</span></div>\n";
		
	} elsif ($options{r}) {
		print "$namemush|$id|$typemush\n";
	} else {
		print "$id is the ".lc($type)." named \'$name\'.\n";			
	} 
	
}



# Get relay state of smartplugs, returning usage if they're on, and grab total usage from powerclamp.
if ($options{e}) {
			
	my $pass = 0;
	
	if ($options{e} ne 'all') {
		@devices = grep(/$options{e}/i, @devices);
		$pass = "1000";
	}
	
	foreach my $d ( @devices ) {
	    my( $name, $id, $type ) = split '\|', $d;
		my $namesafe = $name;
		$namesafe =~ s/\ /_/g;
		my $namemush = mush($name);
		my $typemush = mush($type);
		
		if( $typemush =~ 'power' ) {
		
			my $ampi_highlight = $pass % 2 ? 'light' : 'dark';
		 	my $status = 'online';
			
			my $devicestate;
			if ($typemush eq 'powercontroller') {
				$devicestate = getRelayState("$id");
			} elsif ($typemush eq 'powerclamp') {
				$devicestate = $typemush;
			}
		
			output_eE($pass,$name,$namemush,$namesafe,$id,$type,$typemush,$ampi_highlight,$status,$devicestate);

			$pass++;
			
		}
			
	}	
			
}

# Control smartplugs.
if ($options{E}) {
	
	my $pass = 0;
	
	if ($options{E} ne 'all') {
		@devices = grep(/$options{E}/i, @devices);
		$pass = "1000";
	}
	
	foreach my $d ( @devices ) {
	    my( $name, $id, $type ) = split '\|', $d;
		my $namesafe = $name;
		$namesafe =~ s/\ /_/g;
		my $namemush = mush($name);
		my $typemush = mush($type);
		
		if( $typemush eq 'powercontroller') {
		
			my $ampi_highlight = $pass % 2 ? 'light' : 'dark';
		 	my $status = 'online';
		
			if ($options{O}) {
				setRelayState("$id",$options{O});
			}
		
			if (!$options{O}) {
				toggleRelayState("$id");
			}
			
			sleep 2; # Need to pause a bit, otherwise we might ask for state info before it has been returned.
			my $devicestate = getRelayState("$id");
		
			output_eE($pass,$name,$namemush,$namesafe,$id,$type,$typemush,$ampi_highlight,$status,$devicestate);

			$pass++;
			
		}
			
	}
	
}

sub output_eE {

	my ($pass,$name,$namemush,$namesafe,$id,$type,$typemush,$ampi_highlight,$status,$devicestate) = @_;
	$pass = ($pass += $randomness);

	if($devicestate eq 'True') {

		my $powerlevel = getPowerLevel("$id");

		if(looks_like_number($powerlevel)) {

			if ($options{w}) {
								
				if ($options{A}) { if ($options{D}) { $name = "<a href=\"$options{A}\'$namesafe\'\">$name</a>"; } else { $name = "<a href=\"$options{A}\">$name</a>"; } }
				if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
				print "<div id=\"ampi_energy$pass\" class=\"ampi_energy $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_online\">".$powerlevel."W</span></div>\n";
				
			} elsif ($options{r}) {
				print "$namemush|$powerlevel\n";
			} else {
				print "$name is measuring ".$powerlevel."W.\n";
			}
			
		} else {
			
			if ($options{w}) {
																
				if ($options{A}) { if ($options{D}) { $name = "<a href=\"$options{A}\'$namesafe\'\">$name</a>"; } else { $name = "<a href=\"$options{A}\">$name</a>"; } }
				if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
				print "<div id=\"ampi_energy$pass\" class=\"ampi_energy $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_offline\">Unavailable</span></div>\n";
				
			} elsif ($options{r}) {
				print "$namemush|unavailable\n";
			} else {
				print "$name is unavailable.\n";
			}
			
		}

	}

	if($devicestate eq 'False') {

		if ($options{w}) {
			
			if ($options{A}) { if ($options{D}) { $name = "<a href=\"$options{A}\'$namesafe\'\">$name</a>"; } else { $name = "<a href=\"$options{A}\">$name</a>"; } }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_energy$pass\" class=\"ampi_energy $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_standby\">Off</span></div>\n";
			
		} elsif ($options{r}) {
			print "$namemush|off\n";
		} else {
			print "$name is off.\n";
		}

	}
	
	if($devicestate eq 'powerclamp') {

		my $powerlevel = getPowerLevel("$id");

		if(looks_like_number($powerlevel)) {

			if ($options{w}) {
								
				if ($options{A}) { if ($options{D}) { $name = "<a href=\"$options{A}\'$namesafe\'\">$name</a>"; } else { $name = "<a href=\"$options{A}\">$name</a>"; } }
				if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
				print "<div id=\"ampi_energy$pass\" class=\"ampi_energy $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_online\">".$powerlevel."W</span></div>\n";
				
			} elsif ($options{r}) {
				print "$namemush|$powerlevel\n";
			} else {
				print "$name is measuring ".$powerlevel."W.\n";
			}
			
		} else {
			
			if ($options{w}) {
												
				if ($options{A}) { if ($options{D}) { $name = "<a href=\"$options{A}\'$namesafe\'\">$name</a>"; } else { $name = "<a href=\"$options{A}\">$name</a>"; } }
				if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
				print "<div id=\"ampi_energy$pass\" class=\"ampi_energy $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_offline\">Unavailable</span></div>\n";
				
			} elsif ($options{r}) {
				print "$namemush|unavailable\n";
			} else {
				print "$name is unavailable.\n";
			}
			
		}

	}

	if($devicestate ne 'False' && $devicestate ne 'True' && $devicestate ne 'powerclamp') {

		if ($options{w}) {
														
			if ($options{A}) { if ($options{D}) { $name = "<a href=\"$options{A}\'$namesafe\'\">$name</a>"; } else { $name = "<a href=\"$options{A}\">$name</a>"; } }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_energy$pass\" class=\"ampi_energy $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_offline\">Unavailable</span></div>\n";
			
		} elsif ($options{r}) {
			print "$namemush|unavailable\n";
		} else {
			print "$name is unavailable.\n";
		}

	}

}



# Discover which keyfobs are at home.
if ($options{k}) {
			
	my $pass = 0;
	
	foreach my $d ( @devices ) {
	    my( $name, $id, $type ) = split '\|', $d;
		my $namemush = mush($name);
		my $typemush = mush($type);
		
		if( $typemush eq 'keyfob') {
		
			my $ampi_highlight = $pass % 2 ? 'light' : 'dark';
		 	my $status = 'online';
		
			my $devicestate = getPresence("$id");
		
			output_k($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$devicestate);

			$pass++;
			
		}
			
	}	
			
}

sub output_k {
	
	my ($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$devicestate) = @_;
	$pass = ($pass += $randomness);
	
	if ($devicestate eq 'True') {
	
		if ($options{w}) {
			
			if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_presence$pass\" class=\"ampi_presence $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_online\">Home</span></div>\n";
			
		} elsif ($options{r}) {
			print lc($name)."\n";
		} else {
			print "$name\n";		
		}
			
	} else {
	
		if ($options{w}) {
			
			if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_presence$pass\" class=\"ampi_presence $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_offline\">Away</span></div>\n";
			
		}
	
	}
	
}



# Output log information.
if ($options{l}) {
	unless (looks_like_number($options{l})) {
		print "Please specify the number of lines to return (max 50).\n";
		exit;
	} else {
		getEventLog("$options{l}");
		
		
		if ($options{w}) {
		
			print "<div id=\"ampi_logoutput\"><table>\n<tr><th>Time Elapsed</th><th>Message</th></tr>\n";
			foreach my $l (@eventlog) {
				if ( $l =~ m/\|\|/ ) {
					my( $timestamp, $message ) = split '\|\|', $l;			
					my $difference = difference($timestamp,3);
					print "<tr><td>$difference</td><td>$message</td></tr>\n";
				} else {
					my ( $timestamp, $zidlabel, $loggedid, $typelabel, $loggedtype, $message ) = split '\|', $l;
					my $difference = difference($timestamp,3);
					print "<tr><td>$difference</td><td>$message</td></tr>\n";
				}
			}

			print "</table></div>\n";
			
		} elsif ($options{r}) {
		
			foreach my $loggy (@eventlog) {
				print "$loggy\n";	
			}
			
		} else {	
		
			foreach my $l (@eventlog) {
				if ( $l =~ m/\|\|/ ) {
					my( $timestamp, $message ) = split '\|\|', $l;			
					my $difference = difference($timestamp,3);
					print "$difference ago - $message\n";
				} else {
					my ( $timestamp, $zidlabel, $loggedid, $typelabel, $loggedtype, $message ) = split '\|', $l;
					my $difference = difference($timestamp,3);
					print "$difference ago - $message\n";
				}
			}
			
		}
	}
}



# Tell us what mode we're in, and how long we've been in it.
if ($options{m}) {
	
	getEventLog(50);
	@eventlog = grep(/Behaviour changed to/, @eventlog);
		
	foreach my $l ( @eventlog ) {
		my ( $timestamp, $message ) = split '\|\|', $l;
		
		my $behaviour;
		if ( $message =~ m/At home/ ) {
			$behaviour = 'Home';
		}
		if ( $message =~ m/Away/ ) {
			$behaviour = 'Away';
		}
		if ( $message =~ m/Night/ ) {
			$behaviour = 'Night';
		}
		
		my $mode = $behaviour;
		my $elapsed = difference("$timestamp",3);
		my $elapsedsecs = time() - $timestamp;
						
		if ($options{w}) {
				
			if ($options{A}) { $mode = "<a href=\"$options{A}\">$behaviour</a>"; }
			if ($options{P}) { $mode = "<$options{P}>$mode</$options{P}>"; }
			print "<div id=\"ampi_mode\" class=\"ampi_mode ampi_".lc($behaviour)." $options{C}\">$mode<span class=\"ampi_reading\">".$elapsed."</span></div>\n";
			
		} elsif ($options{r}) {
			print lc($behaviour)."|$elapsedsecs\n";
		} else {
			$message = lc($message);
			$message = ucfirst($message);
			
			if ($elapsed eq "") {
				$elapsed = "less than a minute";
			}
			
			print "$message $elapsed ago.\n";
		}
		
		last;
		
	}
					
} 



# Tell us how long keyfobs have been present or absent for.
if ($options{p}) {
	
	getEventLog(50);
	@eventlog = grep(/Keyfob has/, @eventlog);
		
	my $pass = 0;
	
	foreach my $d ( @devices ) {
	    my( $name, $id, $type ) = split '\|', $d;
		my $namemush = mush($name);
		my $typemush = mush($type);
		
		if( $typemush eq 'keyfob') {
		
			my $ampi_highlight = $pass % 2 ? 'light' : 'dark';
		 	my $status = 'online';
						
			foreach my $l ( @eventlog ) {
				my ( $timestamp, $zidlabel, $loggedid, $typelabel, $loggedtype, $message ) = split '\|', $l;
				
				if ( $loggedid eq $id ) {
					my $elapsed = difference("$timestamp",3);
					my $elapsedsecs = time() - $timestamp;
					
					my $presence;
					if ( $message =~ "arrived home" ) {
						$presence = "home";
					} elsif ( $message =~ "left home" ) {
						$presence = "away"
					}
										
					output_p($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$presence,$elapsed,$elapsedsecs);
					
					last;
				}
				
			}
		
			$pass++;
			
		}
			
	}	
			
} 

sub output_p {
	
	my ($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$presence,$elapsed,$elapsedsecs) = @_;
	$pass = ($pass += $randomness);
	
	if ($options{w}) {
		
		if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
		if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
		print "<div id=\"ampi_presence$pass\" class=\"ampi_presence $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_$presence\">$elapsed</span></div>\n";
		
	} elsif ($options{r}) {
		print "$namemush|$elapsedsecs\n";
	} else {
		print "$name has been $presence for $elapsed.\n";
	}
	
}



# Get hub status information.
if ($options{s}) {
	
    # Get the hubs and only use the first one.
	my $hubs = getAllHubs();
	my @hubs = ( split ',', $hubs );
	my @firsthub = ( split '\|', $hubs[0] );
	my $hub = $firsthub[0];
	
	my ($hubavail,$hubpower,$hubconn,$hubup,$hubver,$hubstatus);
		
	getStatus();
	    
    # Humanise some of the output.
	foreach my $i (@status) {
		$i=lc($i);
	    my ($item,$state) = split '\|', $i, 2;		
		
		if ($item eq 'isavailable' && $state eq 'yes') {
			$hubavail = "Available";
			$hubstatus = "online";
		} elsif ($item eq 'isavailable' && $state eq 'no') {
			$hubavail = "Unavailable";
			$hubstatus = "offline";
		} elsif ($item eq 'isupgrading' && $state eq 'yes') {
			$hubavail = "Upgrading";
			$hubstatus = "standby";
		}
        
	}

    # Lose the values we've not been asked for.
	if ($options{s} ne 'all'){
		@status = grep(/$options{s}/i, @status);
	}
		
	foreach my $i (@status) {
               
		$i=lc($i);
	    my ($item,$state) = split '\|', $i, 2;
        
        #print "$item\n";
        #print "$state\n";
		
		if ($item eq 'powertype' && $state eq 'ac') {
			$hubpower = "AC";
		} elsif ($item eq 'powertype' && $state eq 'battery') {
			$hubpower = "battery";
			$hubstatus = "standby";
		}
		
		if ($item eq 'connectiontype' && $state eq 'broadband') {
			$hubconn = "broadband";
		} elsif ($item eq 'connectiontype' && $state eq 'gprs') {
			$hubconn = "GPRS";
			$hubstatus = "standby";
		}
		
		if ($item eq 'uptime') {
            my (@uptime) = split '\|', $state;
            
			my ($upday,$uphour,$upmin,$upsec) = @uptime;
			foreach ($upday,$uphour,$upmin,$upsec) {
				$_ =~ s/\D//g;
			}
			
			$state = ($upday * 86400) + ($uphour * 3600) + ($upmin * 60) + $upsec;
			$hubup = $state;
		}
		
		if ($item eq 'version') {
			$hubver = $state;
		}
		
		if ($options{r}) {
			print "".mush($hub)."|$item|$state\n";
		}
									
	}
	
	unless ($options{r}) {
		if ($options{w}) {
		
			if ($options{A}) { $hub = "<a href=\"$options{A}\">$hub</a>"; }
			if ($options{P}) { $hub = "<$options{P}>$hub</$options{P}>"; }
			print "<div id=\"ampi_hubstatus\" class=\"ampi_".lc($hubavail)."\">$hub<span class=\"ampi_reading\">";
			
			if ($options{s} =~ 'version' || $options{s} =~ 'all') {
				print "<p class=\"hubver\">$hubver</p>";
			}
				
			if ($options{s} =~ 'uptime' || $options{s} =~ 'all') {
				print "<p class=\"hubup\">".difference($hubup,4,'convert')."</p>";
			}
			
			if ($options{s} =~ 'power' || $options{s} =~ 'all') {
				print "<p class=\"hubpower\">".ucfirst($hubpower)."</p>";
			}
			
			if ($options{s} =~ 'connection' || $options{s} =~ 'all') {
				print "<p class=\"hubconn\">".ucfirst($hubconn)."</p>";
			}

			print "</span></div>\n";
		
		} else {
		
			print "$hub";
			
			if ($options{s} =~ 'version' || $options{s} =~ 'all') {
				print " ($hubver)";
			}
		
			if ($options{s} =~ 'available' || $options{s} =~ 'all') {
				print " is ".lc($hubavail)."";
			}
			
			if ($options{s} =~ 'uptime' || $options{s} =~ 'all') {
				print ", up ".difference($hubup,4,'convert')."";
			}
			
			if ($options{s} =~ 'power' || $options{s} =~ 'all') {
				print ", running on ".$hubpower." power";
			}
			
			if ($options{s} =~ 'connection' || $options{s} =~ 'all') {
				print ", connected via ".$hubconn."";
			}
		
			print ".\n";
		
		}
		
	}	
			
}



# Get temperature readings from devices.
if ($options{t}) {
		
	my $pass = 0;
	
	if ($options{t} ne 'all') {
		@devices = grep(/$options{t}/i, @devices);
	} else {
		@devices = grep(!/camera/i, @devices);
		@devices = grep(!/keyfob/i, @devices);
		@devices = grep(!/power controller/i, @devices);
	}
	
	foreach my $d ( @devices ) {
	    my( $name, $id, $type ) = split '\|', $d;
		my $namemush = mush($name);
		my $typemush = mush($type);

		my $ampi_highlight = $pass % 2 ? 'light' : 'dark';
	 	my $status = 'online';
	
		my $devicestate = getTemperature("$id");
		
		# This crudely tries to compensate for the temperature variation of a smartplug. 
		if ($typemush eq 'powercontroller') {
			my $state = getRelayState("$id");
			if ($state eq 'True') {
				$devicestate = $devicestate - 20;
			} elsif ($state eq 'False') {
				$devicestate = $devicestate - 10;
			}
		}
		
		# This tries to do the same thing for a lamp. 
		if ($typemush eq 'lamp') {
			$devicestate = $devicestate - 19;
		}
		
		output_t($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$devicestate);
		
		$pass++;
						
	}	
		
}

sub output_t {
	
	my ($pass,$name,$namemush,$id,$type,$typemush,$ampi_highlight,$status,$devicestate) = @_;
	$pass = ($pass += $randomness);
	
	if(looks_like_number($devicestate)) {

		if ($options{w}) {	
			#print "<div id=\"temperature$pass\" class=\"box $ampi_highlight $typemush temperature\"><h4>$name</h4><span class=\"reading\"><p class=\"online\">$devicestate&deg;C</p></span></div>\n";
			
			if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_temperature$pass\" class=\"ampi_temperature $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_online\">$devicestate&deg;C</span></div>\n";
			
		} elsif ($options{r}) {
			print "$namemush|$devicestate\n";
		} else {
			print "$name is at $devicestate degrees celsius.\n";			
		}

	} else {
			
		if ($options{w}) {
			
			if ($options{A}) { $name = "<a href=\"$options{A}\">$name</a>"; }
			if ($options{P}) { $name = "<$options{P}>$name</$options{P}>"; }
			print "<div id=\"ampi_temperature$pass\" class=\"ampi_temperature $typemush $ampi_highlight $options{C}\">$name<span class=\"ampi_reading ampi_offline\">Unavailable</span></div>\n";
			
		} elsif ($options{r}) {
			print "$namemush|$devicestate\n";
		} else {
			print "$name\'s temperature is unavailable.\n";
		}
	
	}
	
}



# Update the devices list.
if ($options{U}) {
	updatedevices();
	getdevicecache();
	print "The device cache has been updated.\n";
	foreach my $d ( @devices ) {
	    my( $name, $id, $type ) = split '\|', $d;
		print "$id is the ".lc($type)." named \'$name\'.\n";			
	}
}




### We all love subroutines.

# This handles creation and modification of the login file, populates the device cache file and sets up the cookie cache.
### THIS NEEDS TO BE MADE PER-USER AND SYSTEM AGNOSTIC ###
sub checklogin {
	if ($options{L}) {
		print "Clearing old AlertMe login files...\n";
		my $killfiles = `sudo rm -rf /etc/alertme`;
		print $killfiles;
	}
	unless (-e "/etc/alertme") {
		my $currentuser = getlogin();
		print "Setting up AlertMe Perl Interface files...\n";
		my $dirresult = `sudo mkdir /etc/alertme`;
		print $dirresult;
		my $chowndir = `sudo chown -R $currentuser /etc/alertme`;
		print $chowndir;
		
		print "Please enter your AlertMe login credentials.\n";
		print "Username: ";
		chomp (my $iauser = <STDIN>);
		print "Password: ";
		chomp (my $iapwd = <STDIN>);
		open LOGINFILE, ">/etc/alertme/login" or die $!;
		print LOGINFILE "$iauser\n$iapwd";
		close LOGINFILE;
		print "\n";
		
		print "Setting permissions: you may need to enter your system password...\n";
		print "Creating devices cache...";
		updatedevices();
		`sudo chown $currentuser:www /etc/alertme/login`;
		`sudo chown $currentuser:www /etc/alertme/devices`;
		`sudo touch /etc/alertme/cookie; sudo chown $currentuser:www /etc/alertme/cookie`;
		chmod (0660, "/etc/alertme/login");
		chmod (0660, "/etc/alertme/devices");
		chmod (0660, "/etc/alertme/cookie");
		
		if (-e "/etc/alertme/login") {
			print "\nYour AlertMe username and password have been stored here:\n";
			print "  /etc/alertme/login\n\n";
			die "You can now re-run the script to interact with your AlertMe system.\n\n";
		} else {
			die "Something has gone wrong and your password file has not been created.\n
			Please try running the script again.";
		}
		
	}
}

# Find out our account details and hold them ready for use.
sub readlogin {
	open DETAILS, '/etc/alertme/login';		
	my @logindetails = <DETAILS>;		
	close DETAILS;			
	our $username = $logindetails[0]; chomp $username;
	our $password = $logindetails[1]; chomp $password;
}

# Read the cookie file, or log us in to the AlertMe servers, get a new cookie, then generate a random run-number.
sub login {
	
	# Create the XML::RPC object.
	our $client = new RPC::XML::Client (
		'https://api.alertme.com/webapi/v2',
		error_handler => sub { return "error_network_fault" },
		fault_handler => sub { return "error_" . $_[0]->{faultString} },
	);
	
	my $cookiefile = "/etc/alertme/cookie";
	my $cookieedible = 0;
	
	if (-e $cookiefile) {
		my $cookieage = -M $cookiefile or die "Can't get the age of the cookie file: $cookiefile $!\n";
		$cookieage = int $cookieage*1440;
		if ($cookieage < 15) {
			open COOKIE, "$cookiefile" or die $!;
			our $cookie = <COOKIE>;
			close COOKIE;
			$cookieedible = 1;
		}
	}
	
	if ($cookieedible < 1) {

		my $req = RPC::XML::request->new('login', $username, $password, 'Titchy' ); 			#print "Request is: $req\n";
		my $res = $client->send_request($req);													#print "Result is: $res\n"; print "Client is: $client\n";
		#login() unless ref $res;
		#if ($res =~ "error_") { die "Stupid error." }

		if ($res !~ "error_") {												
			our $cookie = $res->value;															#print "Cookie is: $cookie\n";
			open COOKIE, ">$cookiefile" or die $!;
			print COOKIE $cookie;
			close COOKIE;
		} else {
			login();
		}	

	}
	
}

# This is the bit that actually updates the devices cache.
sub updatedevices {
	readlogin();
	login();
	open DEVICES, ">/etc/alertme/devices" or die $!;
	print DEVICES getAllDevices();
	close DEVICES;
}

# This reads the device cache and feeds it into an array.
sub getdevicecache {
	open DEVICES, '/etc/alertme/devices' or die $!;
	my $devicecache = <DEVICES>;
	close DEVICES;
	our @devices = ( split ',', $devicecache );
	@devices = sort(@devices);
}



# Here live the API commands in handy, bite-sized subroutines.

sub getAllDevices {
	my $req = RPC::XML::request->new('getAllDevices', $cookie);
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub getAllHubs {
	my $req = RPC::XML::request->new('getAllHubs', $cookie);
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub getBehaviour {
	my $req = RPC::XML::request->new('getBehaviour', $cookie );
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub getBatteryLevel {
	my $req = RPC::XML::request->new('getDeviceChannelValue', $cookie, @_, 'BatteryLevel');
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	} else {
		$result = sprintf("%.2f", $result);
	}
	return $result;
}

sub getEventLog {
	my ($number) = @_;
	my $req = RPC::XML::request->new('getEventLog', $cookie, "null", $number, "null", "null");
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
		return $result;
	} else {
		our @eventlog = ( split ',', $result );
		#@eventlog = sort(@eventlog);							# This reverses the order of the event log (oldest first).
	}
}

sub getPowerLevel {
	my $req = RPC::XML::request->new('getDeviceChannelValue', $cookie, @_, 'PowerLevel');
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub getPresence {
	my $req = RPC::XML::request->new('getDeviceChannelValue', $cookie, @_, 'Presence');
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub getRelayState {
	my $req = RPC::XML::request->new('getDeviceChannelValue', $cookie, @_, 'RelayState');
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub getStatus {
	my $req = RPC::XML::request->new('getHubStatus', $cookie);
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
		return $result;
	} else {
		our @status = ( split ',', $result );
        if ($options{z}) {print "\nDEBUG: @status\n\n";}
	}
}

sub getTemperature {
	my $req = RPC::XML::request->new('getDeviceChannelValue', $cookie, @_, 'Temperature');
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	} else {
		$result = sprintf("%.1f", $result);
	}
	return $result;
}


sub setRelayState {
	my ($id, $state) = @_;
	my $req = RPC::XML::request->new('sendCommand', $cookie, 'Energy', $state, $id);
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub setMode {
	my ($mode) = @_;
	my $req = RPC::XML::request->new('sendCommand', $cookie, 'IntruderAlarm', $mode);
	my $res = $client->send_request($req);
	my $result = ref $res ? $res->value : $res;
	if ($result =~ "error_") {
		$result = "unavailable";
	}
	return $result;
}

sub toggleRelayState {
	my ($id, $state) = @_;
	my $currentstate = getRelayState("$id");
	if ($currentstate eq 'False') {
		setRelayState("$id","on");
	}
	if ($currentstate eq 'True') {
		setRelayState("$id","off");
	}
}

# This calculates the difference between the current time and a given
#  timestamp in epoch time; unless we're given the 'convert' option.
sub difference {
	my ($giventime,$accuracy,$mode) = @_;
	my ($DAYS,$D,$HOURS,$H,$MINS,$M,$SECS,$S) = ("","","","","","","","");
	my $rightnow = time();
		
	my $difference = $rightnow - $giventime;

	if ($mode) {
		if ($mode eq 'convert') {
			$difference = $giventime;
		} else {
			die "Unknown mode '$mode' given to difference().\n";
		}
	}

	if ($accuracy) {
		if ($accuracy >= 1) {
			$D = int $difference/86400;
			if ($D >= 1) {$DAYS = "$D"."d";} 
		} else {
			$DAYS = "";
		}
		if ($accuracy >= 2) {
			$H = int $difference/3600-$D*24;
			if ($H >= 1) {
				$HOURS = "$H"."h";
				if ($DAYS) { $DAYS = $DAYS." ";	}
			} 
		} else {
			$HOURS = "";
		}
		if ($accuracy >= 3) {
			$M = int $difference/60-$D*1440-$H*60;
			if ($M >= 1) {
				$MINS = "$M"."m";
				if ($DAYS || $HOURS) { $HOURS = $HOURS." ";	}
			} 
		} else {
			$MINS = "";
		}
		if ($accuracy >= 4) {
			$S = int $difference-($D*86400)-($H*3600)-($M*60);
			if ($S >= 1) {
				$SECS = "$S"."s";
				if ($DAYS || $HOURS || $MINS) { $MINS = $MINS." ";	}
			} 
		} else {
			$SECS = "";
		}
	} else {
		die "difference(<time>,<accuracy (1-4)>,[convert]\n";
	}
	
	return "$DAYS$HOURS$MINS$SECS";

}

# Throw away duplicates from an array.
sub uniq {
    my %h;
    return grep { !$h{$_}++ } @_
}

# Turn anything with capital letters and whitespace into a lettermush.
sub mush {
	my $mush = lc("@_");
	$mush =~ s/\s+//g;
	return "$mush";
}
