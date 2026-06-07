<?php
$path = '/var/www/runalyze/composer.json';
$data = json_decode(file_get_contents($path), true);

if (!isset($data['repositories']) || !is_array($data['repositories'])) {
    $data['repositories'] = [];
}

array_unshift($data['repositories'], [
    'type' => 'package',
    'package' => [
        'name' => 'miniflux/picofeed',
        'version' => 'v0.1.35',
        'source' => [
            'url' => 'https://github.com/aaronpk/picofeed.git',
            'type' => 'git',
            'reference' => 'main',
        ],
        'require' => [
            'php' => '>=5.3.0',
            'ext-iconv' => '*',
            'ext-dom' => '*',
            'ext-xml' => '*',
            'ext-libxml' => '*',
            'ext-SimpleXML' => '*',
            'laminas/laminas-xml' => '^1.2',
        ],
        'autoload' => [
            'psr-0' => [
                'PicoFeed' => 'lib/',
            ],
        ],
    ],
]);

file_put_contents(
    $path,
    json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL
);
