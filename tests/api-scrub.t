use Test::More tests => 34;
use Cwd;
use URI::Escape;
use MolochTest;
use Data::Dumper;
use JSON;
use strict;

my $copytest = getcwd() . "/copytest.pcap";
my $token = getTokenCookie();

countTest(0, "date=-1&expression=" . uri_escape("file=$copytest"));

system("../db/db.pl --prefix tests $MolochTest::elasticsearch rm $copytest 2>&1 1>/dev/null");
viewerPost("/flushCache");
system("/bin/cp pcap/socks-http-example.pcap copytest.pcap");
system("../capture/moloch-capture -c config.test.ini -n test -r copytest.pcap --host localhost");
esGet("/_flush");
esGet("/_refresh");

countTest(3, "date=-1&expression=" . uri_escape("file=$copytest"));

# scrub 1 id
    my $idQuery = viewerGet("/sessions.json?date=-1&expression=" . uri_escape("file=$copytest"));

    viewerPostToken("/delete?removePcap=true&removeSpi=false&date=-1", "ids=" . $idQuery->{data}->[0]->{id}, $token);

    esGet("/_refresh");
    esGet("/_flush");

    countTest(1, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==anonymous"));
    countTest(2, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by!=anonymous"));
    countTest(1, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==Anonymous"));
    countTest(1, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==[Anonymous]"));
    countTest(2, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by!=[Anonymous]"));
    countTest(1, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==Anon*mous"));
    countTest(1, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==/Anon.*mous/"));

# scrub expression
    viewerPostToken("/delete?removePcap=true&removeSpi=false&date=-1&expression=" . uri_escape("file=$copytest"), {}, $token);

    esGet("/_refresh");
    esGet("/_flush");

    countTest(3, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==anonymous"));
    countTest(0, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by!=anonymous"));
    countTest(3, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==Anonymous"));
    countTest(3, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==[Anonymous]"));
    countTest(0, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by!=[Anonymous]"));
    countTest(3, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==Anon*mous"));
    countTest(3, "date=-1&expression=" . uri_escape("file=$copytest&&scrubbed.by==/Anon.*mous/"));

# delete
    viewerPostToken("/delete?removePcap=true&removeSpi=true&date=-1&expression=" . uri_escape("file=$copytest"), {}, $token);

    esGet("/_refresh");
    esGet("/_flush");

    countTest(0, "date=-1&expression=" . uri_escape("file=$copytest"));

# cleanup
    unlink("copytest.pcap");
    system("../db/db.pl --prefix tests $MolochTest::elasticsearch rm $copytest 2>&1 1>/dev/null");
    viewerPost("/flushCache");
