#!/usr/bin/perl

# Copyright 2008, 2009, 2010 Kevin Ryde

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

use 5.004;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Time-Duration-Locale',
   ABSTRACT     => 'Dispatch to language-specific Time::Duration module.',
   VERSION_FROM => 'lib/Time/Duration/Locale.pm',

   # 5.004 for named vars in foreach, probably more
   MIN_PERL_VERSION => '5.004',

   PREREQ_PM    => {
                    'Class::Singleton' => 0,
                    'Module::Load' => 0,
                    'Time::Duration' => 0,
                    'warnings' => 0,

                    # version 0.30 for implicate_supers_strictly(), comes
                    # with perl 5.10
                    'I18N::LangTags' => '0.30',
                    'I18N::LangTags::Detect' => 0,

                    'Test::More' => 0,
                   },

   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   META_MERGE
   => { resources
        => { homepage => 'http://user42.tuxfamily.org/time-duration-locale/index.html' },

        optional_features
        => { maximum_languages
             => { description => 'Have all language-specific Time::Duration modules available (those known at the time of writing ...).',
                  requires => { 'Time::Duration::ja' => 0,
                                'Time::Duration::sv' => 0,
                              },
                },
             maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'threads' => 0,
                              },
                },
             maximum_devel
             => { description => 'Stuff used variously for development.',
                  requires => { 'Devel::Peek' => 0,
                              },
                },
           },
      },
  );

#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;
  return MyMakeMakerExtras::postamble ($makemaker);
}
