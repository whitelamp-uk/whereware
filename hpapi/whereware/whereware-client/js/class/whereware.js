
/* Copyright 2022 Whitelamp http://www.whitelamp.co.uk/ */

import {Generic} from './generic.js';

export class Whereware extends Generic {

    actorsListen (defns) {
        defns.push (
            { class: 'whereware-link', event: 'click', function: this.adminerLink }
        );
        super.actorsListen (defns);
    }

    adminer (request) {
        var count,settings,url,win;
        settings = this.storageRead ('whereware');
        if (settings && settings.whereware_db_user && settings.whereware_db_name) {
            url  = this.adminerUrl;
            url += '?username=' + this.escapeForHtml(settings.whereware_db_user);
            url += '&db=' + this.escapeForHtml(settings.whereware_db_name);
            url += '&' + this.escapeForHtml(request.action) + '=' + this.escapeForHtml(request.table);
            count = 0;
            if (request.action=='select') {
                if ('hidden' in request) {
                    count++;
                    url += '&where['+count+'][col]=hidden';
                    url += '&where['+count+'][op]=' + this.escapeForHtml('=');
                    if (request.hidden>0) {
                        url += '&where['+count+'][val]=1';
                    }
                    else {
                        url += '&where['+count+'][val]=0';
                    }
                }
                if ('cancelled' in request) {
                    count++;
                    url += '&where['+count+'][col]=cancelled';
                    url += '&where['+count+'][op]=' + this.escapeForHtml('=');
                    if (request.cancelled>0) {
                        url += '&where['+count+'][val]=1';
                    }
                    else {
                        url += '&where['+count+'][val]=0';
                    }
                }
            }
            if (request.action=='select' && request.column) {
                count++;
                url += '&where['+count+'][col]=' + this.escapeForHtml(request.column);
                url += '&where['+count+'][op]=' + this.escapeForHtml(request.operator);
                url += '&where['+count+'][val]=' + this.escapeForHtml(request.value);
            }
            else if (request.action=='edit' && column) {
                url += '&where[' + request.column + ']=' + this.escapeForHtml(request.value);
            }
            console.log ('URL: '+url);
            win = 'whereware-adminer-' + request.action;
            if (request.action=='edit' && request.column) {
                win += '-' + request.column;
            }
            win = window.open (url,win);
            win.focus ();
        }
        else {
            this.statusShow ('Missing SQL user and/or database name');
        }
    }

    adminerInit ( ) {
        var dbn,dbu,settings;
        settings = this.storageRead ('whereware');
        if (!settings || !settings.whereware_db_name || !settings.whereware_db_user) {
            settings = {
                whereware_db_name: null,
                whereware_db_user: null
            };
            dbn = this.qs (this.restricted,'#whereware-settings [name="whereware_db_name"]');
            if (dbn) {
                dbn.value = dbn.value.trim ();
                settings.whereware_db_name = dbn.value;
            }
            dbu = this.qs (this.restricted,'#whereware-settings [name="whereware_db_user"]');
            if (dbu) {
                dbu.value = dbu.value.trim ();
                settings.whereware_db_user = dbu.value;
            }
            this.storageWrite ('whereware',settings);
            this.data.whereware.settings = settings;
        }
    }

    adminerLink (evt) {
        var dbn,dbu,request,settings;
        settings = this.storageRead ('whereware');
        if (!settings || !settings.whereware_db_name || !settings.whereware_db_user) {
            settings = {
                whereware_db_name: null,
                whereware_db_user: null
            };
            dbn = this.qs (this.restricted,'#whereware-settings [name="whereware_db_name"]');
            if (dbn) {
                dbn.value = dbn.value.trim ();
                settings.whereware_db_name = dbn.value;
            }
            dbu = this.qs (this.restricted,'#whereware-settings [name="whereware_db_user"]');
            if (dbu) {
                dbu.value = dbu.value.trim ();
                settings.whereware_db_user = dbu.value;
            }
            this.storageWrite ('whereware',settings);
        }
        if (evt && evt.type=='input') {
            evt.currentTarget.value = evt.currentTarget.value.trim ();
            settings[evt.currentTarget.getAttribute('name')] = evt.currentTarget.value;
            this.storageWrite ('whereware',settings);
            return;
        }
        if (evt && evt.type=='click') {
            evt.preventDefault ();
            request = {
                action: evt.currentTarget.dataset.action,
                table: evt.currentTarget.dataset.table,
                column: evt.currentTarget.dataset.column,
                operator: evt.currentTarget.dataset.operator,
                value: evt.currentTarget.dataset.value
            };
            if ('hidden' in evt.currentTarget.dataset) {
                request.hidden = evt.currentTarget.dataset.hidden;
            }
            if ('cancelled' in evt.currentTarget.dataset) {
                request.cancelled = evt.currentTarget.dataset.cancelled;
            }
            this.adminer (request);
        }
    }

