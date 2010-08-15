package MT::Plugin::IfFileExist;

use strict;
use MT::Builder;
use MT::Template::Context;
use base qw(MT::Plugin);

my $plugin = __PACKAGE__->new({
    name        => 'IfFileExist',
    version     => '2.00',
    author_name => 'bzbell',
    description => 'Check the existence of an any file.',
    author_link => 'http://bizcaz.com/',
    doc_link    => 'http://bizcaz.com/archives/2008/06/01-043945.php',
});
MT->add_plugin($plugin);

MT::Template::Context->add_conditional_tag(IfFileExist => \&file_exist_main);

sub file_exist_main
{
    my ($ctx, $args, $cond) = @_;
    my $value;

    if (exists $args->{url}) {
        if ($args->{url} =~ m/(<\$MT.+\$>)/) {
            my $builder = $ctx->stash('builder');
            my $tokens  = $builder->compile($ctx, $args->{url})
                or return $ctx->error($builder->errstr);
            local $ctx->{stash}{tokens} = $tokens;
            my $out = $builder->build($ctx, $tokens, $cond);
            return $ctx->error($builder->errstr) unless defined $out;
            $args->{url} = $out;
        }

        # MTBlogURL に該当するハンドラを取得します
        # $ctx->stash('blog')->site_url でも OK!!
        my $url = file_exist_conv($ctx, $args, 'BlogURL');
        # 指定 URL からサイト URLの文字列を削除します
        $value = $args->{url};
        $value =~ s|$url||;
    }
    elsif (exists $args->{path}) {
        if ($args->{path} =~ m/(<\$MT.+\$>)/) {
            my $builder = $ctx->stash('builder');
            my $tokens  = $builder->compile($ctx, $args->{path})
                or return $ctx->error($builder->errstr);
            local $ctx->{stash}{tokens} = $tokens;
            my $out = $builder->build($ctx, $tokens, $cond);
            return $ctx->error($builder->errstr) unless defined $out;
            $args->{path} = $out;
        }

        # MTBlogRelativeURL に該当するハンドラを取得します
        # $ctx->stash('blog')->site_url でも OK!!
        my $path = file_exist_conv($ctx, $args, 'BlogSitePath');
        # 指定パスからサイトパスの文字列を削除します
        $value = $args->{path};
        $value =~ s|$path||;
    }
    else {
        # 間違ったアトリビュート指定です ダメダメです
        return 0;
    }

    # 先頭の '/' があれば削除します
    $value =~ s|^/||;
    # MTBlogSitePath に該当するハンドラを取得します
    # $ctx->stash('blog')->site_path でも OK!!
    my $path = file_exist_conv($ctx, $args, 'BlogSitePath');
    # サイトパスとファイル名を結合します
    $value = $path . $value;
    # ファイルの存在チェック後、真偽を返します
    return (-e $value) ? 1 : 0;
}

sub file_exist_conv
{
    my ($ctx, $args, $tag) = @_;
    my $conv = '';

    my ($handler) = $ctx->handler_for($tag);

    if (defined($handler)) {
        local $ctx->{__stash}{tag} = $tag;
        $tag = $handler->($ctx, { %$args });

        if (my $ph = $ctx->post_process_handler) {
            $conv = $ph->($ctx, $args, $tag);
        }
    }

    return $conv;
}

1;
