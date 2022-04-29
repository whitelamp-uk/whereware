<?php

/* Copyright 2022 Whitelamp http://www.whitelamp.com/ */


define ( 'WHEREWARE_STR_403',                   '601 403 Sorry - data unavailable'          );
define ( 'WHEREWARE_STR_DB',                    '602 500 Failed to retrieve data'           );
define ( 'WHEREWARE_STR_PASSWORD_TEST',         '603 500 Unable to test password'           );
define ( 'WHEREWARE_STR_ORDER_NOT_NEW',         '604 400 Order already exists'              );
define ( 'WHEREWARE_STR_ORDER_NOT_FOUND',       '605 404 Order not found'                   );
define ( 'WHEREWARE_STR_SKU_NOT_FOUND',         '606 404 SKU not found'                     );


define ( 'WHEREWARE_STR_RESULTS_LIMIT',         'Warning - too many results to show all'    );
define ( 'WHEREWARE_STR_PASSWORD_DICTIONARY',   'Contains common words, names or patterns'  );
define ( 'WHEREWARE_STR_PASSWORD_CHARACTERS',   'Not enough different characters'           );
define ( 'WHEREWARE_STR_PASSWORD_OTHER',        'Too easy to crack'                         );
define ( 'WHEREWARE_STR_PASSWORD_SCORE',        'Security score is too low'                 );


// Userland configuration - definitions and classes
require_once HPAPI_DIR_CONFIG.'/whereware/whereware-server.cfg.php';

