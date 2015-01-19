#######################################################################
#
#  DBD::AnyData2 - a DBI driver for AnyData2 files
#
#  Copyright (c) 2015 by Jens Rehsack
#
#  All rights reserved.
#
#  You may freely distribute and/or modify this  module under the terms
#  of either the GNU  General Public License (GPL) or the Artistic License,
#  as specified in the Perl README file.
#
#  USERS - see the pod at the bottom of this file
#
#  DBD AUTHORS - see the comments in the code
#
#######################################################################
require 5.008;
use strict;
use warnings;

#################
package DBD::AnyData2;
#################
use base qw(DBD::File);
use vars qw($VERSION $ATTRIBUTION $drh $methods_already_installed);
$VERSION     = '0.001';
$ATTRIBUTION = 'DBD::AnyData2 by Jens Rehsack';

use AnyData2;

# no need to have driver() unless you need private methods
#
sub driver ($;$)
{
    my ( $class, $attr ) = @_;
    return $drh if ($drh);

    # do the real work in DBD::File
    #
    $attr->{Attribution} = 'DBD::AnyData2 by Jens Rehsack';
    $drh = $class->SUPER::driver($attr);

    # install private methods
    #
    # this requires that ad2_ (or foo_) be a registered prefix
    # but you can write private methods before official registration
    # by hacking the $dbd_prefix_registry in a private copy of DBI.pm
    #
    #unless ( $methods_already_installed++ )
    #{
    #    DBD::AnyData2::st->install_method('ad2_schema');
    #}

    return $drh;
}

sub CLONE
{
    undef $drh;
}

#####################
package DBD::AnyData2::dr;
#####################
$DBD::AnyData2::dr::imp_data_size = 0;
@DBD::AnyData2::dr::ISA           = qw(DBD::File::dr);

# you could put some :dr private methods here

# you may need to over-ride some DBD::File::dr methods here
# but you can probably get away with just letting it do the work
# in most cases

#####################
package DBD::AnyData2::db;
#####################
$DBD::AnyData2::db::imp_data_size = 0;
@DBD::AnyData2::db::ISA           = qw(DBD::File::db);

use Carp qw/carp/;

sub set_versions
{
    my $this = $_[0];
    $this->{ad2_version} = $DBD::AnyData2::VERSION;
    return $this->SUPER::set_versions();
}

sub init_valid_attributes
{
    my $dbh = shift;

    # define valid private attributes
    #
    # attempts to set non-valid attrs in connect() or
    # with $dbh->{attr} will throw errors
    #
    # the attrs here *must* start with ad2_ or foo_
    #
    # see the STORE methods below for how to check these attrs
    #
    $dbh->{ad2_valid_attrs} = {
                                ad2_version        => 1,    # verbose DBD::AnyData2 version
                                ad2_valid_attrs    => 1,    # DBD::AnyData2::db valid attrs
                                ad2_readonly_attrs => 1,    # DBD::AnyData2::db r/o attrs
                                ad2_meta           => 1,    # DBD::AnyData2 public access for f_meta
                                ad2_tables         => 1,    # DBD::AnyData2 public access for f_meta
                              };
    $dbh->{ad2_readonly_attrs} = {
                                   ad2_version        => 1,    # verbose DBD::AnyData2 version
                                   ad2_valid_attrs    => 1,    # DBD::AnyData2::db valid attrs
                                   ad2_readonly_attrs => 1,    # DBD::AnyData2::db r/o attrs
                                   ad2_meta           => 1,    # DBD::AnyData2 public access for f_meta
                                 };

    $dbh->{ad2_meta} = "ad2_tables";

    return $dbh->SUPER::init_valid_attributes();
}

sub get_ad2_versions
{
    my ( $dbh, $table ) = @_;
    $table ||= '';

    my $meta;
    my $class = $dbh->{ImplementorClass};
    $class =~ s/::db$/::Table/;
    $table and ( undef, $meta ) = $class->get_table_meta( $dbh, $table, 1 );
    $meta or ( $meta = {} and $class->bootstrap_table_meta( $dbh, $meta, $table ) );

    return sprintf( "%s using %s", $dbh->{ad2_version}, $AnyData2::VERSION );
}


