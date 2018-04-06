use strict;
use warnings;
package RT::Extension::ThreadByReference;

our $VERSION = '0.02';

=head1 NAME

RT-Extension-ThreadByReference - Use the MIME Reference header to try and thread messages to tickets

=head1 DESCRIPTION

When an RT ticketing queue is CCed on a message thread, it can be very
difficult to get the subject lines correct in all parts of the
message.  This can cause a single thread to spawn off tens of
different tickets that need manual merging.

This extension uses the MIME Reference header to search for threads
to associate a message with.

=head1 RT VERSION

Works with RT 4.4 and greater.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ThreadByReference');

Then make sure you load 'ThreadByReference' where you set MailPlugins.
If you don't use this setting already, that's:

    Set(@MailPlugins, qw(ThreadByReference));

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Harlan Lieberman-Berg C<< <hlieberm@akamai.com> >>
Brett Smith C<< <brettcsmith@brettcsmith.org> >>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ThreadByReference@rt.cpan.org|mailto:bug-RT-Extension-ThreadByReference@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ThreadByReference>.

=head1 LICENSE

Copyright (c) 2015-2016 by Akamai Technologies, Inc.
Copyright (c) 2018 Brett Smith

This software is free software; you can redistribute and/or modify it
under the same terms as Perl itself.

=cut

1;
