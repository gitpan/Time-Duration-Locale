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

package Time::Duration::LocaleObject;
use 5.005;
use strict;
use warnings;
use Carp;
use Module::Load;
use vars qw($VERSION @ISA $AUTOLOAD);

use Class::Singleton;
@ISA = ('Class::Singleton');
*_new_instance = \&new;

$VERSION = 3;

use constant DEBUG => 0;

sub new {
  my ($class, %self) = @_;
  my $self = bless \%self, $class;

  # Load language module now, if given.  You're not supposed to pass both
  # 'module' and 'language', but for now the latter has precedence.
  #
  if (my $module = delete $self{'module'}) {
    $self->module ($module);
  }
  if (my $lang = delete $self{'language'}) {
    $self->language ($lang);
  }

  return $self;
}

# don't go through AUTOLOAD
sub DESTROY {}

sub module {
  my $self = shift;
  ref $self or $self = $self->instance;
  if (@_) {
    # set
    my ($module) = @_;
    if (defined $module) {
      # guard against infinite recursion on Time::Duration::Locale
      if ($module eq 'Time::Duration::Locale'
          || $module eq 'Time::Duration::LocaleObject') {
        croak 'Don\'t set module to Locale or LocaleObject';
      }
      Module::Load::load ($module);
    }
    $self->{'module'} = $module;
  }
  # get
  return $self->{'module'};
}

sub language {
  my $self = shift;
  ref $self or $self = $self->instance;
  if (@_) {
    # set
    my ($lang) = @_;
    $self->module (_language_to_module ($lang));
  }
  # get
  my $module = $self->{'module'};
  return (defined $module ? _module_to_language($module) : undef);
}

# maybe it'd be easier to create a Time::Duration::en than mangle the names
sub _language_to_module {
  my ($lang) = @_;
  return ($lang eq 'en' ? 'Time::Duration' : "Time::Duration::$lang");
}
sub _module_to_language {
  my ($module) = @_;
  return ($module eq 'Time::Duration' ? 'en'
          : $module =~ /^Time::Duration::(.*)/ ? $1
          : $module);
}

#------------------------------------------------------------------------------
# languages_method() and language_preferences() not yet documented
# ... don't use them

use constant DEFAULT_LANGUAGES_METHOD => 'language_preferences_ENV';

sub languages_method {
  my $self = shift;
  ref $self or $self = $self->instance;
  if (@_) {
    my ($method) = @_;
    $self->{'languages_method'} = $method;
  }
  return ($self->{'languages_method'} || DEFAULT_LANGUAGES_METHOD);
}

