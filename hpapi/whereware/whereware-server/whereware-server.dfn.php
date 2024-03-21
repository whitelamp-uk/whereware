<?php

/* Copyright 2022 Whitelamp http://www.whitelamp.com/ */


// Reporting and errors
define ( 'WHEREWARE_STR_403',                   '601 403 Sorry - data unavailable'          );
define ( 'WHEREWARE_STR_DB',                    '602 500 Failed to retrieve data'           );
define ( 'WHEREWARE_STR_DB_INSERT',             '603 500 Failed to insert data'             );
define ( 'WHEREWARE_STR_DB_UPDATE',             '604 500 Failed to update data'             );
define ( 'WHEREWARE_STR_PASSWORD_TEST',         '605 500 Unable to test password'           );
define ( 'WHEREWARE_STR_ORDER_NOT_NEW',         '606 400 Order already exists'              );
define ( 'WHEREWARE_STR_ORDER_NOT_FOUND',       '607 404 Order not found'                   );
define ( 'WHEREWARE_STR_SKU_NOT_FOUND',         '608 404 SKU not found'                     );
define ( 'WHEREWARE_STR_TARGET_NOT_FOUND',      '609 400 Target location not found'         );
define ( 'WHEREWARE_STR_QTY_INVALID',           '610 400 Quantity is not valid'             );
// 611 must be stable because it is used by Whereware JS returnsRequest():
define ( 'WHEREWARE_STR_QTY_INSUFFICIENT',      '611 400 Low stock'                         );
define ( 'WHEREWARE_STR_PROJECT',               '612 400 Failed to identify project'        );
define ( 'WHEREWARE_STR_RESULTS_LIMIT',         '613 400 Too many results'                  );
define ( 'WHEREWARE_STR_LOCATION_MISSING',      '614 400 Location could not be found'       );
define ( 'WHEREWARE_STR_SKU_MISSING',           '615 400 SKU could not be found'            );
define ( 'WHEREWARE_STR_PASSWORD_DICTIONARY',   'Contains common words, names or patterns'  );
define ( 'WHEREWARE_STR_PASSWORD_CHARACTERS',   'Not enough different characters'           );
define ( 'WHEREWARE_STR_PASSWORD_OTHER',        'Too easy to crack'                         );
define ( 'WHEREWARE_STR_PASSWORD_SCORE',        'Security score is too low'                 );


// Userland configuration - definitions and classes
require_once HPAPI_DIR_CONFIG.'/whereware/whereware-server.cfg.php';

