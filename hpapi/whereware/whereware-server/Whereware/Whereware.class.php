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
/*
        // For example:
        $composite = [
            'sku' = 'TV-99',
            'bin' = 'Z-12'
        ];
        foreach ($picks as $sku) {
            // Each pick is a quantity of a specific component SKU in the composite blueprint
            // For example:
            $sku = [
                'sku' => 'CBL-001',
                'location' => 'W-1',
                'bin' => 'Q-123',
                'qty' => 1
            ];
            try {
                // Against $order_ref/$booking_id, status=[R]aised, move $sku[quantity] X $sku[sku] from/to:
                if (WHEREWARE_LOCATION_ASSEMBLY) {
                    WHEREWARE_LOCATION_COMPONENT/$sku[bin]      ===> WHEREWARE_LOCATION_ASSEMBLY/$composite[bin]
                    WHEREWARE_LOCATION_ASSEMBLY/$composite[bin] ===> WHEREWARE_LOCATION_GOODSOUT/$composite[bin]
                }
                else {
                    WHEREWARE_LOCATION_COMPONENT/$sku[bin]      ===> WHEREWARE_LOCATION_GOODSOUT/$composite[bin]
                }
            }
            catch () {
                update ww_move set cancelled=1 where order_ref='$order_ref' and booking_id='$booking_id';
                throw new \Exception ();
                return false;
            }
        }
*/
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
        $out->constants->WHEREWARE_ASSEMBLY_AUTO_FULFIL                 = new \stdClass ();
        $out->constants->WHEREWARE_LOCATION_COMPONENT                   = new \stdClass ();
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS               = new \stdClass ();
        $out->constants->WHEREWARE_LOCATION_GOODSOUT                    = new \stdClass ();
        $out->constants->WHEREWARE_LOCATION_ASSEMBLY->value             = WHEREWARE_LOCATION_ASSEMBLY;
        $out->constants->WHEREWARE_ASSEMBLY_AUTO_FULFIL->value          = WHEREWARE_ASSEMBLY_AUTO_FULFIL ? 'Yes' : 'No';
        $out->constants->WHEREWARE_LOCATION_COMPONENT->value            = WHEREWARE_LOCATION_COMPONENT;
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS->value        = WHEREWARE_LOCATIONS_DESTINATIONS;
        $out->constants->WHEREWARE_LOCATION_GOODSOUT->value             = WHEREWARE_LOCATION_GOODSOUT;
        $out->constants->WHEREWARE_LOCATION_ASSEMBLY->definition        = 'Assembly location code for automatic composite creation';
        $out->constants->WHEREWARE_ASSEMBLY_AUTO_FULFIL->definition     = 'Automatic fulfilment from assembly to goods out (pick list straight to goods out)';
        $out->constants->WHEREWARE_LOCATION_COMPONENT->definition       = 'Warehouse code for finding/selecting component bins';
        $out->constants->WHEREWARE_LOCATIONS_DESTINATIONS->definition   = 'Code prefix for identifying destination locations';
        $out->constants->WHEREWARE_LOCATION_GOODSOUT->definition        = 'Warehouse code for finding/selecting goods-out bins';
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
            target_location: C-A,
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
        $sku = $this->sku ($obj->composite_sku);
        if (!$sku) {
            throw new \Exception (WHEREWARE_STR_SKU_NOT_FOUND);
            return false;
        }
        $moves = [];
        // Components to assembly/goods-out location composite bin
        foreach ($obj->picks as $pick) {
            $moves[] = [
                'order_ref' => $obj->order_ref,
                'status' => 'R',
                'quantity' => $obj->composite_quantity * $pick->quantity,
                'sku' => $pick->sku,
                'from_location' => WHEREWARE_LOCATION_COMPONENT,
                'from_bin' => $pick->bin,
                'to_location' => WHEREWARE_LOCATION_ASSEMBLY,
                'to_bin' => $sku->bin
            ];
        }
        // Assembled qty x composite to goods-out location, composite bin
        if (WHEREWARE_ASSEMBLY_AUTO_FULFIL) {
            $status = 'R';
        }
        else {
            $status = 'F';
        }
        $moves[] = [
            'order_ref' => $obj->order_ref,
            'status' => $status,
            'quantity' => $obj->composite_quantity,
            'sku' => $obj->composite_sku,
            'from_location' => WHEREWARE_LOCATION_ASSEMBLY,
            'from_bin' => $sku->bin,
            'to_location' => WHEREWARE_LOCATION_GOODSOUT,
            'to_bin' => $sku->bin
        ];
        // Goods-out qty x composite to target location
        $moves[] = [
            'order_ref' => $obj->order_ref,
            'status' => 'R',
            'quantity' => $obj->composite_quantity,
            'sku' => $obj->composite_sku,
            'from_location' => WHEREWARE_LOCATION_GOODSOUT,
            'from_bin' => $sku->bin,
            'to_location' => $obj->target_location,
            'to_bin' => ''
        ];
        try {
            $result = $this->hpapi->dbCall (
                'wwBookingInsert'
            );
            $booking_id = $result[0]['id'];
            foreach ($moves as $m) {
                $result = $this->hpapi->dbCall (
                    'wwMoveInsert',
                    $m['order_ref'],
                    $booking_id,
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
                if ($booking_id) {
                    $this->hpapi->dbCall (
                        'wwBookingCancel',
                        $booking_id
                    );
                    $this->hpapi->diagnostic ("booking_id=$booking_id moves are cancelled");
                }
            }
            catch (\Exception $e2) {
                $this->hpapi->diagnostic ($e->getMessage());
            }
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $rtn = new \stdClass ();
        $rtn->bookingId = $booking_id;
        $rtn->moves = $this->hpapi->parse2D ($moves);
        return $rtn;
    }

    public function orders ($order_ref) {
        $destination_locations_start_with = WHEREWARE_LOCATIONS_DESTINATIONS;
        $limit = WHEREWARE_RESULTS_LIMIT;
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
                throw new \Exception (WHEREWARE_STR_DB);
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
                        $task->postcode
                    );
                }
                catch (\Exception $e) {
                    $this->hpapi->diagnostic ($e->getMessage());
                    throw new \Exception (WHEREWARE_STR_DB);
                    return false;
                }
                $obj->tasks[$i]->id = $result[0]['id'];
                $obj->tasks[$i]->status = 'N';
            }
            try {
                foreach ($task->skus as $sku) {
                    if ($obj->tasks[$i]->status=='N') {
                        // Add booking ID if any move is missing
                        if (!$booking_id) {
                            $result = $this->hpapi->dbCall (
                                'wwBookingInsert'
                            );
                            $booking_id = $result[0]['id'];
                        }
                        // Insert move
                        $result = $this->hpapi->dbCall (
                            'wwMoveInsert',
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
                        $move_id = $result[0]['id'];
                        // Assign move
                        $assigns[] = [
                            'wwMoveAssign',
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
                throw new \Exception (WHEREWARE_STR_DB);
                return false;
            }
        }
        try {
sleep (1); // Quick hack to prevent ww_movelog duplicate primary key after wwMoveInsert() above
            foreach ($assigns as $a) {
                $result = $this->hpapi->dbCall (
                    ...$a
                );
            }
            $moves = [];
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
            throw new \Exception (WHEREWARE_STR_DB);
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

