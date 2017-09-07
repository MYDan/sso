package login;
use Dancer ':syntax';
use Dancer qw(cookie debug);
use Dancer::Plugin::Database;

our $VERSION = '0.1';

use utf8;
use Digest::MD5;

my @domain;
BEGIN
{
    my $domain = config->{set_session_domain};
    @domain = $domain ? ref $domain ? @$domain : ( $domain ) : ();
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

any '/' => sub {
    my %param = %{request->params};
    my ( $msg, $ref, $user, $pass ) = @param{qw( msg ref Username Password )};

    $ref = "http://$ref" if $ref && $ref !~ /^https?:\/\//;

    if( my $sid = cookie( "sid" ) )
    {
         my $r = $sid !~ /^[a-zA-Z0-9]{64}$/ ? [] 
                 : exe("select info from info where `keys`='$sid'");

         redirect "$ref?sid=$sid" if $ref && $r && @$r > 0;
         return template 'login', +{ sid => $sid, user => $r->[0][0] }
             if $r && ref $r eq 'ARRAY' && @$r > 0;
    }

    if( $user && $pass && $user =~ /^[\@a-zA-Z0-9\._-]+$/ )
    {
         $pass = Digest::MD5->new->add($pass)->hexdigest;
         my $r = exe("select * from user where username='$user' and password='$pass'");
         if( $r && ref $r eq 'ARRAY' && @$r > 0 )
          {
              my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
              my $keys = join("", @chars[ map { rand @chars } ( 1 .. 64 ) ]);

              if( @domain )
              {
                  map{ 
                      set_cookie(
                          sid => $keys, 
                          ##expires => time + 10800, 
                          domain => $_, 
                          http_only => 0 
                      );
                  }@domain;
              }
              else
              {
                  set_cookie( sid => $keys, http_only => 0 );
              }

              exe( "insert  into info (`keys`,`info`) values ( '$keys', '$user')" );

              redirect $ref ? "$ref?sid=$keys" : '/';
          }
          else { $msg = 'password nomatch' }
    }

    template 'index', +{ msg => $msg, ref => $ref };
};

any '/info' => sub {
    my $sid = request->params->{sid};

    return "{ \"mesg\": \"sid format err\" }" 
        unless $sid && $sid =~ /^[a-zA-Z0-9]{64}$/;

    my $r = exe("select info from info where `keys`='$sid'");

    return ( $r && ref $r eq 'ARRAY' && @$r >= 1 ) 
        ? "{\"user\": \"$r->[0][0]\"}" 
        : "{ \"mesg\": \"nomatch\" }";

};

any '/logout' => sub {
    my $sid = request->params->{sid};

    return "{ \"mesg\": \"sid format err\" }" 
        unless $sid && $sid =~ /^[a-zA-Z0-9]{64}$/;

    exe("delete from info where `keys`='$sid'");

    redirect "/";
};

true;