sub language_preferences {
  my ($class_or_self) = shift;
  my $method = $class_or_self->languages_method;
  return $class_or_self->$method;
}
sub language_preferences_Glib {
  if (DEBUG) { print "language_preferences_Glib()\n"; }
  require Glib;
  return Glib::get_language_names();
}
sub language_preferences_ENV {
  my @langs;

  # cf Locale::gettext_pp::__load_domain()
  if (defined $ENV{'LANGUAGE'}) {
    unshift @langs, split /:/, $ENV{'LANGUAGE'};
    # double say 'it' to 'it_IT' the same as gettext does; though there's no
    # modules on cpan named like that as of June 2009
    @langs = map {/^([^_]*)$/s ? ($_, "$1_\U$1") : ($_)} @langs;
  }
  push @langs,
    ($ENV{'LC_ALL'} || ''),
      ($ENV{'LC_MESSAGES'} || ''),
        ($ENV{'LANG'} || '');

  # lose trailing codeset, so say 'en_IN.UTF8' -> 'en_IN'
  foreach (@langs) { s/\..*//s }

  # lose possible empty strings
  return grep {$_ ne ''} @langs;
}

#------------------------------------------------------------------------------
# setlocale

sub setlocale {
  my ($self) = @_;
  ref $self or $self = $self->instance;
  if (DEBUG) { print "TDLObj setlocale()\n"; }

  my @langs = $self->language_preferences;

  # Replicate without territory, so say it_IT,sv -> it_IT,sv,it.
  # This is an append to @langs so en_AU,en_GB -> en_AU,en_GB,en, thereby
  # preserving the territory preferences before falling back to generics.
  #
  push @langs, (map {/(.*)_/s ? $1 : ()} @langs);

  # default to plain 'Time::Duration'
  push @langs, 'en';

  if (DEBUG) { print "  try langs: ",join(',',@langs),"\n"; }

  my %seen;
  my $error;
  foreach my $lang (@langs) {
    next if $seen{$lang}++;
    if (eval { $self->language($lang); 1 }) {
      # return value not documented ... don't use it yet
      return $lang;
    }
    $error = $@;
    if (DEBUG) { print "  $lang - error $error\n"; }
  }
  croak "Time::Duration not available -- $error";
}

#------------------------------------------------------------------------------
# call-through

sub can {
  my ($self, $name) = @_;
  if (DEBUG) { print "TDLObj can $name\n"; }
  return $self->SUPER::can($name) || _make_dispatcher($self,$name);
}
sub AUTOLOAD {
  my $name = $AUTOLOAD;
  if (DEBUG) { print "TDLObj autoload $name\n"; }
  $name =~ s/.*://;
  my $code = _make_dispatcher($_[0],$name)
    || croak "No such function $name()";
  goto $code;
}

use vars '$_make_dispatcher';
sub _make_dispatcher {
  my ($class_or_self, $name) = @_;
  if (DEBUG) { print "TDLObj _make_dispatcher $class_or_self $name\n"; }

  # $_make_dispatcher is recursion protection against bad
  # language_preferences method, or any other undefined method module() or
  # setlocale() might accidentally call here.
  if ($_make_dispatcher
      || do {
        local $_make_dispatcher = 1;
        $class_or_self->module || $class_or_self->setlocale;
        my $module = $class_or_self->module;
        if (DEBUG) { print "  check target $module\n"; }
        ! $module->can($name) }) {
    return undef;
  }

  my $subr = sub {
    if (DEBUG >= 2) { print "TDLObj->$name dispatch\n"; }

    my $self = shift;
    ref $self or $self = $self->instance;
    $self->{'module'} || $self->setlocale;

    my $target = "$self->{'module'}::$name";
    no strict 'refs';
    return &$target(@_);
  };
  { no strict 'refs'; *$name = $subr }
  return $subr;
}

1;
__END__

=head1 NAME

Time::Duration::LocaleObject - time duration chosen by an object

=head1 SYNOPSIS

 use Time::Duration::LocaleObject;
 my $tdl = Time::Duration::LocaleObject->new;
 print "next update: ", $tdl->duration(120) ,"\n";

=head1 DESCRIPTION

C<Time::Duration::LocaleObject> is an object-oriented wrapper around
possible language-specific C<Time::Duration> modules.  The methods
correspond to the function calls in those modules.  The target module is
established from the user's locale, or can be set explicitly.

Most of the time this module is unnecessary, a single global choice based on
the locale is enough, per
L<C<Time::Duration::Locale>|Time::Duration::Locale>.  But some OOPery is not
too much more trouble than a plain functions module and it's handy if your
program works with multiple locales more or less simultaneously (something
pretty painful with the POSIX global-only things).

=head1 METHODS

In the following methods TDLObj means either a LocaleObject instance or the
class name C<Time::Duration::Locale>.

    print Time::Duration::LocaleObject->ago(120);
    print $tdl->ago(120);

The class name form operates on a global singleton instance which is used by
C<Time::Duration::Locale>.

=head2 Creation

=over 4

=item C<Time::Duration::LocaleObject-E<gt>new (key =E<gt> value, ...)>

Create and return a new LocaleObject.  Optional key/value pairs can give an
initial C<module> or C<language> as per the settings below, instead of using
the locale settings.

    # for locale settings
    my $tdl = Time::Duration::LocaleObject->new;

    # for explicit language
    my $tdl = Time::Duration::LocaleObject->new (language => 'ja');

    # for explicit language specified by module
    my $tdl = Time::Duration::LocaleObject->new
                (module => 'Time::Duration::la_PIG');

=back

=head2 Duration Methods

As per the C<Time::Duration> functions.  (Any new future functions should
work too, methods pass through transparently.)

=over 4

=item C<TDLObj-E<gt>later ($seconds, [$precision])>

=item C<TDLObj-E<gt>later_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>earlier ($seconds, [$precision])>

=item C<TDLObj-E<gt>earlier_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>ago ($seconds, [$precision])>

=item C<TDLObj-E<gt>ago_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>from_now ($seconds, [$precision])>

=item C<TDLObj-E<gt>from_now_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>duration ($seconds, [$precision])>

=item C<TDLObj-E<gt>duration_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>concise ($str)>

=back

=head2 Settings Methods

=over 4

=item C<$lang = TDLObj-E<gt>language ()>

=item C<TDLObj-E<gt>language ($lang)>

=item C<$module = TDLObj-E<gt>module ()>

=item C<TDLObj-E<gt>module ($module)>

Get or set the language to use, either in the form of a language code like
"en" or "ja", or a module name like "Time::Duration" or
"Time::Duration::ja".

A setting C<undef> means no language has yet been selected.  When setting
the language the necessary module must exist and is loaded if not already
loaded.

=item C<TDLObj-E<gt>setlocale ()>

Set the language according to the user's locale settings such as the
C<LANGUAGE> and C<LANG> environment variables.

This is called automatically by the duration methods above if no language
has otherwise been set, so there's normally no need to explicitly
C<setlocale>.  But call it if you change the environment variables and want
TDLObj to follow.

=back

=head1 OTHER NOTES

In the current implementation C<can()> checks whether the target module has
such a function.  This is probably what you want, though a later change of
language could reveal extra funcs in another module.  In any case a C<can()>
subr of course follows the module of its target object when called, not
whatever it saw when created.

A C<can()> subr returned is stored as a method in the
C<Time::Duration::LocaleObject> symbol table, as a cache against future
C<can()> calls and to bypass C<AUTOLOAD> if later invoked by name.  Not sure
if this is worth the trouble.

=head1 SEE ALSO

L<Time::Duration::Locale>, L<Time::Duration>, L<Time::Duration::ja>
L<Time::Duration::sv>

=head1 HOME PAGE

http://user42.tuxfamily.org/time-duration-locale/index.html

=head1 COPYRIGHT

Copyright 2009, 2010 Kevin Ryde

Time-Duration-Locale is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Time-Duration-Locale is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

=cut
