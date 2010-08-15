package MT::Plugin::UserDashboard;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

MT->add_plugin( MT::Plugin::UserDashboard->new );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        callbacks => {
            'MT::App::CMS::template_source.dashboard' => \&init_menu,
            'MT::App::CMS::template_source.this_is_you' => \&this_is_you,
        },
   } );
}

sub init {
    my $app = shift;
    my $core = MT->component( 'core' );
    my $r = $core->registry( 'applications', 'cms', 'widgets' );
    $r->{this_is_you} = {
                label    => 'This is You',
                template => 'widget/this_is_you.tmpl',
                handler  => "MT::CMS::Dashboard::this_is_you_widget",
                set      => 'sidebar',
                singular => 1,
                view     => 'user',
            };
    $app->SUPER::init( @_ );
}

sub init_menu {
    my ( $cb, $app, $tmpl ) = @_;
    if ( ( $app->view eq 'user' ) || ( $app->mode eq 'default' ) ) {
        my $menus = $app->registry( 'menus' );
        for my $menu ( values( %$menus ) ) {
            if ( $menu->{ view } ) {
                if ( ref ( $menu->{ view } )
                    ? grep( $_ eq 'system', @{ $menu->{ view } } )
                    : $menu->{ view } eq 'system'
                ) {
                    $menu->{ view } = 'user';
                }
            }
        }
    }
}

sub this_is_you {
    my ( $cb, $app, $tmpl ) = @_;
    $$tmpl =~ s/<mtapp:widget/<mtapp:widget can_close="1"/;
    $$tmpl =~ s/you\-widget//; 
    my $new = '<ul><li><strong><mt:var name="author_display_name" escape="html"></strong></li>';
    $$tmpl =~ s/<ul\sclass="user-stats-list">/<ul class="user-stats-list">$new/;
}

1;