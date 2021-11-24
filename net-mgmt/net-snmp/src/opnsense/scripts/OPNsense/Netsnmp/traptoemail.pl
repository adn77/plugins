#!/usr/local/bin/perl

# This is a customized snmptrapd handler script to convert snmp traps into email
# messages. All formatting is done in snmptrapd.conf: "format execute"

# Usage:
# Put a line like the following in your snmptrapd.conf file:
#  traphandle TRAPOID|default /usr/local/bin/traptoemail [-f FROM] [-s SMTPSERVER]b ADDRESSES
#     FROM defaults to "root"
#     SMTPSERVER defaults to "localhost"

use Net::SMTP;
use Getopt::Std;
use POSIX qw(strftime);

$opts{'s'} = "localhost";
$opts{'f'} = 'root@' . `hostname`;
chomp($opts{'f'});
getopts("hs:f:", \%opts);

if ($opts{'h'}) {
    print "
traptoemail [-s smtpserver] [-f fromaddress] toaddress [...]

  traptoemail shouldn't be called interatively by a user.  It is
  designed to be called as an snmptrapd extension via a \"traphandle\"
  directive in the snmptrapd.conf file.  See the snmptrapd.conf file for
  details.

  Options:
    -s smtpserver      Sets the smtpserver for where to send the mail through.
    -f fromaddress     Sets the email address to be used on the From: line.
    toaddress          Where you want the email sent to.

";
    exit;
}

die "no recepients to send mail to" if ($#ARGV < 0);

# process the trap:
$subject = <STDIN>;
chomp($subject);
$ipaddress = <STDIN>;
chomp($ipaddress);

$text = "";
while(<STDIN>) {
    $text .= $_;
}

# send the message
$message = Net::SMTP->new($opts{'s'}) || die "can't talk to server $opts{'s'}\n";
$message->mail($opts{'f'});
$message->to(@ARGV) || die "failed to send to the recepients ",join(",",@ARGV),": $!";
$message->data();
$message->datasend("To: " . join(", ",@ARGV) . "\n");
$message->datasend("From: $opts{f}\n");
$message->datasend("Date: ".strftime("%a, %e %b %Y %X %z", localtime())."\n");
$message->datasend("Subject: trap $subject received from $ipaddress\n");
$message->datasend("\n");
$message->datasend($text);
$message->dataend();
$message->quit;