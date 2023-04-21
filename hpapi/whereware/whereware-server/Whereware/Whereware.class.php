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
        // having the property templates (for Handlebars)
        $result = $this->hpapi->dbCall (
            'wwUsers',
            $this->hpapi->email
        );
        if ($result) {
            $user = $this->hpapi->parse2D ($result) [0];
            $user->templates = $this->templates ();
            $user->adminerUrl = WHEREWARE_ADMINER_URL;
            return $user;
        }
        throw new \Exception ('Authentication failure');
        return false;
    }

    public function book ($order_ref,$composite,$picks) {
        try {
            $result = $this->hpapi->dbCall (
                'wwBookingInsert'
            );
            $booking_id = $result[0]['id'];
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        return $booking_ref;
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
        $out->constants->WHEREWARE_RETURNS_BINS                         = new \stdClass ();
        $out->constants->WHEREWARE_LOCATION_ASSEMBLY->value             = WHEREWARE_LOCATION_ASSEMBLY;
        $out->constants->WHEREWARE_LOCATION_ASSEMBLED->value            = WHEREWARE_LOCATION_ASSEMBLED;
        $out->constants->WHEREWARE_LOCATION_COMPONENT->value            = WHEREWARE_LOCATION_COMPONENT;
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS->value        = WHEREWARE_LOCATIONS_DESTINATIONS;
        $out->constants->WHEREWARE_RETURNS_LOCATION->value              = WHEREWARE_RETURNS_LOCATION;
        $out->constants->WHEREWARE_RETURNS_BINS->value                  = explode (',',WHEREWARE_RETURNS_BINS);
        $out->constants->WHEREWARE_LOCATION_ASSEMBLY->definition        = 'Assembly location code for pick\'n\'book';
        $out->constants->WHEREWARE_LOCATION_ASSEMBLED->definition       = 'Assembled composite default location code for pick\'n\'book';
        $out->constants->WHEREWARE_LOCATION_COMPONENT->definition       = 'Warehouse code for finding/selecting component bins';
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS->definition   = 'Code prefix for identifying destination locations';
        $out->constants->WHEREWARE_RETURNS_LOCATION->definition         = 'Location for accepting returns';
        $out->constants->WHEREWARE_RETURNS_BINS->definition             = 'Bins for holding returned stock';
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
                    $this->hpapi->email,
                    $m['order_ref'],
                    $m['booking_id'],
                    $m['status'],
                    $m['quantity'],
                    $m['sku'],
                    $m['from_location'],
                    $m['from_bin'],
                    $m['to_location'],
                    $m['to_bin']
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

    public function picklist ($sku) {
        $picklist = [];
        try {
            $result = $this->hpapi->dbCall (
                'wwPick',
                $sku
            );
            $result = $this->hpapi->parse2D ($result);
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $picklist = [];
        foreach ($result as $item) {
            $item->options = explode (',',$item->options_preferred_first);
            unset ($item->options_preferred_first);
            $item->components = [];
            foreach ($item->options as $o) {
                $c = new \stdClass ();
                $o = explode (':',$o);
                $c->sku = $o[0];
                $c->name = $o[1];
                try {
                    $rows = $this->hpapi->dbCall (
                        'wwInventory',
                        WHEREWARE_LOCATION_COMPONENT,
                        $c->sku
                    );
                    $stock = [];
                    foreach ($rows as $row) {
                        if ($row['sku']==$c->sku) {
                            $stock[] = $row;
                        }
                    }
                    $stock = $this->hpapi->parse2D ($stock);
                }
                catch (\Exception $e) {
                    $this->hpapi->diagnostic ($e->getMessage());
                    throw new \Exception (WHEREWARE_STR_DB);
                    return false;
                }
                $c->stock = $stock;

                $item->components[] = $c;
            }
            $picklist[] = $item;
        }
        return $picklist;
    }

    public function projectUpdate ($obj) {
/*
    {
        project : 123456,
        name : Some project,
        notes : Some notes,
        skus : [
            {
                sku : THINGY-1,
                name : Thingy One,
                additional_ref : SUPPLIER-THINGY,
                bin : B007,
                notes : Heavy thingy
            },
            ....
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
('Whereware', 'wwProjectSkuInsert',  4,  'SKU name', 1,  'varchar-64'),
('Whereware', 'wwProjectSkuInsert',  5,  'Is composite', 0,  'db-boolean'),

*/
        $booking_id = null;
        $assigns = [];
        $skus_assoc = [];
        foreach ($obj->skus as $sku) {
            $skus_assoc[$sku->sku] = $sku;
            try {
                $result = $this->hpapi->dbCall (
                    'wwProjectSkuInsert',
                    $obj->project,
                    $sku->sku,
                    $sku->bin,
                    $sku->name,
                    1*$sku->composite
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB_INSERT);
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
                    throw new \Exception (WHEREWARE_STR_DB_INSERT);
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
                                'wwBookingInsert'
                            );
                            $booking_id = $result[0]['id'];
                        }
                        // Insert move
                        $result = $this->hpapi->dbCall (
                            'wwMoveInsert',
                            $this->hpapi->email,
                            '',
                            $booking_id,
                            'P',
                            $sku->quantity,
                            $sku->sku,
                            WHEREWARE_LOCATION_COMPONENT,
                            $skus_assoc[$sku->sku]->bin,
                            $task->location,
                            ''
                        );
                        $error = WHEREWARE_STR_DB;
                        $move_id = $result[0]['id'];
                        // Assign move
                        $error = WHEREWARE_STR_DB_INSERT;
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
// TODO
sleep (1); // Quick hack to prevent ww_movelog duplicate primary key after wwMoveInsert() above
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
                $sku->name                      = $row['sku_name'];
                $sku->additional_ref            = $row['additional_ref'];
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
            2. Create a booking and a new task for the same destination location and new scheduled date
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
        // Insert booking and rebook task
        try {
            $result = $this->hpapi->dbCall (
                'wwBookingInsert'
            );
            $booking_id = $result[0]['id'];
            $result = $this->hpapi->dbCall (
                'wwTaskInsert',
                $task->project,
                $task->team,
                $task->location,
                $task->rebook_date,
                '',
                '',
                $task->id // audits original task
            );
            $task_id_new = $result[0]['id'];
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB_INSERT);
            return false;
        }
        $assigns = [];
        // Complete return
        foreach ($returns->moves as $i=>$move) {
            try {
                $result = $this->hpapi->dbCall (
                    'wwMoveInsert',
                    $this->hpapi->email,
                    '',
                    $booking_id,
                    'F',
                    $move->quantity,
                    $move->sku,
                    $move->from_location,
                    '',
                    $move->to_location,
                    $move->to_bin
                );
                $assigns[] = [
                    'wwMoveAssign',
                    $this->hpapi->email,
                    $result[0]['id'],
                    $task->project,
                    $task->id, // the old task
                    $task->team
                ];
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB_INSERT);
                return false;
            }
        }
        // Rebook stock to destination (status P) and assign as a new task
        foreach ($returns->moves as $move) {
            try {
                $result = $this->hpapi->dbCall (
                    'wwMoveInsert',
                    $this->hpapi->email,
                    '',
                    $booking_id,
                    'P',
                    $move->quantity,
                    $move->sku,
                    $move->to_location, // reversed origin and target bins/locations
                    $move->to_bin,
                    $move->from_location,
                    ''
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB_INSERT);
                return false;
            }
            $assigns[] = [
                'wwMoveAssign',
                $this->hpapi->email,
                $result[0]['id'],
                $task->project,
                $task_id_new,
                $task->team
            ];
        }
// TODO
sleep (1); // Quick hack to prevent ww_movelog duplicate primary key after wwMoveInsert() above
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

    public function skus ($search_terms,$show_components=1,$show_composites=1) {
        $limit = WHEREWARE_RESULTS_LIMIT;
        $rtn = new \stdClass ();
        $rtn->sql = "CALL `wwSkus`('$search_terms','$show_components','$show_composites','$limit')";
        $rtn->skus = [];
        $like = $this->searchLike ($search_terms);
        if ($like) {
            $rtn->sql = "CALL `wwSkus`('$like','$show_components',$show_composites,$limit);";
            $limit++;
            try {
                $result = $this->hpapi->dbCall (
                    'wwSkus',
                    $like,
                    $show_components,
                    $show_composites,
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
            $rtn->skus = $this->hpapi->parse2D ($result);
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
            $task->rebooks_task_id      = $row['rebooks_task_id'];
            $task->scheduled_date       = $row['scheduled_date'];
            $task->skus                 = [];
            if ($row['skus']) {
                $skus                   = explode (';;',$row['skus']);
                foreach ($skus as $s) {
                    $s                  = explode ('::',$s);
                    $sku                = new \stdClass ();
                    $sku->sku           = $s[0];
                    $sku->quantity      = $s[1];
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

