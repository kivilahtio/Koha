#!/usr/bin/env perl

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

BEGIN {
    $ENV{LOG4PERL_VERBOSITY_CHANGE} = 6;
    $ENV{MOJO_OPENAPI_DEBUG} = 1;
    $ENV{MOJO_LOG_LEVEL} = 'debug';
    $ENV{VERBOSE} = 1;
}

use Modern::Perl;

use Test::Most tests => 6;
use Test::Mojo;
use Data::Printer;
use Storable qw(dclone);

use t::lib::TestBuilder;
use t::lib::Mocks;
use Mojo::Cookie::Request;

use Koha::Database;

my $schema = Koha::Database->schema;
$schema->storage->txn_begin;
# FIXME: sessionStorage defaults to mysql, but it seems to break transaction handling, this affects the other REST api tests
t::lib::Mocks::mock_preference( 'SessionStorage', 'tmp' );

my $builder = t::lib::TestBuilder->new;

my $apiUser = $builder->build({
    source => 'Borrower',
    value => {
        gonenoaddress   => 0,
        lost            => 0,
        debarred        => undef,
        debarredcomment => undef,
        branchcode => 'FPL',
    }
});

my $subscription = $builder->build({
    source => 'Subscription',
    value => {
        branchcode => 'CPL',
    }
});

my @items = (
    $builder->build({
        source => 'Item',
        value => {
            homebranch => 'CPL',
            holdingbranch => 'CPL',
            itype => 'SER',
        }
    })
);
$items[1] = $builder->build({
    source => 'Item',
    value => {
        homebranch => 'CPL',
        holdingbranch => 'CPL',
        itype => 'SER',
        biblionumber => $items[0]->{biblionumber},
    }
});

my @serials = (
    { biblionumber => $items[0]->{biblionumber}, subscriptionid => $subscription->{subscriptionid}, itemnumber => $items[0]->{itemnumber},
      serialseq => '2018 : 12 : 50', serialseq_x => 2018, serialseq_y => 12, serialseq_z => 50,
      planneddate => '2018-02-02', publisheddate => '2018-02-10', status => 2 },
    { biblionumber => $items[0]->{biblionumber}, subscriptionid => $subscription->{subscriptionid}, itemnumber => $items[1]->{itemnumber},
      serialseq => '2018 : 12 : 51', serialseq_x => 2018, serialseq_y => 12, serialseq_z => 51,
      planneddate => '2018-02-02', publisheddate => '2018-02-10', status => 2 },
    { biblionumber => $items[0]->{biblionumber}, subscriptionid => $subscription->{subscriptionid},
      serialseq => '2018 : 12 : 52', serialseq_x => 2018, serialseq_y => 12, serialseq_z => 52,
      planneddate => '2018-02-02', publisheddate => '2018-02-10', status => 2 },
);

$ENV{REMOTE_ADDR} = '127.0.0.1';
my $t = Test::Mojo->new('Koha::REST::V1');
authenticateToRESTAPI($apiUser, $t->ua, $ENV{REMOTE_ADDR});

