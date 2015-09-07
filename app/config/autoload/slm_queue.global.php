<?php
/**
 * This is the config file for SlmQueue. Just drop this file into your config/autoload folder (don't
 * forget to remove the .dist extension from the file), and configure it as you want
 */

return array(
    'slm_queue' => array(
        /**
         * Allow to configure a specific queue.
         *
         * Available options depends on the queue factory
         */
        'queues' => array(
        ),

        /**
         * This block is use to register and configure strategies to the worker event manager. The default key holds any
         * configuration for all instanciated workers. The ones configured within the 'queues' keys are specific to
         * specific queues only.
         *
         * Note that module.config.php defines a few defaults and that configuration where the value is not an array
         * will be ignored (thus allows you to disable preconfigured strategies).
         *
         * 'worker_strategies' => array(
         *     'default' => array( // per worker
         *          // Would disable the pre configured max memory strategy
         *          'SlmQueue\Strategy\MaxMemoryStrategy' => null
         *          // Reconfigure the pre configured max memory strategy to use 250Mb max
         *          'SlmQueue\Strategy\MaxMemoryStrategy' => array('max_memory' => 250 * 1024 * 1024)
         *     ),
         * ),
         *
         * As queue processing is handled by strategies it is important that for each queue a ProcessQueueStrategy
         * (a strategy that listens to WorkerEvent::EVENT_PROCESS) is registered. By default SlmQueue does handles that
         * for the queue called 'default'.
         *
         * 'worker_strategies' => array(
         *     'queues' => array(
         *         'my-queue' => array(
         *              'SlmQueue\Strategy\ProcessQueueStrategy',
         *         )
         *     ),
         * ),
         */
        'worker_strategies' => array(
            'default' => array( // per worker
            ),
            'queues' => array( // per queue
                'default' => array(
                ),
            ),
        ),

        /**
         * Allow to configure the plugin manager that manages strategies. This works like any other
         * PluginManager in Zend Framework 2.
         *
         * Add you own or override existing factories
         *
         * 'strategy_manager' => array(
         *    'factories' => array(
         *        'SlmQueue\Strategy\LogJobStrategy'               => 'MyVeryOwn\LogJobStrategyFactory',
         *    )
         * ),
         */
        'strategy_manager' => array(),

        /**
         * Allow to configure dependencies for jobs that are pulled from any queue. This works like any other
         * PluginManager in Zend Framework 2. For instance, if you want to inject something into every job using
         * a factory, just adds an element into the "factories" array, with the key being the FQCN of the job,
         * and the value the factory:
         *
         * 'job_manager' => array(
         *     'factories' => array(
         *         'Application\Job\UserJob' => 'Application\Factory\UserJobFactory'
         *     )
         * )
         *
         * Therefore, the job will be created through the factory (the identifier and content of the job will be
         * automatically set after creation). Note that this plugin manager is configured as such it automatically
         * add any unknown classes to the invokables list. This means you should only add factories and/or abstract
         * factories here.
         */
        'job_manager' => array(
            'factories' => array(
                'Whathood\Job\EmailJob' => 'Whathood\Factory\EmailJobFactory',
                'Whathood\Job\NeighborhoodBorderBuilderJob' => 'Whathood\Factory\NeighborhoodBorderBuilderJobFactory'
            )
        ),

        /**
         * Allow to add queues. You need to have at least one queue. This works like any other PluginManager in
         * Zend Framework 2. For instance, if you have a queue whose name is "email", you can add it as an
         * invokable this way:
         *
         * 'queue_manager' => array(
         *     'invokables' => array(
         *         'email' => 'Application\Queue\MyQueue'
         *     )
         * )
         *
         * Please note that you can find built-in factories for several queue systems (Beanstalk, Amazon Sqs...)
         * in SlmQueueSqs and SlmQueueBeanstalk
         */
        'queue_manager' => array(
            'factories' => array(
                'message_queue' => 'SlmQueueDoctrine\Factory\DoctrineQueueFactory'
            )
        ),
    ),
);
