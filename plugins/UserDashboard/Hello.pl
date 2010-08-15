package MT::Plugin::Hello;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

use MT::Util qw( offset_time_list format_ts );

my $plugin = new MT::Plugin::Hello ( {
    description => '<MT_TRANS phrase=\'_PLUGIN_DESCRIPTION\'>',
    name => 'Hello',
    id   => 'Hello',
    key  => 'hello',
    author_name => 'Junnama Noda',
    author_link => 'http://junnama.alfasado.net/online/',
    version => '0.1',
    l10n_class => 'Hello::L10N',
} );

MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        callbacks => {
            'MT::App::CMS::template_source.dashboard' => \&hello,
        },
   } );
}

sub hello {
    my ( $cb, $app, $tmpl ) = @_;
    if ( ( $app->view eq 'user' ) || ( $app->mode eq 'default' ) ) {
        my $msg = &title;
        my $title = '<mt:setvarblock name="page_title"><__trans_section component="Hello"><__trans phrase="[_2], [_1]" params="<mt:var name="author_display_name" escape="html" escape="html">%%' . $msg . '"></__trans_section></mt:setvarblock>';
        $$tmpl =~ s/<mt:setvarblock\sname="html_head"\sappend="1">/$title<mt:setvarblock name="html_head" append="1">/;
    }
}

sub title {
    my $app = MT->instance();
    my $dt = $app->config( 'DefaultTimezone' );
    $dt = $dt * 3600;
    my @tl = offset_time_list( time + $dt, undef );
    my $ts = sprintf "%02d%02d", @tl[2,1];
    $ts .+ 0;
    my $msg = $plugin->translate( 'Hi' );
    if ( $ts > 1900 ) {
        $msg = $plugin->translate( 'Good evening' );
    }
    if ( ( $ts > 500 ) && ( $ts < 1100 ) ) {
        $msg = $plugin->translate( 'Good morning' );
    }
    if (! ( $ts > 500 ) ) {
        $msg = $plugin->translate( 'Good night' );
    }
    return $msg;
}

1;