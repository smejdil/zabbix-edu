#!/usr/bin/perl

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

# Get list of all hosts using authID

$json = {
jsonrpc=> '2.0',
method => 'host.get',
params =>
{
output => ['hostid','name'],# get only host id and host name
sortfield => 'name',        # sort by host name
},
id => 2,
auth => "$authID",
};
$response = $client->call($url, $json);

# Check if response was successful
die "host.get failed\n" unless $response->content->{result};

print "List of hosts\n-----------------------------\n";
foreach my $host (@{$response->content->{result}}) {
print "Host ID: ".$host->{hostid}." Host: ".$host->{name}."\n";
}

# EOF