    constructor (config) {
        super (config);
        this.data.whereware = {};
    }

    async componentsRequest (searchTerms) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "components"
               ,"arguments" : [
                    searchTerms
                ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.sql = response.returnValue.sql;
            this.data.whereware.components = response.returnValue.skus;
            return response.returnValue;
        }
        catch (e) {
            console.log ('componentsRequest(): could not get allowed components: '+e.message);
            return false;
        }
    }

    async compositesRequest (searchTerms) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "composites"
               ,"arguments" : [
                    searchTerms
                ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.sql = response.returnValue.sql;
            this.data.whereware.composites = response.returnValue.skus;
            return response.returnValue;
        }
        catch (e) {
            console.log ('compositesRequest(): could not get allowed composites: '+e.message);
            return false;
        }
    }

    async move ( ) {
        var bid,form,generics,i,move,request,response;
        form = this.qs (this.restricted,'#picklist');
        if (form.quantity.value<1) {
            this.statusShow ('Quantity at least 1 must be entered');
            return;
        }
        form.location.value.trim ();
        if (form.location.value=='') {
            this.statusShow ('Customer location must be selected');
            return;
        }
        move = {
            composite_quantity: form.quantity.value,
            composite_sku: this.parameters.wherewareSku,
            customer_location: form.location.value,
            order_ref: this.parameters.wherewareOrder,
            picks: []
        };
        for (i=0;form.elements[i];i++) {
            if (form.elements[i].type=='radio' && form.elements[i].checked) {
                move.picks.push (
                    {
                        sku: form.elements[i].dataset.sku,
                        bin: form.elements[i].dataset.bin,
                        quantity: form.elements[i].dataset.quantity,
                    }
                );
            }
        }
        generics = this.qsa (form,'tr.generic');
        if (move.picks.length!=generics.length) {
            this.statusShow ('Every generic must be selected');
            return;
        }
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "move"
               ,"arguments" : [
                    move
                ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.moves = response.returnValue.moves;
            this.parameters.wherewareBookingId = response.returnValue.bookingId;
        }
        catch (e) {
            console.log ('move(): could not move stock: '+e.message);
            return false;
        }
        await this.templateFetch ('booked');
        this.insertRender ('booked',this.qs(this.restricted,'#orders'));
    }

    moveCalculate (evt) {
        var item,items,ndd,nr,qty;
        nr = parseInt (evt.target.value);
        if (nr<1) {
            nr = 1;
        }
        evt.currentTarget.value = nr;
        items = this.qsa (evt.currentTarget.form,'tbody tr.component-bin');
        for (item of items) {
            qty = this.qs(item,'td.selected > input').dataset.quantity;
            ndd = this.qs(item,'td.needs');
            ndd.textContent = nr * parseInt(qty);
        }
    }

    navigatorsSelector ( ) {
        return 'a.navigator,button.navigator,.nugget.navigator,td.navigator';
    }

    orderList (container,rows) {
        var count,dt,dtp,i,lk,k,mod,noresults,sm,order,orders;
        // Listen for parameters from new order
        this.qs(container.parentElement,'tr.new [name="order_ref"]').addEventListener ('input',this.orderNew.bind(this));
        // Build the list
        noresults = this.qs (container,'tr.no-results');
        orders = this.qsa (container,'tr.result');
        for (order of orders) {
            order.remove ();
        }
        count = 0;
        for (i=0;rows[i];i++) {
            count++;
            order = document.createElement ('tr');
            order.classList.add ('result');
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('to_locations');
            k.textContent = rows[i].to_locations;
            order.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('to_locations_customer');
            k.textContent = rows[i].to_locations_customer;
            order.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('adminer');
            lk = document.createElement ('a');
            lk.classList.add ('whereware-link');
            lk.dataset.action = 'select';
            lk.dataset.table = 'ww_move';
            lk.dataset.cancelled = 0;
            lk.dataset.hidden = 0;
            lk.dataset.column = 'order_ref';
            lk.dataset.operator = '=';
            lk.dataset.value = rows[i].order_ref;
            lk.textContent = '↗';
            lk.addEventListener ('click',this.adminerLink.bind(this));
            k.appendChild (lk);
            order.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('order_ref');
            k.textContent = rows[i].order_ref;
            order.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('bookings');
            k.textContent = rows[i].bookings;
            order.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('order_sku');
            k.classList.add ('button');
            k.textContent = 'Book more';
            k.classList.add ('navigator');
            k.dataset.insert = 'book';
            k.dataset.target = 'orders';
            k.dataset.parameter = 'wherewareSkuOrder';
            k.dataset.value = this.parameters.wherewareSku+'::'+rows[i].order_ref;
            order.appendChild (k);
            // Append row
            container.appendChild (order);
        }
        this.navigatorsListen (container.parentElement);
        // Hide/show no-results row
        if (count>0) {
            noresults.classList.add ('hidden');
        }
        else {
            noresults.classList.remove ('hidden');
        }
        // Report the number of results
        return count;
    }


    orderNew (evt) {
        var btn,ord;
        evt.currentTarget.value = evt.currentTarget.value.replace (' ','');
        btn = this.qs (evt.currentTarget.parentElement.parentElement,'td.button.new');
        btn.dataset.value = this.parameters.wherewareSku + '::' + evt.currentTarget.value;
    }

    async ordersRequest ( ) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "orders"
               ,"arguments" : [
                    this.parameters.wherewareSku
                ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.sql = response.returnValue.sql;
            this.data.whereware.orders = response.returnValue.orders;
            return response.returnValue;
        }
        catch (e) {
            console.log ('ordersRequest(): could not get orders for "'+this.parameters.wherewareSku+'": '+e.message);
            return false;
        }
    }

    async picklistRequest (btn) {
        var args,is_new,location,request,response;
        args = this.parameters.wherewareSkuOrder.split ('::');
        this.parameters.wherewareOrder = args[1];
        this.parameters.wherewareLocation = btn.dataset.location;
        if (this.parameters.wherewareOrder) {
            is_new = 0;
            if ('new' in btn.dataset) {
                is_new = 1;
            }
            request     = {
                "email" : this.access.email.value
               ,"method" : {
                    "vendor" : "whereware"
                   ,"package" : "whereware-server"
                   ,"class" : "\\Whereware\\Whereware"
                   ,"method" : "picklist"
                   ,"arguments" : [
                        this.parameters.wherewareSku,
                        this.parameters.wherewareOrder,
                        is_new
                   ]
                }
            }
            try {
                response = await this.request (request);
                this.data.whereware.generics = response.returnValue;
                return response.returnValue;
            }
            catch (e) {
                console.log ('picklistRequest(): could not get pick list for "'+this.parameters.wherewareSkuOrder+'": '+e.message);
                return false;
            }
        }
        else {
            console.log ('picklistRequest(): order reference not given for SKU="'+this.parameters.wherewareSku+'"');
            this.data.whereware.generics = [];
            return [];
        }
    }

    skuList (container,response,composite=false) {
        var count,dt,dtp,i,lk,k,mod,noresults,sm,sku,skus;
        noresults = this.qs (container,'tr.no-results');
        skus = this.qsa (container,'tr.result');
        for (sku of skus) {
            sku.remove ();
        }
        count = 0;
        for (i=0;response.skus[i];i++) {
            count++;
            sku = document.createElement ('tr');
            sku.classList.add ('result');
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('updated');
            k.textContent = response.skus[i].updated;
            sku.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('adminer');
            lk = document.createElement ('a');
            lk.classList.add ('whereware-link');
            lk.dataset.action = 'select';
            lk.dataset.table = 'ww_sku';
            lk.dataset.hidden = response.skus[i].hidden;
            lk.dataset.column = 'sku';
            lk.dataset.operator = '=';
            lk.dataset.value = response.skus[i].sku;
            lk.textContent = '↗';
            lk.addEventListener ('click',this.adminerLink.bind(this));
            k.appendChild (lk);
            sku.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('sku');
            k.classList.add ('button');
            k.textContent = response.skus[i].sku;
            k.classList.add ('navigator');
            k.dataset.insert = 'orders';
            k.dataset.target = 'orders';
            k.dataset.parameter = 'wherewareSku';
            k.dataset.value = response.skus[i].sku;
            sku.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('additional_ref');
            k.textContent = response.skus[i].additional_ref;
            sku.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('name');
            k.textContent = response.skus[i].name;
            sku.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            if (composite) {
                k.title = 'Workflow points to this composite storage bin';
            }
            else {
                k.title = 'Component recommended bin (irrelevant to stock moves or inventory calculations)';
            }
            k.classList.add ('bin');
            k.textContent = response.skus[i].bin;
            sku.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('notes');
            dt = document.createElement ('details');
            sm = document.createElement ('summary');
            sm.textContent = 'Notes';
            dt.appendChild (sm);
            dtp = document.createElement ('p');
            dtp.textContent = response.skus[i].notes;
            dt.appendChild (dtp);
            k.appendChild (dt);
            sku.appendChild (k);
            // Append row
            container.appendChild (sku);
        }
        this.navigatorsListen (container);
        if (count>0) {
            noresults.classList.add ('hidden');
        }
        return count;
    }

}

