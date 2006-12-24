#!/usr/bin/perl
# UTF-8 encoded
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Cookies;
#use Term::ReadKey;
#use Term::ReadLine;
#use Term::Screen;

my $viewer = 'display';
my $delay = 10; #second
my $cmdowndir = '/home/azuwis/.cmdown/';
my $cookiesfile = $cmdowndir . 'cookies.lwp';
my $username = 'azuwis'; # leave blank to get username from console
my $password = ''; # leave blank to get password from console

my @pickupcodes = @ARGV;
undef @ARGV;

my $ua = LWP::UserAgent->new();
$ua->cookie_jar( HTTP::Cookies->new(
		     'file' => $cookiesfile,
		     'autosave' => 1,
		     'ignore_discard' => 1,
		 ));	

$| = 1; # auto flush

sub login {
    print "-" x 80 . "\n";
    if ( $username eq ''){
	print 'input username:';
	$username = <>;
	chomp $username;
    }
    if ( $password eq ''){
	print 'input password:';
	system("stty -echo");
	$password = <>;
	chomp $password;
	system("stty echo");
	print "\n";
    }

    # fetch valicode
    my $res;
    my $valicode;
    print "fetching valicode picture...";
    $res = $ua->get('http://passport.mofile.com/images/validate.do');
    if ($res->is_success){
	print "ok\n";
	my $valifile = $cmdowndir . "valicode.jpg";
	open (HANDLE, ">$valifile");
	print HANDLE $res->content;
	close HANDLE;
	# display valicode
	my $pid = open (VIEW, "$viewer $valifile|");
	print 'input valicode:';
	$valicode = <>;
	chomp $valicode;
	kill 'INT' => $pid;
	close VIEW;
    }else{
	print "fail to fetch validation picture, exit.\n";
	exit 1;
    }

    # login
    print "login...";
    $res = $ua->post( 'http://passport.mofile.com/cn/login/login.do',
		      [
		       returnurl => 'http%3A%2F%2Fwww.mofile.com%2Fcn%2Floginok_storage.jsp',
		       errorreturnurl => 'http%3A%2F%2Fwww.mofile.com%2Fcn%2Frelogin.jsp',
		       username => $username,
		       password => $password,
		       validationcode => $valicode,
		       Submit => '%E7%99%BB+%E5%BD%95'
		      ],
	);
    if ($res->is_success){
	if ($res->content =~ /loginok_storage\.jsp\?uname=$username/){
	    print "success.\n";
	}else{
	    print "failed, plz check username and password.\n";
	}
    }else{
	print "failed, network problem?\n";
    }

    # fetch profile webpage
    print "fetching profile webpage...";
    $res = $ua->get('http://constellation.mofile.com/cn/index/profileinfo.do?server1=cosmos');
    if ($res->is_success){
	print "ok.\n";
    }else{
	print "failed, exit.\n";
	exit 1;
    }
}

sub getcookies {
    print "try to use saved cookies...";
    my $res = $ua->get('http://constellation.mofile.com/cn/index/profileinfo.do?server1=cosmos');
    if ($res->is_success){
	if ($res->content =~ /http\:\/\/www\.mofile\.com\?r=login/){
	    print "the cookies seem expired, now login to get cookies.\n";
	    login();
	}else{
	    print "ok.\n";	    
	}
    }else{
	print "failed to get cookies, exit.\n";
	exit 1;
    }
}

sub geturl {
    my $pickupcode = $_[0];
    print "-" x 80 . "\n";
    print "download url for pickup code $pickupcode...";
    my $res = $ua->post( 'http://constellation.mofile.com/cn/pickup/pickup.do',
		      [
		       useSession => 'n',
		       pickupcode => $pickupcode,
		      ],
	);
    if ($res->is_success){
	if ($res->content =~ /<td><a href="(http\:\/\/[^"]+)" targe=_blank>\&nbsp\;\&nbsp\;下载文件<\/a><\/td>/){
	    my $url = $1;
	    print "found:\n";
	    print $url . "\n";
	    return $url;
	}
	else{
	    print "nothing found.\n";
	    return '';
	}
    }else{
	print "failed to fetch pickup webpage.\n";
	return '';
    }
}

sub geturls {
    my $pickupcode;
    foreach $pickupcode (@pickupcodes){
	geturl($pickupcode);
    }
}

sub download {
    return if (scalar(@pickupcodes) == 0);
    my $url = geturl($pickupcodes[0]);
    if ($url eq ''){
	return; 
    }
    my $basename = $url;
    $basename =~ s,.*/,,;
    my $exitcode = 1;
    until (!$exitcode){
	print '-' x 80, "\n";
	print "call wget: ", 'wget ', '-c ', '-O ', $basename, ' ', $url, "\n";
	$exitcode = system 'wget', '-c', '-O', $basename, $url;
	print "sleep $delay second...\n";
	sleep $delay;
    }
}

#login();
getcookies();
#geturls();
download();

#geturl('0740735821116157');
#geturl('2612601863419699');
#geturl('5805783908126286');
#geturl('2292269643139469');

# BEGIN {
#     my ($width, $height) = GetTerminalSize;
#     my $oldwinch = $SIG{'WINCH'};
#     sub window_changed {
# 	($width, $height) = GetTerminalSize;
# 	&$oldwinch if $oldwinch;
# 	$SIG{'WINCH'} = \&window_changed;
#     }
#     $SIG{'WINCH'} = \&window_changed;

#     sub show {
# 	my @text = @_;
# 	my $joined_text;
# 	foreach my $t (@text) {
# 	    chomp $t;
	    
# 	}
#     }
# }
