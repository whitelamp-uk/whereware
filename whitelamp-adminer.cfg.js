
var whitelampAdminer = {
    barcode : {
        columns : [
            ['whereware','ww_bin','bin'],
            ['whereware','ww_booking','id'],
            ['whereware','ww_composite','sku'],
            ['whereware','ww_consignment','id'],
            ['whereware','ww_generic','generic'],
            ['whereware','ww_generic','sku'],
            ['whereware','ww_location','location'],
            ['whereware','ww_move','project'],
            ['whereware','ww_move','order_ref'],
            ['whereware','ww_move','booking_id'],
            ['whereware','ww_move','consignment_id'],
            ['whereware','ww_move','sku'],
            ['whereware','ww_move','from_location'],
            ['whereware','ww_move','from_bin'],
            ['whereware','ww_move','to_location'],
            ['whereware','ww_move','to_bin'],
            ['whereware','ww_movelog','project'],
            ['whereware','ww_movelog','order_ref'],
            ['whereware','ww_movelog','booking_id'],
            ['whereware','ww_movelog','consignment_id'],
            ['whereware','ww_movelog','sku'],
            ['whereware','ww_movelog','from_location'],
            ['whereware','ww_movelog','from_bin'],
            ['whereware','ww_movelog','to_location'],
            ['whereware','ww_movelog','to_bin'],
            ['whereware','ww_project','project'],
            ['whereware','ww_project_location','project'],
            ['whereware','ww_project_location','location'],
            ['whereware','ww_recent_inventory','sku'],
            ['whereware','ww_recent_inventory','sku_additional_ref'],
            ['whereware','ww_recent_inventory','location'],
            ['whereware','ww_recent_inventory','bin'],
            ['whereware','ww_sku','sku'],
            ['whereware','ww_sku','additional_ref'],
            ['whereware','ww_team','team'],
            ['whereware','ww_variant','generic'],
            ['whereware','ww_variant','sku'],
        ]
    },
    columnFade : {
        columns : [
            ['whereware','ww_bin','id'],
            ['whereware','ww_composite','id'],
            ['whereware','ww_generic','id'],
            ['whereware','ww_location','id'],
            ['whereware','ww_move','id'],
            ['whereware','ww_movelog','id'],
            ['whereware','ww_project','id'],
            ['whereware','ww_project_location','id'],
            ['whereware','ww_sku','id'],
            ['whereware','ww_status','id'],
            ['whereware','ww_team','id'],
            ['whereware','ww_user','id'],
            ['whereware','ww_variant','id'],
            ['whereware','ww_web','id'],
        ]
    },
    inputConstraint : {
        classNameFail : 'input-invalid',
        pattern : [
        //  ['db_name','table_name','column_name','pattern_name'],
            ['whereware','ww_generic','generic','code'],
            ['whereware','ww_location','location','code'],
            ['whereware','ww_organisation','organisation','code'],
            ['whereware','ww_status','status','status'],
            ['whereware','ww_sku','sku','code'],
            ['whereware','ww_team','team','code'],
            ['whereware','ww_user','user','handle'],
            ['whereware','ww_web','group','handle'],
        ],
        readonly : [
        //  ['db_name','table_name','column_name'],
            ['whereware','ww_bin','id'],
            ['whereware','ww_booking','id'],
            ['whereware','ww_composite','id'],
            ['whereware','ww_consignment','id'],
            ['whereware','ww_generic','id'],
            ['whereware','ww_location','id'],
            ['whereware','ww_move','id'],
            ['whereware','ww_organisation','id'],
            ['whereware','ww_project','id'],
            ['whereware','ww_sku','id'],
            ['whereware','ww_status','id'],
            ['whereware','ww_team','id'],
            ['whereware','ww_user','id'],
            ['whereware','ww_variant','id'],
            ['whereware','ww_web','id'],
        ],
        regexp : {
        //  pattern_name : ['html_pattern','keydown_pattern','Constraint description'],
            code : ['[A-Z0-9\\-]{3,64}','[A-Z0-9\\-]','Codes are at least 3 characters, limited to capital letters, integers and hyphens and must start with a letter'],
            handle : ['[a-z]{1}[a-z0-9]{2,63}','[a-z0-9]','Computer handles are at least 3 characters, limited to small letters and integers and must start with a letter'],
            status : ['[A-Z]{1}','[A-Z]','Status codes are a single capital letter'],
        },
    },
}

