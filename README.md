AlertMePI
=========

The AlertMe Perl Interface is a Perl script designed to reduce the initial hurdle of controlling and obtaining data from the AlertMe home security and smart energy system. It is currently compatible with UNIX systems only, as I've hard-coded some paths, but the hope is to make it more system-agnostic as development goes on.


Introduction
------------

The script takes readings from and sends commands to your AlertMe hub via the AlertMe web API. It supports many ways of interacting with your system, including setting and requesting hub status (and returning the length of time in that state), controlling and reading values from SmartPlugs and the PowerClamp, taking temperature readings from devices, obtaining presence information from keyfobs and checking battery levels.

In addition the script has three output modes: 'standard', 'web' and 'raw'. Standard output is human-friendly; web output produces comprehensively tagged HTML; and raw mode simply returns the device name and associated value in 'device|reading' format.

When using the script, a nice rule of thumb is that flags in lower case (eg. -e) are 'query' flags and will not affect the operation of your system, devices attached to it, or the operation of the script itself. Upper case flags are 'control' flags and may turn devices off or modify the operation of your system. Please use them with care!


Installation
------------

### Prerequisites

The script requires two Perl modules in order to work; the RPC::XML::Client module and the Crypt::SSLeay module. These can be installed using CPAN for your system.

### Mac OS X

Tested on Mac OS X v10.5.6 - 10.7.2.

Ensure you have the [Apple Developer Tools](http://developer.apple.com/Tools/) appropriate to your OS X version installed.

Install Crypt::SSLeay:

	sudo /usr/bin/cpan -i Crypt::SSLeay

Accept all of the default settings and choose yourself a download server or two from the list. It should download Crypt::SSLeay and install it with no problems.

Install RPC::XML::Client:

	sudo /usr/bin/cpan -i RPC::XML::Client

You should be ready to go.

### Ubuntu

You'll need build-essential and the libssl-dev package:

	sudo apt-get install build-essential libssl-dev
	
Then the instructions are the same as for Mac OS X:

	sudo /usr/bin/cpan -i Crypt::SSLeay
	sudo /usr/bin/cpan -i RPC::XML::Client
	
That's it.


Configuration
-------------

This is now automated. All you need to do is download the latest version and set the execute bit on it:

	chmod +x alertmepi.pl

Run it from the command line and the first run will prompt you to enter your system password, as it needs to create some files in /etc. It will then prompt you for your AlertMe username and password. These are saved in /etc/alertme/ and read permission is given to the user that installed it, plus the 'www' group so that it can be used from a web interface. Please change these if you feel you need to.

Should you change your AlertMe login details, you'll need to update your details for alertmepi. This can be done by rerunning the script with the -L flag, which will erase your old details and allow you to enter new ones.

You could optionally create a link to wherever you keep the file in your $PATH to trigger it more directly, eg.

	sudo mkdir -p /usr/local/bin
	ln -s path/to/alertme.pl /usr/local/bin/alertme


Usage
-----

You can run: 

	./alertmepi.pl -h

for more information, or take a look in the wiki.


Acknowledgements
----------------

The login and fetch parts of this script were based on Crispin Flowerday's 'houseTemp' perl script.