<?php

/* Copyright 2022 Whitelamp http://www.whitelamp.co.uk */

namespace Whereware;

class Blueprint {

    /* Interacts with a location/bin/SKU `whereware` database model */

    public $hpapi;

    public function __construct (\Hpapi\Hpapi $hpapi) {
        $this->hpapi            = $hpapi;
        $this->timezone         = $this->hpapi->tzName;
    }

    public function __destruct ( ) {
    }

    public function blueprint ($sku) {
        $blueprint = [];
        try {
            $result = $this->hpapi->dbCall (
                'wwBlueprint',
                $sku
            );
            $result = $this->hpapi->parse2D ($result);
        }
        catch (\Exception $e) {
            $this->hpapi->diagnostic ($e->getMessage());
            throw new \Exception (WHEREWARE_STR_DB);
            return false;
        }
        $blueprint = [];
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
            $blueprint[] = $item;
        }
        return $blueprint;
    }

}
