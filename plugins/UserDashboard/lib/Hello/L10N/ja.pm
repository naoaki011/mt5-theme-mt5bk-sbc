package Hello::L10N::ja;

use strict;
use base 'Hello::L10N';
use vars qw( %Lexicon );

our %Lexicon = (
    '_PLUGIN_DESCRIPTION' => 'ユーザーダッシュボードのタイトルを時間帯で変えるよ!',
    'Good morning' => 'おはようございます',
    'Hi' => 'こんにちは',
    'Good evening' => 'こんばんは',
    'Good night' => 'おやすみなさい',
    '[_2], [_1]' => '[_2], [_1]さん',
    );
1;
