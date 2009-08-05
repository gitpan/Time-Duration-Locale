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
use Time::Duration::LocaleObject;
use Test::More;

use Config;
$Config{useithreads}
  or plan skip_all => 'No ithreads in this Perl';

plan tests => 2;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

# This is only meant to check that any CLONE() done by threads works with
# the AUTOLOAD() and/or can() stuff.
#

$ENV{'LANGUAGE'} = 'en';
my $tdl = Time::Duration::LocaleObject->new;
$tdl->setlocale;

require threads;
my $thr = threads->create(\&foo);
sub foo {
  return $tdl->ago(0);
}

my @ret = $thr->join;
is_deeply (\@ret, [$tdl->ago(0)], 'same in thread as main');

exit 0;