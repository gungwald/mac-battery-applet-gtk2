PROGRAM: gnome-battery-applet.pl
AUTHOR:  Bill Chatfield <bill_chatfield@yahoo.com>
LICENSE: GPL 3.0

![Screenshot](/docs/images/gtk2-battery-closeup.png?raw=true "Screenshot of Mate with fully charged battery")

![Screenshot](/docs/images/gtk-battery-closeup-blue.png?raw=true "Screenshot of Mate with the Mac Battery Applet")

DESCRIPTION

This is a Linux app for Gtk2 which displays the
battery status in an icon on the top panel. It should work with the Mate and
Xfce desktops. It will also work with Gnome 3 but because it uses Gtk2
instead of Gtk3, some of the UI elements will look different from the rest
of the desktop applets.

It was developed and tested on Debian Wheezy 7.8. It should work on x86 Linux and on any 
PowerPC-based Mac running Linux. It probably won't work on BSD because it
reads the battery info from /proc/pmu.

Because the PowerPC Macs have a different type of power unit (PMU), the normal
battery applets for Intel hardware do not work. There was an emulator but it 
is non-functional now.

This program is written in Perl. I like Perl because it is very powerful,
allowing one to accomplish a lot with little time and effort. Yes, I know
about Python and can I write it, but I prefer Perl, after giving Python a
good try with several programs. 

If you like Python, it is OK with me. There are very good reasons to choose 
Python as your preferred language. I'm glad our choices are not limited to 
one language but that we can each choose to work with the language we prefer.


REQUIREMENTS

* x86 PC or PowerPC Macintosh with a PMU power unit - G3, G4, G5
* Linux
* Perl
* Gtk2 (Mate, Xfce, Gnome)
* The libgtk2-perl Debian package. Run: aptitude install libgtk2-perl


INSTALLATION

The gnome-battery-applet.pl is the file you want to run. You can put it where
ever you prefer. I would suggest /usr/local/bin. Make it executable:

        chmod a+x gnome-battery-applet.pl

It uses the icons that are installed by default with Gnome/Mate.


GNOME AUTO-START SETUP

To configure it to start when Mate is started, add an entry for
/usr/local/bin/gnome-battery-applet.pl to "Startup Applications"
(System -> Preferences -> Startup Applications).


DEBIAN PACKAGE

I wanted to provide a .deb package. But after reading all the documentation,
rules, commands, processes and procedures associated with doing this, I no
longer have the desire to do this. My goal instead is to make this easy to
compile and install with a simple Makefile. Maybe someone else will suffer
the process of creating a Debian package.
