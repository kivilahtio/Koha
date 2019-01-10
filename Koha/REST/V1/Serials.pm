package Koha::REST::V1::Serials;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';

use C4::Serials;

use Try::Tiny;
use Data::Printer;

use Koha::Exception::UnknownObject;
use Koha::Exception::BadParameter;

sub get_serial_items {
    my $c = shift->openapi->valid_input or return;

    my $args = $c->req->query_params->to_hash;

    try {
        my $serialItems = C4::Serials::GetSerialItems($args);

        return $c->render( status => 200, openapi => {
            serialItems => $serialItems
        } );
    } catch {
        return $c->render( status => 500,
             openapi => { error => "Something went wrong, check the logs." } );
    };
}

sub get_collection {
    my $c = shift->openapi->valid_input or return;

    my $args = $c->req->query_params->to_hash;

    try {
        my $collectionMap = C4::Serials::GetCollectionMap($args);

        return $c->render( status => 200, openapi => {
            collectionMap => $collectionMap
        } );
    } catch {
        return $c->render( status => 500,
             openapi => { error => "Something went wrong, check the logs." } );
    }
}

sub serial_delete {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $serialid = $c->validation->param('serialid');

        my $serial = C4::Serials::GetSerial($serialid);
        Koha::Exception::UnknownObject->throw(error => "No such serial") unless $serial;

        my $deletedCount = C4::Serials::DeleteSerial($serialid);
        Koha::Exception::DB->throw(error => "The given serial '$serialid' exists, but deleting it causes '$deletedCount' rows to be removed from the DB? Expected to only remove 1 row.") if ($deletedCount != 1);

        return $c->render(status => 200, openapi => _swaggerizeSerial($serial));
    }
    catch {
        unless (blessed $_ && $_->can('rethrow')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        if ($_->isa('Koha::Exception::DB')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::UnknownObject')) {
            return $c->render(status  => 404,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::BadParameter')) {
            return $c->render(status  => 400,
                              openapi => { error => "$_" });
        }
        else {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
    };
}

sub serial_get {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $serialid = $c->validation->param('serialid');

        my $serial = C4::Serials::GetSerial($serialid);
        Koha::Exception::UnknownObject->throw(error => "No serial found with serialid='".($serialid || 'undef')."'") unless $serial;

        return $c->render(status => 200, openapi => _swaggerizeSerial($serial));
    }
    catch {
        unless (blessed $_ && $_->can('rethrow')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        if ($_->isa('Koha::Exception::DB')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::UnknownObject')) {
            return $c->render(status  => 404,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::BadParameter')) {
            return $c->render(status  => 400,
                              openapi => { error => "$_" });
        }
        else {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
    };
}

sub serial_list {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $biblionumber = $c->validation->param('biblionumber');
        my $subscriptionid = $c->validation->param('subscriptionid');
        Koha::Exception::BadParameter->throw(error => "Either the biblionumber or the subscriptionid -parameters must be given.") unless ($subscriptionid or $biblionumber);

        my $serials = C4::Serials::ListSerials($subscriptionid, $biblionumber);
        Koha::Exception::UnknownObject->throw(error => "No serials found for biblionumber='".($biblionumber || 'undef')."', subscriptionid='".($subscriptionid || 'undef')."'") unless @$serials;
        @$serials = map {_swaggerizeSerial($_)} @$serials;

        return $c->render(status => 200, openapi => $serials);
    }
    catch {
        unless (blessed $_ && $_->can('rethrow')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        if ($_->isa('Koha::Exception::DB')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::UnknownObject')) {
            return $c->render(status  => 404,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::BadParameter')) {
            return $c->render(status  => 400,
                              openapi => { error => "$_" });
        }
        else {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
    };
}

sub serial_post {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $serial = $c->validation->param('serial');

        $serial = C4::Serials::AddSerial($serial);

        return $c->render(status => 200, openapi => _swaggerizeSerial($serial));
    }
    catch {
        unless (blessed $_ && $_->can('rethrow')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        if ($_->isa('Koha::Exception::DB')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::UnknownObject')) {
            return $c->render(status  => 404,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::BadParameter')) {
            return $c->render(status  => 400,
                              openapi => { error => "$_" });
        }
        else {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
    };
}

sub serial_put {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $serialid = $c->validation->param('serialid');
        my $serial = $c->validation->param('serial');
        $serial->{serialid} = $serialid;

        $serial = C4::Serials::ModSerial($serial);

        return $c->render(status => 200, openapi => _swaggerizeSerial($serial));
    }
    catch {
        unless (blessed $_ && $_->can('rethrow')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        if ($_->isa('Koha::Exception::DB')) {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::UnknownObject')) {
            return $c->render(status  => 404,
                              openapi => { error => "$_" });
        }
        elsif ($_->isa('Koha::Exception::BadParameter')) {
            return $c->render(status  => 400,
                              openapi => { error => "$_" });
        }
        else {
            return $c->render(status  => 500,
                              openapi => { error => "$_" });
        }
    };
}

sub _swaggerizeSerial {
    $_[0]->{itemnumber}     += 0 if (defined($_[0]->{itemnumber}));
    $_[0]->{biblionumber}   += 0 if (defined($_[0]->{biblionumber}));
    $_[0]->{subscriptionid} += 0 if (defined($_[0]->{subscriptionid}));
    $_[0]->{status}         += 0 if (defined($_[0]->{status}));
    $_[0]->{claims_count}   += 0 if (defined($_[0]->{claims_count}));
    return $_[0];
}
1;
