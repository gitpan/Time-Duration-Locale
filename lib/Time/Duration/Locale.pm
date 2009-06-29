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

package Time::Duration::Locale;
use 5.005;
use strict;
use warnings;
use Carp;
use Time::Duration::LocaleObject;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

$VERSION = 1;

use Exporter;
@ISA = ('Exporter');

# same exports as Time::Duration
@EXPORT = qw(later later_exact earlier earlier_exact
             ago ago_exact from_now from_now_exact
             duration duration_exact
             concise);
@EXPORT_OK = ('interval', @EXPORT);
%EXPORT_TAGS = (all => \@EXPORT_OK);

use constant DEBUG => 0;

# subclassing Exporter
sub import {
  my $class = shift;

  # experimental undocumented '-language_preferences_ENV' or
  # '-language_preferences_Glib'
  if (@_ && $_[0] =~ /^-(.*)/) {
    Time::Duration::LocaleObject->languages_method ($1);
    shift;
  }

  return $class->SUPER::export_to_level (1, @_);
}

# SUPER::can() here is UNIVERSAL::can().  When an autoloaded function like
# duration() is exported, UNIVERSAL::can() returns the stub coderef which
# calls to AUTOLOAD.  This means AUTOLOAD() can't rely on can() to get the
# dispatcher func, it has to make its own.  Or unless can() oughtn't use
# SUPER::can this way ...
#
# If $name exists as a method in Time::Duration::LocaleObject, meaning a
# function in Time::Duration or langugage-specifc module, then create *$name
# so as to have just one copy of it for can() to return each time and so as
# not to go through AUTOLOAD() every time.
#
# If $name is unknown then don't create a dispatcher, firstly of course so
# can() is false, and secondly to avoid junking up the package if a caller
# gets a name wrong.
#
sub can {
  my ($class, $name) = @_;
  if (DEBUG) { print "TDL can $name\n"; }
  return $class->SUPER::can($name) || _make_dispatcher($name);
}
sub AUTOLOAD {
  my $name = $AUTOLOAD;
  if (DEBUG) { print "TDL autoload $name\n"; }
  $name =~ s/.*://;
  my $code = _make_dispatcher($name)
    || croak "No such function $name()";
  goto $code;
}

# The sub here is "by name".  Could instead go to the coderef returned by
# can(), like
#
#   sub { unshift @_, 'Time::Duration::LocaleObject'; goto $can; };
#
# Dunno if there's more merit in the name or the coderef.  The name would
# support redefinitions (the base TDLObj->can() returns the same subr every
# time).  The coderef might save a couple of cycles.
#
sub _make_dispatcher {
  my ($name) = @_;
  Time::Duration::LocaleObject->can($name) or return undef;
  my $subr = sub {
    if (DEBUG >= 2) { print "TDL dispatch to TDLObj->$name\n"; }
    return Time::Duration::LocaleObject->$name (@_);
  };
  { no strict 'refs'; *$name = $subr }
  return $subr;
}

1;
__END__

=head1 NAME

Time::Duration::Locale - time duration module chosen by locale

=head1 SYNOPSIS

 use Time::Duration::Locale;
 print "next update ",duration(150),"\n";

=head1 DESCRIPTION

C<Time::Duration::Locale> has the same interface as
L<C<Time::Duration>|Time::Duration> but chooses a language according to the
user's locale settings.

As of June 2009 the available language modules on CPAN include

    Time::Duration        English
    Time::Duration::ja    Japanese
    Time::Duration::sv    Swedish

If the user's locale setting is not one of these then the fallback is the
English module.

=head1 EXPORTS

Like C<Time::Duration>, the following functions are exported by default

    later
    later_exact
    earlier
    earlier_exact
    ago
    ago_exact
    from_now
    from_now_exact
    duration
    duration_exact
    concise

=head1 EXTRA FUNCTIONS

The following extra functions are provided by C<Time::Duration::Locale> and
are not exported.

=over 4

=item C<Time::Duration::Locale::setlocale ()>

Set the language from the current locale environment variables etc.

This is called automatically the first time one of the duration functions is
called.  Call it explicitly if you change the environment variables later
and want C<Time::Duration::Locale> to follow the new values.

=item C<$lang = Time::Duration::Locale::language ()>

=item C<Time::Duration::Locale::language ($lang)>

=item C<$module = Time::Duration::Locale::module ()>

=item C<Time::Duration::Locale::module ($module)>

Get or set the language to use, either in the form of a language code like
"en" or "ja", or a module name like "Time::Duration" or
"Time::Duration::ja".

C<undef> means a language has not been chosen yet.  When setting the
language the necessary module must exist and is loaded if not already
loaded.

=back

=head1 SEE ALSO

L<Time::Duration::LocaleObject>, L<Time::Duration>, L<Time::Duration::ja>
L<Time::Duration::sv>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/time-duration-locale/index.html>

=head1 COPYRIGHT

Copyright 2009 Kevin Ryde

Time-Duration-Locale is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Time-Duration-Locale is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Time-Duration-Locale.  If not, see L<http://www.gnu.org/licenses/>.

=cut
