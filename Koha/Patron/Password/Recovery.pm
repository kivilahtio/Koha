package Koha::Patron::Password::Recovery;

# Copyright 2014 Solutions InLibro inc.
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;
use C4::Context;
use C4::Letters;
use Crypt::Eksblowfish::Bcrypt qw(en_base64);

use Koha::Exceptions;

use vars qw(@ISA @EXPORT);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    push @EXPORT, qw(
      &ValidateBorrowernumber
      &SendPasswordRecoveryEmail
      &GetValidLinkInfo
      &CompletePasswordRecovery
      &DeleteExpiredPasswordRecovery
    );
}

=head1 NAME

Koha::Patron::Password::Recovery - Koha password recovery module

=head1 SYNOPSIS

use Koha::Patron::Password::Recovery;

=head1 FUNCTIONS

=head2 ValidateBorrowernumber

$alread = ValidateBorrowernumber( $borrower_number );

Check if the system already start recovery

Returns true false

=cut

sub ValidateBorrowernumber {
    my ($borrower_number) = @_;
    my $schema = Koha::Database->new->schema;

    my $rs = $schema->resultset('BorrowerPasswordRecovery')->search(
        {
            borrowernumber => $borrower_number,
            valid_until    => \'> NOW()'
        },
        { columns => 'borrowernumber' }
    );
    if ( $rs->next ) {
        return 1;
    }
    return 0;
}

=head2 GetValidLinkInfo

    Check if the link is still valid and return some info.

=cut

sub GetValidLinkInfo {
    my ($uniqueKey) = @_;
    my $dbh         = C4::Context->dbh;
    my $query       = '
    SELECT borrower_password_recovery.borrowernumber, userid
    FROM borrower_password_recovery, borrowers
    WHERE borrowers.borrowernumber = borrower_password_recovery.borrowernumber
    AND NOW() < valid_until
    AND uuid = ?
    ';
    my $sth = $dbh->prepare($query);
    $sth->execute($uniqueKey);
    return $sth->fetchrow;
}

=head2 SendPasswordRecoveryEmail

 It creates an email using the templates and sends it to the user, using the specified email

 Parameters:
 C<$borrower>   Koha::Patron
 C<$userEmail>  to_address (the one specified in the request)
 C<$update>     Update existing password recovery request
 C<$params>     Additional parameters as follows:
                  url:        Custom password reset link (third party integrations)
                  skip_email: If true, will not enqueue the letter, but return it
                              instead. Use this flag if you want a third party
                              service to handle emailing instead of Koha.
=cut

sub SendPasswordRecoveryEmail {
    my $borrower  = shift;    # Koha::Patron
    my $userEmail = shift;    #to_address (the one specified in the request)
    my $update    = shift;
    my $params    = shift;

    my $schema = Koha::Database->new->schema;

    # generate UUID
    my $uuid_str;
    do {
        $uuid_str = '$2a$08$'.en_base64(Koha::AuthUtils::generate_salt('weak', 16));
    } while ( substr ( $uuid_str, -1, 1 ) eq '.' );

    # insert into database
    my $expirydate =
      DateTime->now( time_zone => C4::Context->tz() )->add( days => 2 );
    if ($update) {
        my $rs =
          $schema->resultset('BorrowerPasswordRecovery')
          ->search( { borrowernumber => $borrower->borrowernumber, } );
        $rs->update(
            { uuid => $uuid_str, valid_until => $expirydate->datetime() } );
    }
    else {
        my $rs = $schema->resultset('BorrowerPasswordRecovery')->create(
            {
                borrowernumber => $borrower->borrowernumber,
                uuid           => $uuid_str,
                valid_until    => $expirydate->datetime()
            }
        );
    }

    # create link
    my $opacbase = C4::Context->preference('OPACBaseURL') || '';
    my $uuidLink = $opacbase
      . "/cgi-bin/koha/opac-password-recovery.pl?uniqueKey=$uuid_str";

    # Custom $uuidLink. This feature is used for external integrations that handle
    # password resetting inside the system via e.g. Koha's REST API.
    if (defined $params->{url}) {
        # Make sure host name exists in whitelist
        my $url = $params->{url};
        my $whitelist = C4::Context->preference(
            'OpacResetPasswordHostWhitelist'
        );
        my @allowed_hosts = split /[,\s\|]/, $whitelist if defined $whitelist;
        foreach my $allowed_host (@allowed_hosts) {
           if ($url =~ /^https?:\/\/$allowed_host/) {
                $url =~ s/{uuid}/$uuid_str/gi;
                $uuidLink = $params->{url} = $url;
                last;
            }
        }
        Koha::Exceptions::WrongParameter->throw( error => 'System preference'
              . ' OpacResetPasswordHostWhitelist does'
              . " not contain the requested host of '$url'"
        ) if $uuidLink ne $params->{url};
    }

    # prepare the email
    my $letter = C4::Letters::GetPreparedLetter(
        module      => 'members',
        letter_code => 'PASSWORD_RESET',
        branchcode  => $borrower->branchcode,
        lang        => $borrower->lang,
        substitute =>
          { passwordreseturl => $uuidLink, user => $borrower->userid },
    );

    if ($params->{skip_email}) {
        return {
            to_address => $userEmail,
            uuid       => $uuid_str,
            uuidLink   => $uuidLink,
            letter     => $letter->{content},
        };
    }

    # define to/from emails
    my $kohaEmail = C4::Context->preference('KohaAdminEmailAddress');    # from

    C4::Letters::EnqueueLetter(
        {
            letter                 => $letter,
            borrowernumber         => $borrower->borrowernumber,
            to_address             => $userEmail,
            from_address           => $kohaEmail,
            message_transport_type => 'email',
        }
    );

    return 1;
}

=head2 CompletePasswordRecovery

    $bool = CompletePasswordRecovery($uuid);

    Deletes a password recovery entry.

=cut

sub CompletePasswordRecovery {
    my $uniqueKey = shift;
    my $model =
      Koha::Database->new->schema->resultset('BorrowerPasswordRecovery');
    my $entry = $model->search(
        { -or => [ uuid => $uniqueKey, valid_until => \'< NOW()' ] } );
    return $entry->delete();
}

=head2 DeleteExpiredPasswordRecovery

    $bool = DeleteExpiredPasswordRecovery($borrowernumber)

    Deletes an expired password recovery entry.

=cut

sub DeleteExpiredPasswordRecovery {
    my $borrower_number = shift;
    my $model =
      Koha::Database->new->schema->resultset('BorrowerPasswordRecovery');
    my $entry = $model->search(
        { borrowernumber => $borrower_number } );
    return $entry->delete();
}


END { }    # module clean-up code here (global destructor)

1;
