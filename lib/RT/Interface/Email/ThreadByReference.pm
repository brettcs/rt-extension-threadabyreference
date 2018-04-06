package RT::Interface::Email::ThreadByReference;

use strict;
use warnings;

use Role::Basic 'with';
with 'RT::Interface::Email::Role';

use RT::Interface::Email ();

sub BeforeDecrypt {
    $RT::Logger->debug("Entering ThreadByReference");

    my %args = (
	Message       => undef,
	RawMessage    => undef,
	Actions       => undef,
	Queue         => undef,
	@_
	);

    if (my $ticket_id = RT::Interface::Email::ExtractTicketId($args{'Message'})) {
	$RT::Logger->debug(sprintf("Ticket %s already assigned.  You don't need my help!", 
			   $ticket_id));
	return;
    }

    my $head = $args{'Message'}->head();
    my @messageids = FetchPossibleHeaders($head);

    unless (scalar @messageids >= 1) {
	$RT::Logger->debug("Message contains no headers!");
	return;
    }

    my %tickets = ();
    foreach my $messageid (@messageids) {
	if (my @ticket_ids = MessageIdToTickets($messageid)) {
	    foreach my $ticket (@ticket_ids) {
		$tickets{$ticket} = undef;
	    }
	}
    }
    
    my @tickets = keys(%tickets);
    my $ticket_count = scalar(@tickets);
    if ($ticket_count == 0) {
	$RT::Logger->debug("No tickets for references found.");
	return;
    }
    elsif ($ticket_count > 1) {
	$RT::Logger->warning("Email maps to more than one ticket.");
	$RT::Logger->warning(sprintf("Tickets: %s", @tickets));
    }
    $RT::Logger->debug(sprintf("Threading email in ticket %s", $tickets[0]));
    my $subject = Encode::decode("UTF-8", $head->get('Subject') || '');
    $head->replace('Subject', RT::Interface::Email::AddSubjectTag($subject, $tickets[0]));
}

sub FetchPossibleHeaders {
    my $head = shift();

    my @msgids = ();

    # There may be multiple references
    # In practice, In-Reply-To seems to no longer be worth parsing, as
    # it seems to usually just be a repeat of the References.
    if (my $refs = $head->get('References')) {
	chomp($refs);

	foreach my $ref (split(/\s+/, $refs)) {
	    $ref =~ /,?<([^>]+)>/;
	    if ($1) {
		push(@msgids, $1);
		$RT::Logger->debug(sprintf("Found reference: %s", $1));
	    }
	    else {
		$RT::Logger->debug(sprintf("Reference with borked syntax: %s", $ref));
		next;
	    }
	}
    }
    return @msgids;
}

sub MessageIdToTickets {
    # Copied heavily from rt-references
    my $id = shift();

    my $attachments = RT::Attachments->new($RT::SystemUser);
    $attachments->Limit(
	FIELD => 'MessageId',
	OPERATOR => '=',
	VALUE => $id
	);
    $attachments->Limit(
	FIELD => 'Parent',
	OPERATOR => '=',
	VALUE => '0'
	);

    # Link attachments to their transactions, then transactions to
    # their tickets.
    my $trans = $attachments->NewAlias('Transactions');
    my $tkts = $attachments->NewAlias('Tickets');
    
    $attachments->Join(
	ALIAS1 => 'main',
	FIELD1 => 'TransactionId',
	ALIAS2 => $trans,
	FIELD2 => 'id'
	);
    $attachments->Join(
	ALIAS1 => $trans,
	FIELD1 => 'ObjectID',
	ALIAS2 => $tkts,
	FIELD2 => 'id'
	);
    $attachments->Limit(
	ALIAS => $trans,
	FIELD => 'objecttype',
	OPERATOR => '=',
	VALUE => 'RT::Ticket'
	);

    $RT::Logger->debug($attachments->BuildSelectQuery());
    my %tickets = ();
    while (my $attach = $attachments->Next) {
	my $transaction = $attach->TransactionObj();
	my $ticket_id = $transaction->Ticket();
	$RT::Logger->debug(sprintf("Match for message <%s>: attachment %s, transaction %s, ticket %s",
				   $id, $attach->id, $transaction->id, $ticket_id));
	$tickets{$ticket_id} = undef;
    }

    return keys(%tickets);
}

1;
