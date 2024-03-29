#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::RealBin,'lib');
use Time::Duration::Upper;

print "Upper ISA ",@Time::Duration::Upper::ISA,"\n";
print "Upper AUTOLOAD ",
  (defined &Time::Duration::Upper::AUTOLOAD ? "defined" : "not defined"), "\n";
print "Upper AUTOLOAD ", \&Time::Duration::Upper::AUTOLOAD, "\n";

# use vars '$AUTOLOAD';
# $AUTOLOAD = 'Time::Duration::Upper::duration';
# Time::Duration::Upper::AUTOLOAD();
#print Time::Duration::Upper::foo(45*86400+6*3600),"\n";

print "main duration() is ",\&duration,"\n";
print duration(45*86400+6*3600),"\n";

exit 0;
