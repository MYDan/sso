package chpasswd;
use Dancer ':syntax';
use Dancer qw(cookie debug info);
use Dancer::Plugin::Database;
use Digest::MD5; 
use Mail::Sendmail;
use YAML::XS;
use utf8;

our $VERSION = '0.1';
my @allow;
BEGIN
{
    my $allow = config->{allow_chpasswd};
    @allow = $allow ? ref $allow ? @$allow : ( $allow ) : ();
};

sub exe
{
    return unless my $sql = shift;
    utf8::encode($sql);

    my $result = [];
    eval
    {
        my $sth = database->prepare( $sql );
        $sth->execute();
        $result = $sth->fetchall_arrayref if $sql =~ m/^\s*(select|show)/i;
    };

    if( $@ ) { error $@; return undef; }

    return $result;
}


sub mail
{
    my ( $user, $keys, $host ) = @_;

    my %send = (
        From    => 'sso@mydan.org',
        Subject => 'sso.mydan.org chpasswd',
        'Content-Type' => 'text/html; charset=utf8',
        To => $user, 
        Message => "<a href=\"http://$host/chpasswd?key=$keys\">Change your password</a>",
    );
    
    $send{Smtp} = $ENV{SMTP_ADDR} if $ENV{SMTP_ADDR};

    print YAML::XS::Dump \%send;
    info "CHPASSWD: $user => http://$host/chpasswd?key=$keys\n";
    return sendmail( %send );
}

any '/chpasswd' => sub {

    my %param = %{request->params};

    my ( $msg, $key, $user, $pass, $pass2, $u, $succ ) = @param{qw( msg key Username Password Password2 )};
    unless( @allow )
    {
        template 'chpasswd', +{ msg => 'Not allow', key => $key } ;
    }
    else
    {

        if( $key )
        {

            if(  $key =~ /^[a-zA-Z0-9]{64}$/ )
            {

                my $r = exe( "select usr from chpasswd where `key`='$key'" ); 
                if( @$r < 1 )
                {
                    $msg = 'key invalid';
                }else
                {
                    $u = $r->[0][0];
                    if( $pass && $pass2 )
                    {
                        if( $pass eq $pass2 )
                        {
                            exe( sprintf "replace into user(`username`,`password`) values( '$u','%s' )", Digest::MD5->new->add( $pass )->hexdigest ); 
                            $succ = 1;
                        }
                        else
                        {
                            $msg = 'Two times the password is not the same';
                        }
                    }
                }
            }else
            {
                $msg = 'key error';
            }
        }
        else
        {
            if( $user )
            {
                if( $user =~ /^([\w\._-]+)@([\w\.]+)$/ )
                {
                    my ( $name, $mail ) = ( $1, $2 );
                    if( grep{ $mail eq $_ }@allow )
                    {
                        my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
                        my $keys = join("", @chars[ map { rand @chars } ( 1 .. 64 ) ]);
                        unless( mail( $user, $keys, request->env->{HTTP_HOST} ) )
                        {
                            $msg = 'send email fail';
                        }
                        else
                        {
                            $msg = 'Already sent';
                        }
			exe( "insert into chpasswd (`usr`,`key`) values ( '$name', '$keys')" ); 
                    }
                    else { $msg = "\@$mail not allow"; }
                }
                else { $msg = 'username format error'; }
            }
        }
        template 'chpasswd', +{ msg => $msg, key => $key, usr => $u, succ => $succ };
    }
};

true;
