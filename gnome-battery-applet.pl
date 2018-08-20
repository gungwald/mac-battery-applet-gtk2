#!/usr/bin/perl

# mac-battery-applet.pl - Copyright © 2015 Bill Chatfield
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;

use Glib;
use Gtk2 '-init';

use constant BATTERY_ICON_DIR => '/home/bill/share/icons/battery';

use constant TRUE  => 1;
use constant FALSE => 0;
use constant UPDATE_INTERVAL => 10000; # Milliseconds

# Values for pmu_battery_info.flags in the Linux kernel file pmu.h
use constant PMU_BATT_PRESENT     => 0x00000001;
use constant PMU_BATT_CHARGING    => 0x00000002;
use constant PMU_BATT_TYPE_MASK   => 0x000000f0;
use constant PMU_BATT_TYPE_SMART  => 0x00000010; # Smart battery
use constant PMU_BATT_TYPE_HOOPER => 0x00000020; # 3400/3500 
use constant PMU_BATT_TYPE_COMET  => 0x00000030; # 2400

sub readPmuBatteryStatus;
sub readX86BatteryStatus;
sub readBatteryStatus;
sub updateBatteryIcon;
sub updateWithStdBatteryIcon;
sub detectDesktop;
sub isRunning($);

my $cpu = `uname -m`;

# Create a status icon object without specifying an icon. The icon will
# be specified later when we decide which variant of the icon should be
# displayed.
my $batteryIcon = new Gtk2::StatusIcon();

my $desktop = detectDesktop();
my $updateFunction;

if ($desktop ~~ ['gnome', 'unity', 'cinnamon', 'ubuntu']) {
    # The included icons look best on a black background.
    # First time display.
    #updateBatteryIcon();
    
    # Always use the standard icons because the custom icons are not
    # provided with this program.
    updateWithStdBatteryIcon();
    
    # Initialize the battery charge updater.
    #my $timer = Glib::Timeout->add(UPDATE_INTERVAL, \&updateBatteryIcon);
    my $timer = Glib::Timeout->add(UPDATE_INTERVAL, \&updateWithStdBatteryIcon);
}
elsif ($desktop ~~ ['mate', 'xfce4', 'lxde', 'gnome2' ]) {
    # The default icons look best on a non-black background.
    # First time display.
    updateWithStdBatteryIcon();
    # Initialize the battery charge updater.
    my $timer = Glib::Timeout->add(UPDATE_INTERVAL, \&updateWithStdBatteryIcon);
}
else {
    print STDERR "A Gtk-based panel is needed. $desktop does not have it.\n";
}

Gtk2->main;

# End of Main Program

sub readBatteryStatus
{
	if ($cpu =~ /86/) {
		return readX86BatteryStatus();
	}
	else {
		return readPmuBatteryStatus();
	}
}

sub readX86BatteryStatus
{
    my $batteryDir = "/sys/class/power_supply/BAT0";
    my $chargeFile = $batteryDir . "/capacity";
    my $statusFile = $batteryDir . "/status";
    my $charging = 0;
    open(CHARGE, $chargeFile) || return (0, 0, "$chargeFile: $!");
    my $charge = <CHARGE>;
    chomp($charge);
    close(CHARGE);
    open(STATUS, $statusFile) || return ($charge, 0, "$statusFile: $!");
    my $status = <STATUS>;
    chomp($status);
    close(STATUS);
    if ($status eq "Charging") {
        $charging = 1;
    }
    else {
	$charging = 0;
    }
    return ($charge, $charging);
}

# Reads the current battery info from /proc file system.
# Returns the current charge as an unformatted percent value.
sub readPmuBatteryStatus
{
    my $batteryFile = "/proc/pmu/battery_0";
    my $charge;
    my $maxCharge;
    my $isCharging = 0;
    my $remainingPower;

    open(BATTERY, $batteryFile) || return (0, 0, "$batteryFile: $!");
    while (<BATTERY>) {
        my ($key, $value) = /(\w*)\s*:\s*(\w*)/;
        if ($key) {
            if ($key eq 'charge') {
                $charge = $value;
            }
            elsif ($key eq 'max_charge') {
                $maxCharge = $value;
            }
            elsif ($key eq 'flags') {
            	$isCharging = hex($value) & PMU_BATT_CHARGING;
            }
        }
    }
    close(BATTERY);
    $remainingPower = $charge / $maxCharge * 100;
    return ($remainingPower, $isCharging);
}

