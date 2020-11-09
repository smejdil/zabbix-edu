#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use JSON::RPC::Client;
use Data::Dumper;

# Authenticate yourself
my $client = new JSON::RPC::Client;
my $url = 'http://localhost/zabbix/api_jsonrpc.php';
my $authID;
my $response;

my $json = {
jsonrpc => "2.0",
method => "user.login",
params => {
user => "zbx_probe",
password => "ZBXlab"
},
id => 1
};

$response = $client->call($url, $json);

# Check if response was successful
die "Authentication failed\n" unless $response->content->{'result'};

$authID = $response->content->{'result'};
print "Authentication successful. Auth ID: " . $authID . "\n";

# EOF