############################
package DBD::AnyData2::Statement;
############################

@DBD::AnyData2::Statement::ISA = qw(DBD::File::Statement);

########################
package DBD::AnyData2::Table;
########################

1;
__END__
=pod

=head1 NAME

DBD::AnyData2 - a DBI driver for AnyData2

=head1 SYNOPSIS

 use DBI;
 $dbh = DBI->connect('dbi:AnyData2:');
 $dbh = DBI->connect('DBI:AnyData2(RaiseError=1):');

 # or
 $dbh = DBI->connect('dbi:AnyData2:', undef, undef);
 $dbh = DBI->connect('dbi:AnyData2:', undef, undef, {
   ...
 });

and other variations on connect() as shown in the L<DBI> docs,
L<DBD::File metadata|DBD::File/Metadata> and L</Metadata>
shown below.

Use standard DBI prepare, execute, fetch, placeholders, etc.,
see L<QUICK START> for an example.

=head1 DESCRIPTION

DBD::AnyData2 is a database management system that works right out of the
box.  If you have a standard installation of Perl and DBI you can begin
creating, accessing, and modifying simple database tables without any
further modules.

=head1 QUICK START

...

=head1 BUGS AND LIMITATIONS

This module uses hash interfaces of two column file databases. While
none of supported SQL engines have support for indices, the following
statements really do the same (even if they mean something completely
different) for each dbm type which lacks C<EXISTS> support:

  $sth->do( "insert into foo values (1, 'hello')" );

  # this statement does ...
  $sth->do( "update foo set v='world' where k=1" );
  # ... the same as this statement
  $sth->do( "insert into foo values (1, 'world')" );

This is considered to be a bug and might change in a future release.

=head1 GETTING HELP, MAKING SUGGESTIONS, AND REPORTING BUGS

If you need help installing or using DBD::AnyData2, please write to the DBI
users mailing list at dbi-users@perl.org or to the
comp.lang.perl.modules newsgroup on usenet.  I cannot always answer
every question quickly but there are many on the mailing list or in
the newsgroup who can.

DBD developers for DBD's which rely on DBD::File or DBD::AnyData2 or use
one of them as an example are suggested to join the DBI developers
mailing list at dbi-dev@perl.org and strongly encouraged to join our
IRC channel at L<irc://irc.perl.org/dbi>.

If you have suggestions, ideas for improvements, or bugs to report, please
report a bug as described in DBI. Do not mail any of the authors directly,
you might not get an answer.

When reporting bugs, please send the output of $dbh->dbm_versions($table)
for a table that exhibits the bug and as small a sample as you can make of
the code that produces the bug.  And of course, patches are welcome, too
:-).

If you need enhancements quickly, you can get commercial support as
described at L<http://dbi.perl.org/support/> or you can contact Jens Rehsack
at rehsack@cpan.org for commercial support in Germany.

Please don't bother Jochen Wiedmann or Jeff Zucker for support - they
handed over further maintenance to H.Merijn Brand and Jens Rehsack.

=head1 ACKNOWLEDGEMENTS

Many, many thanks to Tim Bunce for prodding me to write this, and for
copious, wise, and patient suggestions all along the way. (Jeff Zucker)

I send my thanks and acknowledgements to H.Merijn Brand for his
initial refactoring of DBD::File and his strong and ongoing support of
SQL::Statement. Without him, the current progress would never have
been made.  And I have to name Martin J. Evans for each laugh (and
correction) of all those funny word creations I (as non-native
speaker) made to the documentation. And - of course - I have to thank
all those unnamed contributors and testers from the Perl
community. (Jens Rehsack)

=head1 AUTHOR AND COPYRIGHT

This module is written by Jens Rehsack < rehsack AT cpan.org >.

 Copyright (c) 2015 by Jens Rehsack, all rights reserved.

You may freely distribute and/or modify this module under the terms of
either the GNU General Public License (GPL) or the Artistic License, as
specified in the Perl README file.

=head1 SEE ALSO

L<DBI>,
L<SQL::Statement>, L<DBI::SQL::Nano>

=cut
