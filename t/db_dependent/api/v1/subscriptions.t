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

use Test::Most tests => 1;
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

my $biblio = $builder->build({
    source => 'Biblio'
});
my @subscriptions = (
    $builder->build({
        source => 'Subscription',
        value => {
            branchcode => 'CPL',
            biblionumber => $biblio->{biblionumber},
        }
    }),
    $builder->build({
        source => 'Subscription',
        value => {
            branchcode => 'CPL',
            biblionumber => $biblio->{biblionumber},
        }
    }),
);

$ENV{REMOTE_ADDR} = '127.0.0.1';
my $t = Test::Mojo->new('Koha::REST::V1');

subtest "List subscriptions" => sub {
    plan tests => 7;

    $t->get_ok('/api/v1/subscriptions' => form => {biblionumber => 99999999999});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('404');
    $t->json_like('/error', qr/No subscriptions/,
        "No subscriptions");

    $t->get_ok('/api/v1/subscriptions' => form => {biblionumber => $subscriptions[0]->{biblionumber}});
    p($t->tx->res->body) if ($ENV{VERBOSE});
    $t->status_is('200');
    $t->json_is('/0/subscriptionid', $subscriptions[0]->{subscriptionid},
        "Subscription received");
    $t->json_is('/1/subscriptionid', $subscriptions[1]->{subscriptionid},
        "Subscription received");
};

1;