<?php

// This file is used as the router for PHP's built-in server,
// so that Laravel (public/index.php) handles routes like /api/*.

if (php_sapi_name() === 'cli-server') {
    $uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

    // If the requested file exists in /public, let the server serve it directly
    if ($uri !== '/' && file_exists(__DIR__ . '/public' . $uri)) {
        return false;
    }
}

// Otherwise, forward everything to Laravel's front controller
require __DIR__ . '/public/index.php';
