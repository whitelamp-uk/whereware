<?php
return [
    'whereware' => [
        'all_tables'                => '&where[0][col]=hidden&where[0][op]=%3D&where[0][val]=0',
        'per_table' => [
            'ww_bin'                => '&order[0]=bin',
            'ww_booking'            => '&order[0]=id&desc[0]=1',
            'ww_composite'          => '&order[0]=sku',
            'ww_consignment'        => '&order[0]=id&desc[0]=1',
            'ww_generic'            => '&order[0]=sku&order[1]=generic',
            'ww_location'           => '&order[0]=location',
            'ww_move'               => '&where[1][col]=cancelled&where[1][op]=%3D&where[1][val]=0&where[2][col]=status&where[2][op]=%3D&where[2][val]=F' 
                                      .'&order[0]=updated&desc[0]=1&order[1]=order_ref&order[2]=booking_id&order[3]=sku',
            'ww_project'            => '&order[0]=project',
            'ww_project_sku'        => '&order[0]=project&order[1]=sku',
            'ww_recent_inventory'   => '&where[1][col]=location&where[1][op]=%3D&where[1][val]=W-1&order[0]=sku&order[1]=bin',
            'ww_sku'                => '&order[0]=sku',
            'ww_team'               => '&order[0]=team',
            'ww_task'               => '&order[0]=scheduled_date&desc[0]=1&order[1]=team&order[2]=location',
            'ww_variant'            => '&order[0]=generic&order[1]=sku',
        ]
    ]
];

