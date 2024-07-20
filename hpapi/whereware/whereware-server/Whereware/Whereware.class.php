<?php

/* Copyright 2022 Whitelamp http://www.whitelamp.co.uk */

namespace Whereware;

class Whereware {

    /* Interacts with a location/bin/SKU `whereware` database model */

    public $hpapi;
    public $userId;

    public function __construct (\Hpapi\Hpapi $hpapi) {
        $this->hpapi            = $hpapi;
        $this->timezone         = $this->hpapi->tzName;
        $this->userId           = $this->hpapi->userId;
    }

    public function __destruct ( ) {
    }

    public function authenticate ( ) {
        // The framework does the actual authentication every request
        // This method is for client app authentication of a browser session
        // The standard base class hpapi.js expects to receive user details
        return $this->user ();
    }

    public function binSelect ($location,$qty=null,$sku) {
        if ($qty===null) {
            // Stock levels are immaterial, just select the SKU native "home" bin
            $sku = $this->sku ($sku);
            if ($sku) {
                return $sku->bin;
            }
            return '';
        }
        // Get best bin by a selection algorithm that considers bin quantities
        try {
            $results = $this->hpapi->dbCall (
                'wwInventory',
                $location,
                $sku
            );
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $max                = 0;
        $matches            = [];
        foreach ($results as $r) {
            // wwInventory() results are from a LIKE search
            if ($r['sku']==$sku) {
                // Result exactly matches this SKU
                if ($r['is_home_bin'] && WHEREWARE_BIN_PRIORITY_HOME) {
                    // This is the home bin for this SKU
                    if ($r['available']>=$qty) {
                        // Home bin has sufficient stock
                        return $r['bin'];
                    }
                }
                // Find best availability
                $matches[]  = $r;
                if ($max<$r['available']) {
                    $max    = $r['available'];
                }
            }
        }
        if (count($matches)) {
            if ($max>$qty && WHEREWARE_BIN_PRIORITY=='MINSA') {
                // Minimum Sufficient Availability model - MINSA
                $results        = [];
                foreach ($matches as $m) {
                    if (!array_key_exists($m['available'],$results)) {
                        $results[$m['available']] = $m;
                    }
                }
                ksort ($results);
                foreach ($results as $r) {
                    if ($r['available']>=$qty) {
                        return $r['bin'];
                    }
                }
            }
            // If $max<=$qty, the MINSA model is pointless - we want the bin with the mostest in this case
            // Maximum Availability model - MAXA
            return $matches[0]['bin'];
        }
        // No moves in the inventory so find the home bin from the SKU table
        if ($bin=$this->skus($sku)->skus[0]->bin) {
            return $bin;
        }
        else {
            throw new \Exception ('No bin found for SKU '.$sku);
            return false;
        }
    }

    public function book ($booking) {
        /*
        Example $booking:
        {
            location             : "S-XYZ",
            project              : "1234567",
            project_name         : "My project",
            order_ref            : "ABCD"
            type                 : "incoming",
            export               : true,
            shipment_details     : "4 boxes",
            deliver_by           : "2023-05-26",
            eta                  : null,
            pick_by              : null,
            prefer_by            : null,
            notes                : "The Co\nThe commercial estate\nSome other info",
            items: [
                {
                    quantity     : 4,
                    sku  : "NEW-MARK-00000000010",
                    description  : "A new thing",
                },
                ...
            ]
        }
        */
        // Missing null fields
        foreach (['project','task_id','team','deliver_by','eta','pick_scheduled','pick_by','prefer_by'] as $p) {
            if (!property_exists($booking,$p) || !$booking->$p) {
                $booking->$p = null;
            }
        }
        // Missing empty fields
        foreach (['booker','order_ref','type','shipment_details','location','location_name','location_address','notes'] as $p) {
            if (!property_exists($booking,$p) || !$booking->$p) {
                $booking->$p = '';
            }
        }
        // Missing boolean fields
        foreach (['export'] as $p) {
            if (!property_exists($booking,$p)) {
                $booking->$p = 0;
            }
            $booking->$p &= true;
            $booking->$p *= 1;
        }
        foreach ($booking->items as $item) {
            foreach (['quantity','sku'] as $p) {
                if (!property_exists($item,$p)) {
                    $item->$p = '';
                }
            }
            $item->quantity = intval ($item->quantity);
        }
        try {
            $result = $this->hpapi->dbCall (
                'wwBookingInsert',
                $this->user()->user,
                $booking->project,
                $booking->order_ref,
                $booking->type,
                $booking->export,
                $booking->shipment_details,
                $booking->deliver_by,
                $booking->eta,
                $booking->pick_scheduled,
                $booking->pick_by,
                $booking->prefer_by,
                $booking->notes
            );
            $booking->id = $result[0]['id'];
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $locations = [
            'incoming' => [
                'from' => '',
                'via' => WHEREWARE_LOCATION_IN,
                'to' => WHEREWARE_LOCATION_COMPONENT
            ],
            'internal' => [
                'from' => WHEREWARE_LOCATION_COMPONENT,
                'via' => WHEREWARE_LOCATION_COMPONENT,
            ],
            'outgoing' => [
                'from' => WHEREWARE_LOCATION_COMPONENT,
                'via' => WHEREWARE_LOCATION_OUT,
                'to' => WHEREWARE_LOCATIONS_BOOKINGS.$booking->id
            ]
        ];
        if ($booking->type=='incoming') {
            if ($booking->location) {
                $locations['incoming']['from'] = $booking->location;
            }
            else {
                $booking->location = $locations['incoming']['from'];
            }
        }
        elseif ($booking->type=='outgoing') {
            if ($booking->location) {
                $locations['outgoing']['to'] = $booking->location;
            }
            else {
                $booking->location = $locations['outgoing']['to'];
            }
        }
        else {
            $booking->location = null;
        }
        $items = "";
        if ($booking->location) {
            try {
// TODO: This needs to allow adding of broken down address: address_1, ..., postcode
// An unstructured name/address for now goes in notes field but maybe have new field `address_label`
                $result = $this->hpapi->dbCall (
                    'wwLocationInsertMissing',
                    $booking->location,
                    $booking->location_name,
                    $booking->location_address,
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB_INSERT);
                return false;
            }
        }
        $sku_group = strtoupper (WHEREWARE_SKU_TEMP_NAMESPACE.'-'.$this->user()->user);
        $assigns = [
        ];
        foreach ($booking->items as $i=>$item) {
            if ($booking->type=='outgoing') {
                // The stock matters; use the configured selection algorithm
                $booking->items[$i]->bin = $this->binSelect (WHEREWARE_LOCATION_COMPONENT,$item->quantity,$item->sku);
            }
            elseif ($booking->type=='incoming') {
                // For a "to" bin, stock is immaterial; select the home bin
                $booking->items[$i]->bin = $this->binSelect (WHEREWARE_LOCATION_COMPONENT,null,$item->sku);
            }
            else {
                // A human will decide later
                $booking->items[$i]->bin = '';
            }
        }
        foreach ($booking->items as $item) {
            try {
                $error = WHEREWARE_STR_DB_INSERT;
                $bin_from = '';
                if ($locations[$booking->type]['from']==WHEREWARE_LOCATION_COMPONENT) {
                    $bin_from = $item->bin;
                }
                $bin_via = '';
                if ($locations[$booking->type]['via']==WHEREWARE_LOCATION_COMPONENT) {
                    $bin_via = $item->bin;
                }
                $result = $this->hpapi->dbCall (
                    'wwMoveInsert',
                    $this->user()->user,                 // inserter
                    $booking->order_ref,                 // orderRef
                    $booking->id,                        // bookingId
                    'R',                                 // sts
                    $item->quantity,                     // qty
                    $item->sku,                          // sk
                    $locations[$booking->type]['from'],  // frLoc
                    $bin_from,                           // frBin
                    $locations[$booking->type]['via'],   // toLoc
                    $bin_via                             // toBin
                );
                $assigns[] = [
                    $this->user()->user,
                    $result[0]['id'],
                    $booking->project,
                    $booking->task_id,
                    $booking->team
                ];
                if (array_key_exists('to',$locations[$booking->type])) {
                    $error = WHEREWARE_STR_DB_INSERT;
                    $bin_to = '';
                    if ($locations[$booking->type]['to']==WHEREWARE_LOCATION_COMPONENT) {
                        $bin_to = $item->bin;
                    }
                    $result = $this->hpapi->dbCall (
                        'wwMoveInsert',
                        $this->user()->user,                // inserter
                        $booking->order_ref,                // orderRef
                        $booking->id,                       // bookingId
                        'R',                                // sts
                        $item->quantity,                    // qty
                        $item->sku,                         // sk
                        $locations[$booking->type]['via'],  // frLoc
                        $bin_via,                           // frBin
                        $locations[$booking->type]['to'],   // toLoc
                        $bin_to                             // toBin
                    );
                    $assigns[] = [
                        $this->user()->user,
                        $result[0]['id'],
                        $booking->project,
                        $booking->task_id,
                        $booking->team
                    ];
                }
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception ($error);
                return false;
            }
        }
        try {
            $error = WHEREWARE_STR_DB_UPDATE;
            foreach ($assigns as $a) {
                $result = $this->hpapi->dbCall (
                    'wwMoveAssign',
                    ...$a
                );
            }
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception ($error);
            return false;
        }
        return $booking->id;
    }

    public function components ($search_terms) {
        return $this->skus ($search_terms,1,0);
    }

    public function composites ($search_terms) {
        return $this->skus ($search_terms,0,1);
    }

    public function config ( ) {
        $out = new \stdClass ();
        try {
            $out->timezoneExpected = $this->timezone;
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        try {
            $result = $this->hpapi->dbCall (
                'wwBins',
                ''
            );
            $out->bins = $this->hpapi->parse2D ($result);
            $result = $this->hpapi->dbCall (
                'wwLocations',
                ''
            );
            $out->locations = $this->hpapi->parse2D ($result);
            foreach ($out->locations as $i=>$locn) {
                $out->locations[$i]->is_destination = false;
                if (strpos($out->locations[$i]->location,WHEREWARE_LOCATIONS_DESTINATIONS)===0) {
                    $out->locations[$i]->is_destination = true;
                }
            }
            $result = $this->hpapi->dbCall (
                'wwStatuses'
            );
            $out->statuses = $this->hpapi->parse2D ($result);
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $out->constants = new \StdClass ();
        $out->constants->WHEREWARE_LOCATION_ASSEMBLY                    = new \stdClass ();
        $out->constants->WHEREWARE_LOCATION_ASSEMBLED                   = new \stdClass ();
        $out->constants->WHEREWARE_LOCATION_COMPONENT                   = new \stdClass ();
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS               = new \stdClass ();
        $out->constants->WHEREWARE_RETURNS_LOCATION                     = new \stdClass ();
        $out->constants->WHEREWARE_ADMINER_URL                          = new \stdClass ();
        $out->constants->WHEREWARE_RESULTS_LIMIT                        = new \stdClass ();
        $out->constants->WHEREWARE_SKU_TEMP_NAMESPACE                   = new \stdClass ();
        $out->constants->WHEREWARE_SKU_TEMP_ID_LENGTH                   = new \stdClass ();
        $out->constants->WHEREWARE_LOCATION_ASSEMBLY->value             = WHEREWARE_LOCATION_ASSEMBLY;
        $out->constants->WHEREWARE_LOCATION_ASSEMBLED->value            = WHEREWARE_LOCATION_ASSEMBLED;
        $out->constants->WHEREWARE_LOCATION_COMPONENT->value            = WHEREWARE_LOCATION_COMPONENT;
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS->value        = WHEREWARE_LOCATIONS_DESTINATIONS;
        $out->constants->WHEREWARE_RETURNS_LOCATION->value              = WHEREWARE_RETURNS_LOCATION;
        $out->constants->WHEREWARE_ADMINER_URL->value                   = WHEREWARE_ADMINER_URL;
        $out->constants->WHEREWARE_RESULTS_LIMIT->value                 = WHEREWARE_RESULTS_LIMIT;
        $out->constants->WHEREWARE_SKU_TEMP_NAMESPACE->value            = WHEREWARE_SKU_TEMP_NAMESPACE;
        $out->constants->WHEREWARE_SKU_TEMP_ID_LENGTH->value            = WHEREWARE_SKU_TEMP_ID_LENGTH;
        $out->constants->WHEREWARE_LOCATION_ASSEMBLY->definition        = 'Assembly location code for pick\'n\'book';
        $out->constants->WHEREWARE_LOCATION_ASSEMBLED->definition       = 'Assembled composite default location code for pick\'n\'book';
        $out->constants->WHEREWARE_LOCATION_COMPONENT->definition       = 'Warehouse code for finding/selecting component bins';
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS->definition   = 'Code prefix for identifying destination locations';
        $out->constants->WHEREWARE_RETURNS_LOCATION->definition         = 'Location for accepting returns';
        $out->constants->WHEREWARE_ADMINER_URL->definition              = 'Adminer URL';
        $out->constants->WHEREWARE_RESULTS_LIMIT->definition            = 'Maximum number of search results';
        $out->constants->WHEREWARE_SKU_TEMP_NAMESPACE->definition       = 'Prefix to search for a new user-space SKU';
        $out->constants->WHEREWARE_SKU_TEMP_ID_LENGTH->definition       = 'Length of user-space SKU ID';
        return $out;
    }

    public function inventory ($location) {
        try {
            $result = $this->hpapi->dbCall (
                'wwInventory',
                $location,
                null
            );
            return $this->hpapi->parse2D ($result);
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
    }

    public function move ($obj) {
/* Pick 'n' book stuff is now broken at least because of radical changes to wwBookingInsert() */
        /*
        For example:
        {
            composite_quantity: 1,
            composite_sku: COMPOSITE-1,
            target_location: GO-1,
            target_bin: ,
            order_ref: MARK-1234,
            picks: [
                {
                    sku: WIDGET-1,
                    bin: B17,
                    quantity: 4,
                },
                ...
            ]
        }
        */
        if (!preg_match('<^[1-9][0-9]*$>',$obj->composite_quantity)) {
            throw new \Exception (WHEREWARE_STR_QTY_INVALID);
            return false;
        }
        $obj->target_location = trim ($obj->target_location);
        if (!strlen($obj->target_location)) {
            throw new \Exception (WHEREWARE_STR_TARGET_NOT_FOUND);
            return false;
        }
        $obj->target_bin = trim ($obj->target_bin);
        $sku = $this->sku ($obj->composite_sku);
        if (!$sku) {
            throw new \Exception (WHEREWARE_STR_SKU_NOT_FOUND);
            return false;
        }
        $moves = [];
        // Many components moved to assembly location / component bin
/* Pick 'n' book stuff is now broken at least because of radical changes to wwBookingInsert() */
        $result = $this->hpapi->dbCall (
            'wwBookingInsert'
        );
        $ids = [];
        $ids[0] = $result[0]['id'];
        foreach ($obj->picks as $pick) {
            $moves[] = [
                'order_ref' => $obj->order_ref,
                'booking_id' => $ids[0],
                'status' => 'R',
                'quantity' => $obj->composite_quantity * $pick->quantity,
                'sku' => $pick->sku,
                'from_location' => WHEREWARE_LOCATION_COMPONENT,
                'from_bin' => $pick->bin,
                'to_location' => WHEREWARE_LOCATION_ASSEMBLY,
                'to_bin' => $pick->bin
            ];
        }
        // Human assembly process happens here in the model. Then:
        // Single composite moved to target location / composite bin
        if (strlen($obj->target_bin)) {
            $to_bin = $obj->target_bin;
        }
        else {
            $to_bin = $sku->bin;
        }
/* Pick 'n' book stuff is now broken at least because of radical changes to wwBookingInsert() */
        $result = $this->hpapi->dbCall (
            'wwBookingInsert'
        );
        $ids[1] = $result[0]['id'];
        $moves[] = [
            'order_ref' => $obj->order_ref,
            'booking_id' => $ids[1],
            'status' => 'R',
            'quantity' => $obj->composite_quantity,
            'sku' => $obj->composite_sku,
            'from_location' => WHEREWARE_LOCATION_ASSEMBLY,
            'from_bin' => $sku->bin,
            'to_location' => $obj->target_location,
            'to_bin' => $to_bin
        ];
        // Now do all the moves
        try {
            foreach ($moves as $m) {
                $result = $this->hpapi->dbCall (
                    'wwMoveInsert',
                    $this->hpapi->email,  // inserter
                    $m['order_ref'],      // orderRef
                    $m['booking_id'],     // bookingId
                    $m['status'],         // sts
                    $m['quantity'],       // qty
                    $m['sku'],            // sk
                    $m['from_location'],  // frLoc
                    $m['from_bin'],       // frBin
                    $m['to_location'],    // toLoc
                    $m['to_bin']          // toBin
                );
            }
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            try {
                if (array_key_exists(0,$ids)) {
                    $this->hpapi->dbCall (
                        'wwBookingCancel',
                        $ids[0]
                    );
                    $this->hpapi->diagnostic ("booking_id=$booking_id moves are cancelled");
                }
                if (array_key_exists(1,$ids)) {
                    $this->hpapi->dbCall (
                        'wwBookingCancel',
                        $ids[1]
                    );
                }
            }
            catch (\Exception $e2) {
                $this->hpapi->diagnostic ($e->getMessage());
            }
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $rtn = new \stdClass ();
        $rtn->bookingIds = [];
        foreach ($ids as $i=>$id) {
            $rtn->bookingIds[$i] = '#'.$id;
        }
        $rtn->bookingIds = implode (', ',$rtn->bookingIds);
        $rtn->moves = $this->hpapi->parse2D ($moves);
        return $rtn;
    }

    public function orders ($order_ref) {
        $destination_locations_start_with = WHEREWARE_LOCATIONS_DESTINATIONS;
        $limit = WHEREWARE_RESULTS_LIMIT + 1;
        $rtn = new \stdClass ();
        $rtn->sql = "CALL `wwOrders`('','','','')";
        $rtn->orders = [];
        try {
            $rtn->sql = "CALL `wwOrders`('$order_ref','$destination_locations_start_with',$limit);";
            $limit++;
            $result = $this->hpapi->dbCall (
                'wwOrders',
                $order_ref,
                $destination_locations_start_with,
                $limit
            );
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        if (count($result)>WHEREWARE_RESULTS_LIMIT) {
            $this->hpapi->warn (WHEREWARE_STR_RESULTS_LIMIT);
            array_pop ($result);
        }
        $rtn->orders = $this->hpapi->parse2D ($result);
        return $rtn;
    }

    public function passwordReset ($answer,$code,$newPassword) {
        if (!$this->hpapi->object->response->pwdSelfManage) {
            $this->hpapi->diagnostic (HPAPI_DG_RESET);
            throw new \Exception (HPAPI_STR_AUTH_DENIED);
            return false;
        }
        try {
            if (!$this->passwordTest($newPassword,$this->hpapi->object->response->pwdScoreMinimum,$msg)) {
                $this->hpapi->addSplash ($msg);
                throw new \Exception (WHEREWARE_STR_PASSWORD);
                return false;
            }
        }
        catch (\Exception $e) {
            throw new \Exception ($e->getMessage());
            return false;
        }
        try {
            $user = $this->hpapi->dbCall (
                'wwUserDetails',
                $this->userId
            );
            $answerHash         = $user[0]['secretAnswerHash'];
            $verifyCode         = $user[0]['verifyCode'];
            $verifyCodeExpiry   = $user[0]['verifyCodeExpiry'];
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        if (!password_verify($this->answerCondense($answer),$answerHash)) {
            throw new \Exception (WHEREWARE_STR_PWD_RESET_ANSWER);
            return false;
        }
        if ($code!=$verifyCode) {
            throw new \Exception (WHEREWARE_STR_PWD_RESET_CODE);
            return false;
        }
        if ($this->hpapi->timestamp>$verifyCodeExpiry) {
            throw new \Exception (WHEREWARE_STR_PWD_RESET_EXPIRY);
            return false;
        }
        $expires                = null;
        if (HPAPI_PASSWORD_DAYS) {
            $expires            = $this->hpapi->timetamp;
            $expires           += HPAPI_PASSWORD_DAYS * 86400;
        }
        try {
            $this->hpapi->dbCall (
                'wwSetPasswordHash',
                $this->userId,
                $this->hpapi->passwordHash ($newPassword),
                $expires,
                1
            );
            return true;
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
    }

    public function passwordTest ($pwd,$minscore,&$msg='OK') {
        return passwordTest ($pwd,$minscore,$msg);
    }

    public function phoneParse ($number) {
        $number = preg_replace ('/[^0-9]+/','',$number);
        if (strpos($number,'0')===0 && strpos($number,'00')!==0) {
            $number = WHEREWARE_PHONE_DEFAULT_COUNTRY_CODE.substr($number,1);
        }
        return $number;
    }

    public function projectInsert ($project,$name,$notes) {
        try {
            $result = $this->hpapi->dbCall (
                'wwProjectInsert',
                $project,
                $name,
                $notes
            );
            $row_id = $result[0]['id'];
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB_INSERT);
            return false;
        }
        return $row_id;
    }

    public function projectUpdate ($obj) {
/*
    {
        project : 123456,
        order_ref : 2024-WK-01/2024002,
        notes : Some notes,
        skus : [
            THINGY-1,
            ...
        ],
        tasks [
            {
                team : T-123,
                location : NICE-1,
                scheduled_date : 2021-02-23,
                name : Somewhere nice,
                postcode : CB25 0DU,
                skus : [
                    {
                        sku : THINGY-1,
                        quantity : 1
                    },
                    ...
                ]
            },
            ....
        ]
    }

('Whereware', 'wwProjectSkuInsert',  1,  'Project code', 0,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  2,  'SKU', 0,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  3,  'Bin code', 1,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  4,  'SKU description', 1,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  5,  'Is composite', 0,  'db-boolean'),

*/
        $booking_id = null;
        $assigns = [];
        $locations = [];
        $bins = [];
        foreach ($obj->skus as $sku) {
            try {
                $results = $this->hpapi->dbCall (
                    'wwSkus',
                    $sku,
                    1,
                    1,
                    1,
                    '',
                    ''
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB);
                return false;
            }
            if (!count($results)) {
                throw new \Exception (WHEREWARE_STR_SKU_MISSING.': '.$sku);
                return false;
            }
            // This will foce an error if there is no valid bin for a SKU (before we start inserting this batch of moves)
            $this->binSelect (WHEREWARE_LOCATION_COMPONENT,1,$sku);
        }
        foreach ($obj->tasks as $task) {
            if (!in_array($task->location,$locations)) {
                $locations[] = $task->location;
            }
        }
        foreach ($locations as $locationLike) {
            try {
                $result = $this->hpapi->dbCall (
                    'wwLocations',
                    $locationLike
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB);
                return false;
            }
            if (!count($result) || $result[0]['location']!=$locationLike) {
                throw new \Exception (WHEREWARE_STR_LOCATION_MISSING.': '.$locationLike);
                return false;
            }
        }
        $tasks = $this->tasks ($obj->project);
        foreach ($obj->tasks as $i=>$task) {
            $obj->tasks[$i]->id = null;
            $obj->tasks[$i]->status = null;
            foreach ($tasks as $t) {
                if ($t->location==$task->location && $t->scheduled_date==$task->scheduled_date) {
                    $obj->tasks[$i]->id = $t->id;
                    $obj->tasks[$i]->status = $t->status;
                    break;
                }
            }
            if (!$obj->tasks[$i]->id) {
                try {
                    $result = $this->hpapi->dbCall (
                        'wwTaskInsert',
                        $obj->project,
                        $task->team,
                        $task->location,
                        $task->scheduled_date,
                        $task->name,
                        $task->postcode,
                        null
                    );
                }
                catch (\Exception $e) {
                    $this->hpapi->diagnostic ($e->getMessage());
                    // Assume this is because the team does not exist in ww_team
                    throw new \Exception (WHEREWARE_STR_TEAM_MISSING.' - '.$task->team);
                    return false;
                }
                $obj->tasks[$i]->id = $result[0]['id'];
                $obj->tasks[$i]->status = 'N';
            }
            try {
                foreach ($task->skus as $sku) {
                    $error = WHEREWARE_STR_DB;
                    if ($obj->tasks[$i]->status=='N') {
                        // Add booking ID if any move is missing
                        if (!$booking_id) {
                            $error = WHEREWARE_STR_DB_INSERT;
                            $result = $this->hpapi->dbCall (
                                'wwBookingInsert',
                                $this->user()->user,
                                $obj->project,
                                'TASK-'.$obj->tasks[$i]->id,
                                'outgoing',
                                0,
                                'Refresh',
                                null,
                                null,
                                null,
                                null,
                                null,
                                ''
                            );
                            $booking_id = $result[0]['id'];
                        }
                        // Above we did this for quantity 1 so we are confident there is at least one valid bin by this point
                        $bin = $this->binSelect (WHEREWARE_LOCATION_COMPONENT,$sku->quantity,$sku->sku);
                        // Insert move from components to out
                        $error = WHEREWARE_STR_DB_INSERT;
                        $result = $this->hpapi->dbCall (
                            'wwMoveInsert',
                            $this->hpapi->email,           // inserter
                            $obj->order_ref,               // orderRef
                            $booking_id,                   // bookingId
                            'R',                           // sts
                            $sku->quantity,                // qty
                            $sku->sku,                     // sk
                            WHEREWARE_LOCATION_COMPONENT,  // frLoc
                            $bin,                          // frBin
                            WHEREWARE_LOCATION_OUT,        // toLoc
                            ''                             // toBin
                        );
                        $move_id = $result[0]['id'];
                        // Assign move
                        $assigns[] = [
                            'wwMoveAssign',
                            $this->hpapi->email,
                            $move_id,
                            $obj->project,
                            $task->id,
                            $task->team
                        ];
                        // Insert move from out to destination
                        $error = WHEREWARE_STR_DB_INSERT;
                        $result = $this->hpapi->dbCall (
                            'wwMoveInsert',
                            $this->hpapi->email,     // inserter
                            $obj->order_ref,         // orderRef
                            $booking_id,             // bookingId
                            'R',                     // sts
                            $sku->quantity,          // qty
                            $sku->sku,               // sk
                            WHEREWARE_LOCATION_OUT,  // frLoc
                            '',                      // frBin
                            $task->location,         // toLoc
                            ''                       // toBin
                        );
                        $move_id = $result[0]['id'];
                        // Assign move
                        $assigns[] = [
                            'wwMoveAssign',
                            $this->hpapi->email,
                            $move_id,
                            $obj->project,
                            $task->id,
                            $task->team
                        ];
                    }
                }
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception ($error);
                return false;
            }
        }
        try {
            $error = WHEREWARE_STR_DB_UPDATE;
            foreach ($assigns as $a) {
                $result = $this->hpapi->dbCall (
                    ...$a
                );
            }
            $moves = [];
            $error = WHEREWARE_STR_DB;
            if ($booking_id) {
                $result = $this->hpapi->dbCall (
                    'wwBooking',
                    $booking_id
                );
                $moves = $this->hpapi->parse2D ($result);
            }
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception ($error);
            return false;
        }
        $rtn = new \stdClass ();
        $rtn->tasks = $obj->tasks;
        $rtn->moves = $result;
        return $rtn;
    }

    public function projects ($project=null) {
        try {
            $result = $this->hpapi->dbCall (
                'wwProjects',
                $project
            );
            $ps = [];
            foreach ($result as $row) {
                if (!array_key_exists($row['project'],$ps)) {
                    $p                          = new \stdClass ();
                    $p->project                 = $row['project'];
                    $p->name                    = $row['name'];
                    $p->notes                   = $row['notes'];
                    $p->skus                    = [];
                    $ps[$row['project']]        = $p;
                }
                $sku                            = new \stdClass ();
                $sku->sku                       = $row['sku'];
                $sku->description               = $row['sku_description'];
                $sku->alt_code                  = $row['sku_alt_code'];
                $sku->bin                       = $row['bin'];
                $sku->notes                     = $row['sku_notes'];
                $ps[$row['project']]->skus[]    = $sku;
            }
            $projects = [];
            foreach ($ps as $p) {
                $projects[] = $p;
            }
            return $projects;
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
    }

    public function report ($args) {
        try {
            $result = $this->hpapi->dbCall (
                ...$args
            );
            return $this->hpapi->parse2D ($result);
        }
        catch (\Exception $e) {
            throw new \Exception ($e->getMessage());
            return false;
        }
    }

    public function reports ( ) {
        try {
            $result = $this->hpapi->dbCall (
                'hpapiSprargs',
                'whereware',
                'whereware-server',
                '\Whereware\Whereware',
                'report'
            );
            $rows = [];
            foreach ($result as $row) {
                $spr = $row['spr'];
                if (!array_key_exists($spr,$rows)) {
                    $rows[$spr] = new \stdClass ();
                    $rows[$spr]->arguments  = [];
                    $rows[$spr]->spr        = $row['spr'];
                    $rows[$spr]->reportName = $row['notes'];
                }
                if (!$row['argument']) {
                    continue;
                }
                unset ($row['spr']);
                unset ($row['notes']);
                $arg                        = new \stdClass ();
                $arg->pattern               = $row['expression'];
                $arg->isCompulsory          = 1 - $row['emptyAllowed'];
                unset ($row['pattern']);
                unset ($row['expression']);
                unset ($row['emptyAllowed']);
                foreach ($row as $property=>$value) {
                    $arg->{$property}       = $value;
                }
                if (defined($arg->constraints)) {
                    $arg->constraints       = constant ($arg->constraints);
                }
                $rows[$spr]->arguments[]    = $arg;
            }
            $reports = [];
            foreach ($rows as $row) {
                $reports[] = $row;
            }
            return $reports;
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
    }

    public function returns ($returns) {
        /*
            1. Get task project and stock (status, quantity), next available scheduled_date
               [First available scheduled date after the original task at the destination location]
               [Usually the day after the original task and in the past - the schedule is later corrected by admin]
            2. Check the stock
            3. Create a booking and a new task for the same destination location and new scheduled date
            4. Move (fulfilled) stock from a destination to a returns bin
            5. Move (pending) the same stock back to the destination
            6. Assign the pending moves to the new task and the same team
            7. Manual adjustment of the new task scheduled date
            {
                task_id : 123,
                team : T-1,
                moves : [
                    {
                        quantity : 1,
                        sku : SKU-1,
                        from_location : D-CUR-1234, // The destination
                        to_location : R-1, // Warehouse returns area
                        to_bin : DE-1 // One of a few returns bins by product type
                    },
                    ...
                ]
            }
        */
        // Get the task (one row per move)
        try {
            $result = $this->hpapi->dbCall (
                'wwTask',
                $returns->task_id
            );
            $moves              = $this->hpapi->parse2D ($result);
            $task               = $moves[0];
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        // Check the task stock
        foreach ($returns->moves as $i=>$move) {
            $move->stocked = false;
            foreach ($moves as $m) {
                if ($m->sku==$move->sku) {
                    if ($m->status=='F' && $m->quantity>=$move->quantity) {
                        $move->stocked = true;
                    }
                    break;
                }
            }
            if (!$move->stocked) {
                throw new \Exception (WHEREWARE_STR_QTY_INSUFFICIENT.' SKU='.$move->sku);
                return false;
            }
        }
        $assigns = [];
        // Make a booking for the return
        try {
            $result = $this->hpapi->dbCall (
                'wwBookingInsert',
                $this->user()->user,
                $task->project,
                $task->order_ref,
                'incoming',
                0,
                'Refresh return',
                date ('Y-m-d'),
                null,
                null,
                null,
                null,
                'Returned item(s) for '.$task->order_ref
            );
            $booking_id = $result[0]['id'];
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        // Complete return
        foreach ($returns->moves as $i=>$move) {
            try {
                $result = $this->hpapi->dbCall (
                    'wwMoveInsert',
                    $this->hpapi->email,   // inserter
                    $task->order_ref,      // orderRef
                    $booking_id,           // bookingId
                    'F',                   // sts
                    $move->quantity,       // qty
                    $move->sku,            // sk
                    $move->from_location,  // frLoc
                    '',                    // frBin
                    $move->to_location,    // toLoc
                    $move->to_bin          // toBin
                );
                $assigns[] = [
                    'wwMoveAssign',
                    $this->hpapi->email,
                    $result[0]['id'],
                    $task->project,
                    $returns->task_id,
                    $task->team
                ];
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB_INSERT);
                return false;
            }
        }
        try {
            $error = WHEREWARE_STR_DB_UPDATE;
            foreach ($assigns as $a) {
                $result = $this->hpapi->dbCall (
                    ...$a
                );
            }
            $error = WHEREWARE_STR_DB;
            $result = $this->hpapi->dbCall (
                'wwBooking',
                $booking_id
            );
            $moves = $this->hpapi->parse2D ($result);
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception ($error);
            return false;
        }
        return $moves;
    }

    private function searchLike ($search_terms) {
        $str = trim ($search_terms);
        $str = explode (' ',$str);
        $terms = [];
        $longest = 0;
        foreach ($str as $trm) {
            if (($len=strlen($trm))>$longest) {
                $longest = $len;
            }
            $terms[] = strtolower ($trm);
        }
        if ($longest<3) {
            return false;
        }
        return implode ('%',$terms);
    }

    public function secretQuestion ($phoneEnd) {
        if (!$this->hpapi->groupAvailable($groups)) {
            $this->hpapi->diagnostic (HPAPI_DG_ACCESS_GRP);
            throw new \Exception (HPAPI_STR_AUTH_DENIED);
            return false;
        }
        if (!$this->hpapi->object->response->pwdSelfManage) {
            $this->hpapi->diagnostic (HPAPI_DG_RESET);
            throw new \Exception (HPAPI_STR_AUTH_DENIED);
            return false;
        }
        try {
            $user = $this->hpapi->dbCall (
                'wwUserQuestion',
                $this->userId,
                $phoneEnd
            );
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        if (!count($user)) {
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        return $user[0]['secretQuestion'];
    }

    public function sku ($sku) {
        $likes = $this->skus ($sku);       
        foreach ($likes->skus as $like) {
            if ($like->sku==$sku) {
                return $like;
                break;
            }
        }
        return false;
    }

    public function skuUserUpdate ($sku,$alt_code,$description,$notes) {
        $sku_group = strtoupper (WHEREWARE_SKU_TEMP_NAMESPACE.'-'.$this->user()->user);
        $notes = trim ($notes);
        if ($notes) {
            $notes = "\n$notes";
        }
        if (stripos($sku,$sku_group.'-')===0) {
            try {
                $error = WHEREWARE_STR_DB;
                $result = $this->hpapi->dbCall (
                    'wwSkus',
                    $sku,
                    1,
                    1,
                    1,
                    WHEREWARE_LOCATION_COMPONENT,
                    WHEREWARE_LOCATION_ASSEMBLED
                );
                $old = $result[0];
                $error = WHEREWARE_STR_DB_UPDATE;
                $result = $this->hpapi->dbCall (
                    'wwSkuUpdate',
                    $sku,
                    $old['bin'],
                    $alt_code,
                    $old['unit_price'],
                    $description,
                    $old['notes'].$notes
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception ($error);
                return false;
            }
            return true;
        }
    }

    public function skus ($search_terms,$show_components=true,$show_composites=true) {
        $show_components &= true;
        $show_composites &= true;
        $max = WHEREWARE_RESULTS_LIMIT;
        $limit = $max + 1;
        $rtn = new \stdClass ();
        $rtn->sql = "CALL `wwSkus`('$search_terms','$show_components','$show_composites','$limit')";
        $rtn->skus = [];
        $like = $this->searchLike ($search_terms);
        if ($like) {
            if (stripos($like,WHEREWARE_SKU_TEMP_NAMESPACE)===0) {
                $show_components = true;
                $show_composites = true;
            }
            $rtn->sql = "CALL `wwSkus`('$like','$show_components',$show_composites,$limit);";
            try {
                $result = $this->hpapi->dbCall (
                    'wwSkus',
                    $like,
                    1*$show_components,
                    1*$show_composites,
                    $limit,
                    WHEREWARE_LOCATION_COMPONENT,
                    WHEREWARE_LOCATION_ASSEMBLED
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB);
                return false;
            }
            $skus = $this->hpapi->parse2D ($result);
            if (stripos($like,WHEREWARE_SKU_TEMP_NAMESPACE)===0) {
                $sku_group = strtoupper (WHEREWARE_SKU_TEMP_NAMESPACE.'-'.$this->user()->user);
                $sku_idx = 0;
                $sku_group_id = 0;
                $user_sku = new \stdClass ();
                for ($i=0;array_key_exists($i,$skus);$i++) {
                    if (stripos($skus[$i]->sku,WHEREWARE_SKU_TEMP_NAMESPACE)===0) {
                        // So in the user SKU namespace
                        if (strtoupper($skus[$i]->sku_group)==$sku_group) {
                            // So in the current user SKU namespace
                            if ($skus[$i]->sku_group_id>$sku_group_id) {
                                $user_sku = $skus[$i];
                                $sku_group_id = $skus[$i]->sku_group_id;
                            }
                        }
                    }
                }
                if (!$sku_group_id || ($sku_group_id && ($user_sku->alt_code || $user_sku->description))) {
                    // No user SKU or last one already used (has either an additional ref or a name)
                    $sku_group_id++;
                    $sku_group_id = str_pad ("$sku_group_id",WHEREWARE_SKU_TEMP_ID_LENGTH,'0',STR_PAD_LEFT);
                    $new = new \stdClass ();
                    $new->sku = $sku_group.'-'.$sku_group_id;
                    $new->bin = '';
                    $new->alt_code = '';
                    $new->unit_price = 0;
                    $new->description = '';
                    $new->notes = '';
                    // Neither an alt_code nor a description therefore unused
                    try {
                        $result = $this->hpapi->dbCall (
                            'wwSkuInsert',
                            $new->sku,
                            $new->bin,
                            $new->alt_code,
                            $new->unit_price,
                            $new->description,
                            $new->notes
                        );
                    }
                    catch (\Exception $e) {
                        $this->hpapi->diagnostic ($e->getMessage());
                        throw new \Exception (WHEREWARE_STR_DB_INSERT);
                        return false;
                    }
                    $new->id = $result[0]['id'];
                    $skus = [ $new ];
                }
                else {
                    $skus = [ $user_sku ];
                }
            }
            $rtn->skus = $skus;
            if (count($rtn->skus)>$max) {
                // Strictly limit generosity
                throw new \Exception (WHEREWARE_STR_RESULTS_LIMIT);
                return false;
            }
        }
        return $rtn;
    }

    public function sms ($number,$message) {
        try {
            $voodoosms                      = $this->hpapi->jsonDecode (file_get_contents(WHEREWARE_VOODOOSMS_JSON),false,3);
            $voodoosms->parameters->dest    = $this->phoneParse ($number);
            $voodoosms->parameters->msg     = $message;
            $url                            = $voodoosms->url;
            $url                           .= $this->objectToQueryString ($voodoosms->parameters);
            $ch                             = \curl_init ();
            \curl_setopt ($ch,CURLOPT_URL,$url);
            \curl_setopt ($ch,CURLOPT_SSL_VERIFYPEER,false);
            \curl_setopt ($ch,CURLOPT_SSL_VERIFYHOST,2);
            \curl_setopt ($ch,CURLOPT_RETURNTRANSFER,TRUE);
            $json                           = \curl_exec ($ch)."\n";
            if ($e=\curl_error($ch)) {
                $this->hpapi->diagnostic ("Curl error: ".$e);
            }
            else {
                $response                   = $this->hpapi->jsonDecode ($json,false,3);
            }
            \curl_close($ch);
            if ($e) {
                throw new \Exception (WHEREWARE_STR_SMS);
                return false;
            }
            if ($response->result!=200) {
                throw new \Exception (WHEREWARE_STR_SMS);
                return false;
            }
            return true;
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_SMS);
            return false;
        }
    }

    public function tasks ($project) {
        try {
            $result = $this->hpapi->dbCall (
                'wwTasks',
                $project
            );
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $tasks = $this->hpapi->parse2D ($result);
        foreach ($tasks as $i=>$task) {
            $skus = $task->skus;
            $tasks[$i]->skus = [];
            if ($skus) {
                $skus = explode (';;',$skus);
                foreach ($skus as $s) {
                    $s = explode ('::',$s);
                    $sku = new \stdClass ();
                    $sku->sku = $s[0];
                    $sku->quantity = $s[1];
                    $tasks[$i]->skus[] = $sku;
                }
            }
        }
        return $tasks;
    }

    public function team ($team_code) {
        try {
            $result = $this->hpapi->dbCall (
                'wwTeam',
                $team_code
            );
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $tasks          = $this->hpapi->parse2D ($result);
        $team           = new \stdClass ();
        $team->team     = $team_code;
        $team->tasks    = [];
        foreach ($result as $row) {
            $team->hidden               = $row['hidden'];
            $team->name                 = $row['name'];
            $task                       = new \stdClass ();
            $task->id                   = $row['id'];
            $task->updated              = $row['updated'];
            $task->scheduled_date       = $row['scheduled_date'];
            $task->skus                 = [];
            if ($row['skus']) {
                $skus                   = explode (';;',$row['skus']);
                foreach ($skus as $s) {
                    $s                  = explode ('::',$s);
                    $sku                = new \stdClass ();
                    $sku->sku           = $s[0];
                    $sku->quantity      = $s[1];
                    $sku->bin           = $s[2];
                    $task->skus[]       = $sku;
                }
            }
            $task->location             = $row['location'];
            $task->location_name        = $row['location_name'];
            $task->location_territory   = $row['location_territory'];
            $task->location_postcode    = $row['location_postcode'];
            $task->location_address_1   = $row['location_address_1'];
            $task->location_address_2   = $row['location_address_2'];
            $task->location_address_3   = $row['location_address_3'];
            $task->location_town        = $row['location_town'];
            $task->location_region      = $row['location_region'];
            $task->location_map_url     = $row['location_map_url'];
            $task->location_notes       = $row['location_notes'];
            $team->tasks[]              = $task;
        }
        return $team;
    }

    public function teams ( ) {
        try {
            $result = $this->hpapi->dbCall (
                'wwTeams'
            );
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        return $this->hpapi->parse2D ($result);
    }

    public function templates ( ) {
        $g = [];
        $t = [];
        foreach (glob(WHEREWARE_TEMPLATE_GLOB) as $f) {
            $g[] = basename ($f);
        }
        return $t;
    }

    private function user ( ) {
        try {
            $result = $this->hpapi->dbCall (
                'wwUsers',
                $this->hpapi->email
            );
            if (count($result)) {
                // Theoretically this should always be the case
                $user = $this->hpapi->parse2D ($result)[0];
            }
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        // The standard base class hpapi.js expects to receive user details
        // having the property templates (for Handlebars)
        $user->templates = $this->templates ();
        $user->adminerUrl = WHEREWARE_ADMINER_URL;
        return $user;
    }

    public function uuid ( ) {
        try {
            $uuid = $this->hpapi->dbCall (
                'hpapiUUIDGenerate'
            );
        }
        catch (\Exception $e) {
            throw new \Exception ($e->getMessage());
            return false;
        }
        return $uuid[0]['uuid'];
    }

}

