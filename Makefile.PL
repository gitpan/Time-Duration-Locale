#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

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

use 5.005;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Time-Duration-Locale',
   ABSTRACT     => 'Dispatch to language-specific Time::Duration module.',
   VERSION_FROM => 'lib/Time/Duration/Locale.pm',
   MIN_PERL_VERSION => '5.005',
   PREREQ_PM    => {
                    'Class::Singleton' => 0,
                    'Module::Load' => 0,
                    'Time::Duration' => 0,
                    'warnings' => 0,

                    'Test::More' => 0,
                   },

   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   clean        => { FILES => [ 'temp-lintian' ] },

   EXTRA_META => <<'HERE',
optional_features:
    maximum_languages:
        description: Have all language-specific Time::Duration modules available (those known at the time of writing ...).
        requires:
            Time::Duration::ja: 0
            Time::Duration::sv: 0
    maximum_tests:
        description: Have "make test" do as much as possible.
        requires:
            Parse::CPAN::Meta: 0
            Test::Pod: 1.00
            Test::NoWarnings: 0
            Test::DistManifest: 0
            Test::YAML::Meta: 0
            YAML: 0
            YAML::Syck: 0
            YAML::Tiny: 0
            YAML::XS: 0
no_index:
    directory:
        - t
        - devel
        - junk
        - maybe
resources:
    homepage: http://user42.tuxfamily.org/time-duration-locale/index.html
    license: http://www.gnu.org/licenses/gpl.html
HERE

# Not yet ...
#    META_MERGE
#    => { no_index => { directory => [ 'devel', 'junk', 'maybe' ] },
#         resources => { homepage => 'http://user42.tuxfamily.org/time-duration-locale/index.html',
#                        license => 'http://www.gnu.org/licenses/gpl.html',
#                      },
# 
#         optional_features
#         => { maximum_languages
#              => { description => 'Have all language-specific Time::Duration modules available (those known at the time of writing ...).',
#                   requires => { 'Time::Duration::ja' => 0,
#                                 'Time::Duration::sv' => 0,
#                               }
#                 },
#              maximum_tests
#              => { description => 'Have "make test" do as much as possible.',
#                   requires => { 'threads' => 0,
#                                 'Parse::CPAN::Meta' => 0,
#                                 'Test::Pod' => '1.00',
#                                 'Test::NoWarnings' => 0,
#                                 'Test::DistManifest' => 0,
#                                 'Test::YAML::Meta' => 0,
#                                 'YAML' => 0,
#                                 'YAML::Syck' => 0,
#                                 'YAML::Tiny' => 0,
#                                 'YAML::XS' => 0,
#                               },
#                 },
#            },
#       },
  );

sub MY::postamble {
  return <<'MAKE_FRAG';

deb: libtime-duration-locale-perl_$(VERSION)-1_all.deb
libtime-duration-locale-perl_$(VERSION)-1_all.deb: Time-Duration-Locale-$(VERSION).tar.gz
	rm -rf Time-Duration-Locale-$(VERSION)
	tar xfz Time-Duration-Locale-$(VERSION).tar.gz
	cd Time-Duration-Locale-$(VERSION) \
	  && dpkg-checkbuilddeps debian/control \
	  && fakeroot debian/rules binary
	rm -rf Time-Duration-Locale-$(VERSION)

LINT_FILES = $(TO_INST_PM) t/*.t examples/*.pl devel/*.pl
lint:
	perl -MO=Lint $(LINT_FILES)
pc:
	-podchecker $(LINT_FILES)
	perlcritic $(LINT_FILES)
unused:
	for i in $(LINT_FILES); do perl -Mwarnings::unused -I lib -c $$i; done

myman:
	-mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

# find files in the dist with mod times this year, but without this year in
# the copyright line
copyright-years-check:
	year=`date +%Y`; \
	tar tvfz $(DISTVNAME).tar.gz \
	| egrep '$$year-|debian/copyright' \
	| sed 's:^.*$(DISTVNAME)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat \
	      | t/pod.t \
	      | COPYING | MANIFEST* | SIGNATURE | META.yml) \
	      continue ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! grep -q "Copyright.*$$year" $$f; then \
	      echo "$$i":"1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

debug-constants-check:
	if egrep -n 'DEBUG => [^0]' $(TO_INST_PM); then exit 1; else exit 0; fi

diff-prev:
	rm -rf diff.tmp
	mkdir diff.tmp
	cd diff.tmp \
	&& tar xfz ../$(DISTNAME)-`expr $(VERSION) - 1`.tar.gz \
	&& tar xfz ../$(DISTNAME)-$(VERSION).tar.gz
	-cd diff.tmp; diff -ur $(DISTNAME)-`expr $(VERSION) - 1` \
	                       $(DISTNAME)-$(VERSION) >tree.diff
	-less diff.tmp/tree.diff
	rm -rf diff.tmp

lintian-source:
	DEB=`perl -e 'print lc("lib$(DISTNAME)-perl")'`; \
	echo $$DEB; \
	rm -rf temp-lintian; \
	mkdir temp-lintian; \
	cd temp-lintian; \
	cp ../$(DISTNAME)-$(VERSION).tar.gz $${DEB}_$(VERSION).orig.tar.gz; \
	tar xfz $${DEB}_$(VERSION).orig.tar.gz; \
	mv $(DISTNAME)-$(VERSION) $${DEB}-$(VERSION); \
	dpkg-source -b $${DEB}-$(VERSION) $${DEB}_$(VERSION).orig.tar.gz; \
	lintian -i *.dsc; \
	cd ..; \
	rm -rf temp-lintian

MAKE_FRAG
}
