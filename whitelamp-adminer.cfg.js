
var whitelampAdminer = {
    barcode : {
        columns : [
            ['whereware','ww_sku','sku'],
        ]
    },
    inputConstraint : {
        classNameFail : 'input-invalid',
        regexp : {
            pattern : [
                ['whereware','ww_generic','generic','[A-Z0-9\\-]{3,64}'],
                ['whereware','ww_location','location','[A-Z0-9\\-]{3,64}'],
                ['whereware','ww_organisation','organisation','[A-Z0-9\\-]{3,64}'],
                ['whereware','ww_status','status','[A-Z]{1}'],
                ['whereware','ww_sku','sku','[A-Z0-9\\-]{3,64}'],
                ['whereware','ww_team','team','[A-Z0-9\\-]{3,64}'],
                ['whereware','ww_user','user','[a-z]{1}[a-z0-9]{2,63}'],
                ['whereware','ww_web','group','[a-z]{1}[a-z0-9]{2,63}'],
            ],
            keydown : [
                ['whereware','ww_generic','generic','[A-Z0-9\\-]'],
                ['whereware','ww_location','location','[A-Z0-9\\-]'],
                ['whereware','ww_organisation','organisation','[A-Z0-9\\-]'],
                ['whereware','ww_status','status','[A-Z]'],
                ['whereware','ww_sku','sku','[A-Z0-9\\-]'],
                ['whereware','ww_team','team','[A-Z0-9\\-]'],
                ['whereware','ww_user','user','[a-z0-9]'],
                ['whereware','ww_web','group','[a-z0-9]'],
            ],
            readonly : [
                ['whereware','ww_bin','id'],
                ['whereware','ww_booking','id'],
                ['whereware','ww_composite','id'],
                ['whereware','ww_consignment','id'],
                ['whereware','ww_generic','id'],
                ['whereware','ww_location','id'],
                ['whereware','ww_move','id'],
                ['whereware','ww_organisation','id'],
                ['whereware','ww_project','id'],
                ['whereware','ww_refresh','id'],
                ['whereware','ww_sku','id'],
                ['whereware','ww_status','id'],
                ['whereware','ww_team','id'],
                ['whereware','ww_user','id'],
                ['whereware','ww_variant','id'],
                ['whereware','ww_web','id'],
            ],
        }
    },
}

