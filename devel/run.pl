#!/usr/bin/perl

# Copyright 2009 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
BEGIN {
  $ENV{'LANGUAGE'} = 'en:sv';
}
use Time::Duration::Locale '-language_preferences_Glib';


# Time::Duration::Locale::setlocale();
{
  my $module = Time::Duration::Locale::module();
  print "module ",(defined $module ? $module : 'undef'), "\n";
}
print "main duration() is ",\&duration,"\n";
{
  require Time::Duration;
  print "Time::Duration::duration() is ",\&Time::Duration::duration,"\n";
}

print duration(123),"\n";

$ENV{'LANGUAGE'} = 'it:sv';
Time::Duration::Locale::setlocale();
{
  my $module = Time::Duration::Locale::module();
  print "module ",(defined $module ? $module : 'undef'), "\n";
}

print duration(150),"\n";

exit 0;