# Puts the current battery info into the UI.
sub updateBatteryIcon
{
    my ($power, $isCharging, $errorMessage) = readBatteryStatus();
    my $iconName;
    
    if ($errorMessage) {
        $batteryIcon->set_tooltip($errorMessage);
        $iconName = 'battery-0%-power';
    }
    else {
        my $direction = 'draining';

        if ($isCharging) {
            $direction = 'charging';
        }

        my $tooltip = sprintf("Power at %0.0f%% and %s", $power, $direction);
        $batteryIcon->set_tooltip($tooltip);

        if ($power >= 90) {
            $iconName = 'battery-90%-power';
        }
        elsif ($power >= 80) {
            $iconName = 'battery-80%-power';
        }
        elsif ($power >= 70) {
            $iconName = 'battery-70%-power';
        }
        elsif ($power >= 60) {
            $iconName = 'battery-60%-power';
        }
        elsif ($power >= 50) {
            $iconName = 'battery-50%-power';
        }
        elsif ($power >= 40) {
            $iconName = 'battery-40%-power';
        }
        elsif ($power >= 30) {
            $iconName = 'battery-30%-power';
        }
        elsif ($power >= 20) {
            $iconName = 'battery-20%-power';
        }
        elsif ($power >= 10) {
            $iconName = 'battery-10%-power';
        }
        else {
            $iconName = 'battery-0%-power';
        }
        if ($isCharging) {
            $iconName .= '-charging';
        }
        $iconName .= '.xpm';
        $iconName = BATTERY_ICON_DIR . '/' . $iconName;
    }
    $batteryIcon->set_from_file($iconName);

    # Returning true keeps this timer installed.
    return TRUE;
}

# Puts the current battery info into the UI.
sub updateWithStdBatteryIcon
{
    my ($power, $isCharging, $errorMessage) = readBatteryStatus();
    my $iconName;
    
    if ($errorMessage) {
        $batteryIcon->set_tooltip($errorMessage);
        $iconName = 'battery-missing';
    }
    else {
        my $direction = 'draining';

        if ($isCharging) {
            $direction = 'charging';
        }

        my $tooltip = sprintf("Power at %0.0f%% and %s", $power, $direction);
        $batteryIcon->set_tooltip($tooltip);

        if ($power >= 90) {
            $iconName = 'battery-full';
        }
        elsif ($power >= 20) {
            $iconName = 'battery-good';
        }
        elsif ($power >= 10) {
            $iconName = 'battery-low';
        }
        elsif ($power >= 5) {
            $iconName = 'battery-caution';
        }
        else {
            $iconName = 'battery-empty';
        }

        if ($isCharging && $iconName ne 'battery-empty') {
            # The 'battery-empty' icon does not have a 'charging' option.
            $iconName .= '-charging';
        }
    }
    $batteryIcon->set_from_icon_name($iconName);

    # Returning true keeps this timer installed.
    return TRUE;
}

# From http://stackoverflow.com/questions/2035657/what-is-my-current-desktop-environment
# and http://ubuntuforums.org/showthread.php?t=652320
# and http://ubuntuforums.org/showthread.php?t=652320
# and http://ubuntuforums.org/showthread.php?t=1139057
sub detectDesktop 
{
    if ($^O =~ /MSWin/ || $^O =~ /cygwin/i) {
        return 'windows';
    }
    elsif ($^O eq 'darwin') {
        return 'mac';
    }
    else {
        # Most likely either a POSIX system or something uncommon
        my $desktop = $ENV{DESKTOP_SESSION};

        if ($desktop) { 

            # Easier to match if we don't have to deal with character cases
            $desktop = lc($desktop);

            if ($desktop ~~ ["gnome", "unity", "cinnamon", "mate", "xfce4",
                             "lxde", "fluxbox", "blackbox", "openbox", 
                             "icewm", "jwm", "afterstep", "trinity", "kde"]) {
                return $desktop;
            }

            # Special cases: Canonical sets $DESKTOP_SESSION to Lubuntu 
            # rather than LXDE if using LXDE. There is no guarantee that 
            # they will not do the same with the other desktop environments.
            if ($desktop =~ /xfce/ || $desktop =~ /^xubuntu/) {
                return "xfce4";
            }
            elsif ($desktop =~ /^ubuntu/) {
                return "unity";
            }
            elsif ($desktop =~ /^lubuntu/) {
                return "lxde";
            }
            elsif ($desktop =~ /^kubuntu/) { 
                return "kde";
            }
            elsif ($desktop =~ /^razor/) {  # e.g. razorkwin
                return "razor-qt";
            }
            elsif ($desktop =~ /^wmaker/) { # e.g. wmaker-common
                return "windowmaker";
            }
        }

        if ($ENV{KDE_FULL_SESSION} eq 'true') {
            return "kde";
        }
        elsif ($ENV{GNOME_DESKTOP_SESSION_ID} =~ /deprecated/) {
            return "gnome2";
        }

        # From http://ubuntuforums.org/showthread.php?t=652320
        if (isRunning("xfce-mcs-manage")) {
            return "xfce4";
        }
        elsif (isRunning("ksmserver")) {
            return "kde";
        }
        elsif (isRunning("xfce4-session")) {
            return "xfce4";
        }
    }
    return "unknown";
}

# From http://www.bloggerpolis.com/2011/05/how-to-check-if-a-process-is-running-using-python/
# and http://richarddingwall.name/2009/06/18/windows-equivalents-of-ps-and-kill-commands/
sub isRunning($) 
{
    my ($process) = @_;
    if ($^O =~ /^MSWin/ && `tasklist /v` =~ /$process/) {
        return 1;
    }
    elsif (`ps axw` =~ /$process/) {
        return 1;
    }
    else {
        return 0;
    }
}
