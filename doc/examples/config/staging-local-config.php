<?php
/* Copyright 2012-2013 Crowd Favorite, Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

define("WP_HOME", 'http://example.dev');
define("WP_SITEURL", 'http://example.dev/wp');
define("WP_CONTENT_URL", 'http://example.dev/wp-content');
define("WP_CONTENT_DIR",  dirname(__FILE__) . '/'. 'wp-content');

define('DB_NAME', 'example_staging');
define('DB_USER', 'example');
define('DB_PASSWORD', 'correct-horse-battery-staple');
define('DB_HOST', '172.16.1.17');

define('WP_DEBUG', true);
define('SCRIPT_DEBUG', true);
