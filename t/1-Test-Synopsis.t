#!/usr/bin/perl

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


## no critic (ProhibitCallsToUndeclaredSubs)

use strict;
use warnings;
use Test::More;

eval 'use Test::Synopsis; 1'
  or plan skip_all => "due to Test::Synopsis not available -- $@";

plan tests => 3;

# exclude lib/Time/Duration/Filter.pm as its synopsis code depends on
# Time::Duration::sv
#
synopsis_ok('lib/Time/Duration/Locale.pm');
synopsis_ok('lib/Time/Duration/LocaleObject.pm');
synopsis_ok('lib/Time/Duration/en_PIGLATIN.pm');


exit 0;
