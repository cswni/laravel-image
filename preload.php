<?php

/**
 * OPcache Preload Script for Laravel 12
 *
 * This file preloads frequently used Laravel classes into OPcache
 * for maximum performance. Enable in production by setting in opcache.ini:
 *
 * opcache.preload=/var/www/html/preload.php
 * opcache.preload_user=www-data
 *
 * WARNING: Only use in production! This can cause issues in development.
 */

if (!function_exists('preload')) {
    function preload(string $path): void
    {
        $files = [];

        if (is_dir($path)) {
            $directory = new RecursiveDirectoryIterator($path);
            $iterator = new RecursiveIteratorIterator($directory);
            $regex = new RegexIterator($iterator, '/^.+\.php$/i', RecursiveRegexIterator::GET_MATCH);

            foreach ($regex as $file) {
                $files[] = $file[0];
            }
        } else {
            $files[] = $path;
        }

        foreach ($files as $file) {
            try {
                require_once $file;
            } catch (Throwable $e) {
                // Silently skip files that can't be preloaded
                error_log("Preload failed for: {$file} - {$e->getMessage()}");
            }
        }
    }
}

// Base path
$baseDir = dirname(__FILE__);

// Preload Composer autoloader
require_once $baseDir . '/vendor/autoload.php';

// Preload Laravel Core
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Foundation');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Support');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Container');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Events');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Routing');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Http');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Database');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/Validation');
preload($baseDir . '/vendor/laravel/framework/src/Illuminate/View');

// Preload commonly used packages
if (is_dir($baseDir . '/vendor/filament')) {
    preload($baseDir . '/vendor/filament/filament/src');
    preload($baseDir . '/vendor/filament/support/src');
    preload($baseDir . '/vendor/filament/forms/src');
    preload($baseDir . '/vendor/filament/tables/src');
    preload($baseDir . '/vendor/filament/notifications/src');
}

// Preload your application code
preload($baseDir . '/app/Models');
preload($baseDir . '/app/Http/Controllers');
preload($baseDir . '/app/Http/Middleware');
preload($baseDir . '/app/Services');

// Optional: Preload Livewire if used
if (is_dir($baseDir . '/vendor/livewire/livewire/src')) {
    preload($baseDir . '/vendor/livewire/livewire/src');
}

echo "✅ OPcache preload completed successfully\n";

