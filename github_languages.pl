#!/usr/bin/env perl

use strict;
use warnings;
use v5.24.0;

use JSON::MaybeXS qw(decode_json);
use List::Util qw(sum);
use LWP::UserAgent qw(new request);


my %languages;

my $ua = LWP::UserAgent->new;

my $username = "username";
my $password = "password";

sub main {
	process_repos();
}

sub add_languages {
	my ($ref) = @_;
	
	my %repo = $ref->%*;
	
	my $req = HTTP::Request->new(GET => $repo{languages_url});
	
	$req->authorization_basic($username, $password);
	
	my $resp = $ua->request($req);
	my %data = decode_json($resp->decoded_content)->%*;
	
	foreach my $key (keys %data) {
		my $value = $languages{$key} ? $data{$key} + $languages{$key} : $data{$key};
		
		$languages{$key} = $value;
	}
}

sub get_repos {
	my $req = HTTP::Request->new(GET => "https://api.github.com/user/repos");
	
	$req->authorization_basic($username, $password);
	
	my $resp = $ua->request($req);
	my $data = decode_json($resp->decoded_content);
	
	return $data->@*;
}

sub process_repos {
	my @repos = get_repos();
	
	foreach my $repo (@repos) {
		add_languages($repo);
	}
	
	show_languages(scalar @repos);
}

sub show_languages {
	my ($repo_count) = @_;
	
	my $language_total = sum values %languages;
	
	foreach my $key (keys %languages) {
		my $value = sprintf("%.2f", (100 * $languages{$key}) / $language_total);
		
		say $key . ': ' . $value if $value > 0.01;
	}
}

main();


__END__
