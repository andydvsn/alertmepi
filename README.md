AlertMePI
=========

The AlertMe Perl Interface is a perl script designed to reduce the initial hurdle of controlling and obtaining data from the AlertMe home security and smart energy system.


Introduction
------------

The script takes readings from and sends commands to your AlertMe hub via the AlertMe web API. It supports many ways of interacting with your system, including setting and requesting hub status (and returning the length of time in that state), controlling and reading values from SmartPlugs and the PowerClamp, taking temperature readings from devices, obtaining presence information from keyfobs and checking battery levels.

In addition the script has three output modes: 'standard', 'web' and 'raw'. Standard output is human-friendly; web output produces comprehensively tagged HTML; and raw mode simply returns the device name and associated value in 'device|reading' format.

When using the script, a nice rule of thumb is that flags in lower case (eg. -e) are 'query' flags and will not affect the operation of your system, devices attached to it, or the operation of the script itself. Upper case flags are 'control' flags and may turn devices off or modify the operation of your system. Please use them with care!


Usage
-----

You can run: 

	./alertmepi.pl -h

for more information, or take a look in the wiki.


Acknowledgements
----------------

The login and fetch parts of this script were based on Crispin Flowerday's 'houseTemp' perl script.