subtest "List/GET serials when there are no blocks to list" => sub {
    plan tests => 6;

    $t->get_ok('/api/v1/serials?subscriptionid='.$subscription->{subscriptionid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('404');
    $t->json_like('/error', qr/No serials/,
        "No serials");

    $t->get_ok('/api/v1/serials?biblionumber='.$subscription->{biblionumber});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('404');
    $t->json_like('/error', qr/No serials/,
        "No serials");
};

subtest '/serials POST' => sub {
    plan tests => 13;

    $t->post_ok('/api/v1/serials' => {Accept => '*/*'} => json => dclone($serials[0]));
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('403');
    $t->json_like('/error', qr/Missing required permission/, 'No permission');

    Koha::Auth::PermissionManager->grantPermission(
        $apiUser->{borrowernumber}, 'serials', 'serial_create'
    );

    for my $i (0..$#serials) {
        $t->post_ok('/api/v1/serials/' => {Accept => '*/*'} => json => dclone($serials[$i]));
        p($t->tx->res->body) if ($ENV{VERBOSE});
        $t->status_is('200');
        ok($serials[$i]->{serialid} = $t->tx->res->json->{serialid},
            "Received serialid");
    }

    subtest("Scenario: serialitems-link autovivificated", sub {
        plan tests => 2;

        my $s = C4::Serials::GetSerial($serials[0]->{serialid});
        is($s->{itemnumber}, $serials[0]->{itemnumber},
            "serialitem autovivificated");

        $s = C4::Serials::GetSerial($serials[0]->{serialid});
        is($s->{itemnumber}, $serials[0]->{itemnumber},
            "serialitem autovivificated");
    });

};

subtest "List/GET serials when there is something to list/GET" => sub {
    plan tests => 9;

    $t->get_ok('/api/v1/serials/'.$serials[0]->{serialid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('200');
    $t->json_is('/serialid', $serials[0]->{serialid});

    subtest "Scenario: Serial with no attached item must still return with a serialid" => sub {
        plan tests => 3;

        $t->get_ok('/api/v1/serials/'.$serials[2]->{serialid});
        p($t->tx->res->body) if ($ENV{VERBOSE});
        $t->status_is('200');
        $t->json_is('/serialid', $serials[2]->{serialid});
    };

    $t->get_ok('/api/v1/serials?subscriptionid='.$subscription->{subscriptionid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('200');
    $t->json_is('/0/serialid', $serials[0]->{serialid});
    $t->json_is('/1/serialid', $serials[1]->{serialid});
    $t->json_is('/2/serialid', $serials[2]->{serialid},
        "Serial with no attached item must still return with a serialid");
};

subtest "Edit/PUT serials" => sub {
    plan tests => 7;

    $t->put_ok('/api/v1/serials/'.$serials[0]->{serialid} => {Accept => '*/*'} => json => dclone($serials[0]));
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('403');
    $t->json_like('/error', qr/Missing required permission/, 'No permission');

    Koha::Auth::PermissionManager->grantPermission(
        $apiUser->{borrowernumber}, 'serials', 'serial_edit'
    );

    $serials[0]->{serialseq_z} = 10;
    $t->put_ok('/api/v1/serials/'.$serials[0]->{serialid} => {Accept => '*/*'} => json => dclone($serials[0]));
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('200');
    cmp_deeply($t->tx->res->json, $serials[0],
        "Serial is as expected");

    subtest "Scenario: Bad serialid is not found from DB" => sub {
        plan tests => 3;

        $t->put_ok('/api/v1/serials/99999999999' => {Accept => '*/*'} => json => dclone($serials[0]));
        p($t->tx->res->body) if ($ENV{VERBOSE});
        $t->status_is('404');
        $t->json_like('/error', qr/but no such serial exists/, 'Got correct error message');
    };

};

subtest '/serials DELETE' => sub {
    plan tests => 14;

    $t->delete_ok('/api/v1/serials/'.$serials[0]->{serialid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('403');
    $t->json_like('/error', qr/Missing required permission/, 'No permission');

    Koha::Auth::PermissionManager->grantPermission(
        $apiUser->{borrowernumber}, 'serials', 'serial_delete'
    );

    $t->delete_ok('/api/v1/serials/'.$serials[0]->{serialid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('200');
    $t->json_is('/serialid', $serials[0]->{serialid},
        "Deleted ok, received contents");

    $t->delete_ok('/api/v1/serials/'.$serials[1]->{serialid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('200');
    $t->json_is('/serialid', $serials[1]->{serialid},
        "Deleted ok, received contents");

    $t->delete_ok('/api/v1/serials/'.$serials[2]->{serialid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('200');
    $t->json_is('/serialid', $serials[2]->{serialid},
        "Deleted ok, received contents");

    $t->get_ok('/api/v1/serials?subscriptionid='.$subscription->{subscriptionid});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('404');
};

subtest 'Create a serial with missing mandatory attributes', sub {
    plan tests => 2;

    my $payload = {
        biblionumber => $items[0]->{biblionumber},
        subscriptionid => $subscription->{subscriptionid},
        serialseq => '2018 : 12 : 52',
        serialseq_x => 2018,
        serialseq_y => 12,
        serialseq_z => 52,
        planneddate => undef,
        publisheddate => undef,
        status => 2
    };

    $t->post_ok('/api/v1/serials/' => {Accept => '*/*'} => json => $payload);
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('400');
};

sub authenticateToRESTAPI {
    my ($apiUser, $userAgent, $domain) = @_;
    my $session = t::lib::Mocks::mock_session({borrower => $apiUser});
    my $jar = Mojo::UserAgent::CookieJar->new;
    $jar->add(
        Mojo::Cookie::Response->new(
            name   => 'CGISESSID',
            value  => $session->id,
            domain => $domain,
            path   => '/',
        )
    );
    $userAgent->cookie_jar($jar);
}

1;