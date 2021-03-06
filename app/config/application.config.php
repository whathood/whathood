<?php

$application_env = $_SERVER['APPLICATION_ENV'];

$modules = array(
    'DoctrineModule',
    'DoctrineORMModule',
    'ZfcBase',
    'ZfcUser',
    'ZfcUserDoctrineORM',
    'BjyAuthorize',
	'SamUser',
    'SlmQueue',
    'SlmQueueDoctrine',
    'Whathood',
);

if ('development' == $application_env) {
    // put developer tools at the beginning of the modules to load
    array_unshift($modules, 'ZendDeveloperTools');
}

return array(
    'listeners' => array(
        'TimerListener'
    ),

    // This should be an array of module namespaces used in the application.
    'modules' => $modules,

    // These are various options for the listeners attached to the ModuleManager
    'module_listener_options' => array(
        // This should be an array of paths in which modules reside.
        // If a string key is provided, the listener will consider that a module
        // namespace, the value of that key the specific path to that module's
        // Module class.
        'module_paths' => array(
            './module',
            './vendor',
        ),

        // An array of paths from which to glob configuration files after
        // modules are loaded. These effectively overide configuration
        // provided by modules themselves. Paths may use GLOB_BRACE notation.
        'config_glob_paths' => array(
            'config/autoload/*.local.php',
            'config/autoload/whathood.db.php',
            'config/autoload/*.global.php'
        ),
    ),
);
