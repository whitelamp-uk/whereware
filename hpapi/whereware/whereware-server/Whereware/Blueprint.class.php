<?php

/* Copyright 2022 Whitelamp http://www.whitelamp.co.uk */

namespace Whereware;

require_once __DIR__.'/Whereware.class.php';

class Blueprint extends Whereware {

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
        $blueprint = new \stdClass ();
        $blueprint->sku = $sku;
        $blueprint->additional_ref = '';
        $blueprint->name = '';
        $blueprint->generics = [];
        foreach ($result as $item) {
            $blueprint->additional_ref = $item->additional_ref;
            $blueprint->name = $item->sku_name;
            $item->options = explode (',',$item->options_preferred_first);
            unset ($item->options_preferred_first);
            $item->components = [];
            foreach ($item->options as $o) {
                $c = new \stdClass ();
                $o = explode (':',$o);
                $c->quantity = $o[0];
                $c->sku = $o[1];
                $c->additional_ref = $o[2];
                $c->name = $o[3];
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
            $blueprint->generics[] = $item;
        }
        return $blueprint;
    }

    public function generics ($search_terms) {
        $max = WHEREWARE_RESULTS_LIMIT;
        $limit = $max + 1;
        $rtn = new \stdClass ();
        $rtn->generics = [];
        $like = $this->searchLike ($search_terms);
        if ($like) {
            $rtn->sql = "CALL `wwSkus`('$like',$limit);";
            try {
                $result = $this->hpapi->dbCall (
                    'wwGenerics',
                    $like,
                    $limit
                );
            }
            catch (\Exception $e) {
                $this->hpapi->diagnostic ($e->getMessage());
                throw new \Exception (WHEREWARE_STR_DB);
                return false;
            }
            $rtn->skus = $this->hpapi->parse2D ($result);
            if (count($rtn->skus)>$max) {
                // Strictly limit generosity
                throw new \Exception (WHEREWARE_STR_RESULTS_LIMIT);
                return false;
            }
        }
        return $rtn;
    }

}

