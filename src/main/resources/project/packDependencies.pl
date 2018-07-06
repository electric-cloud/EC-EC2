use warnings;
use strict;
use Archive::Zip qw(AZ_OK);
use MIME::Base64 qw(encode_base64);
use File::Temp qw(tmpnam);
use File::Find;
use File::Spec;
use File::Basename qw(dirname);
use Digest::MD5 qw(md5_hex);

my $filename = $ARGV[0] or die "No lib path";

open my $fh, $filename or die "Cannot open $filename: $!";
binmode $fh;
my $content = join('', <$fh>);
close $fh;

my $base64 = encode_base64($content);
my $chunkSize = 1024 * 1024;
$base64 =~ s/\s+//g;

my $chunks = chunkString($base64, $chunkSize);
print "Got chunks: " . scalar @$chunks . "\n";

my $counter = 0;
my $props = [];
for my $chunk (@$chunks) {
    my $propName = "ec_dependencyChunk_$counter";
    my $property = qq{
        <property>
            <propertyName>$propName</propertyName>
            <value>$chunk</value>
            <expandable>0</expandable>
        </property>
    };
    $counter++;
    push @$props, $property;
}

my $checksum = md5_hex($base64);
push @$props, qq{
<property>
    <propertyName>checksum</propertyName>
    <value>$checksum</value>
</property>
};


my $propSheet = join("\n", @$props);

my $projectPath = File::Spec->catfile(dirname($0), 'project.xml');
open $fh, $projectPath or die "Cannot open $projectPath: $!";
my $project = join('', <$fh>);
close $project;

$project =~ s/\Q<!-- start chunked dependencies -->\E.*\Q<!-- end chunked dependencies -->\E
/<!-- start chunked dependencies -->$propSheet<!-- end chunked dependencies -->/gxms;

open $fh, ">$projectPath" or die "Cannot open $projectPath: $!";
print $fh $project;
close $fh;
print "Saved project.xml\n";

sub chunkString {
    my ($string, $chunkSize) = @_;

    my $current = '';
    my $chunks = [];
    for my $sym (split('', $string)) {
        $current .= $sym;
        if (length($current) == $chunkSize) {
            push @$chunks, $current;
            $current = '';
        }
    }
    if ($current) {
        push @$chunks, $current;
    }
    return $chunks;
}
