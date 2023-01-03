
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
        window.addEventListener ('focus',this.refreshesFocus.bind(this));
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
            k.dataset.parameter = 'wherewareOrder';
            k.dataset.value = rows[i].order_ref;
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
        btn.dataset.value = evt.currentTarget.value;
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

    async picklistRequest (sku) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "picklist"
               ,"arguments" : [
                    sku
               ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.generics = response.returnValue;
            return response.returnValue;
        }
        catch (e) {
            console.log ('picklistRequest(): could not get pick list for "'+sku+'": '+e.message);
            return false;
        }
    }

    async picklistRequestPickNBook ( ) {
        var rtn;
        try {
            rtn = await this.picklistRequest (this.parameters.wherewareSku);
            return rtn;
        }
        catch (e) {
            return false;
        }
    }

    async refreshesCalculate ( ) {
        var b,buttons,g,p,q,qty,quantities;
        if (!('picklists' in this.data.whereware.refreshes)) {
            this.data.whereware.refreshes.picklists = [];
        }
        qty = 0;
        quantities = this.qsa (this.restricted,'.spreadsheet-cell input.spreadsheet-cell-integer');
        for (q of quantities) {
            qty += 1 * q.value;
            p = this.find (this.data.whereware.refreshes.picklists,'sku',q.dataset.sku);
            if (!p) {
                try {
                    g = await this.picklistRequest (q.dataset.sku);
                    p = {
                        sku: q.dataset.sku,
                        generics: g
                    }
                    this.data.whereware.refreshes.picklists.push (p);
                }
                catch (e) {
                    this.statusShow ('Could not fetch picklist');
                    return false;
                }
            }
        }
        // Toggle button for next stage
        buttons = this.qsa (this.restricted,'.whereware-refreshes-book');
        for (b of buttons) {
            if (qty>0) {
                b.disabled = false;
            }
            else {
                b.disabled = true;
            }
        }
    }

    refreshesFocus (evt) {
        if (evt.currentTarget==window) {
            this.refreshesFocusInhibit = true;
            setTimeout (this.refreshesFocusEnable.bind(this),100);
            return;
        }
        if (!this.refreshesFocusInhibit) {
            evt.currentTarget.select ();
        }
    }

    refreshesFocusEnable (evt) {
        this.refreshesFocusInhibit = false;
    }

    refreshesInputInteger (evt) {
        evt.currentTarget.value = this.refreshesLimitInteger (evt.currentTarget.value);
        this.refreshesCalculate ();
    }


    refreshesKeydown (evt) {
        var i,input,inputs,move,p,q,r,row,rows,tbody;
        // Use arrow keys for spreadsheet-like navigation
        if (['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(evt.key) && !evt.shiftKey && !evt.ctrlKey) {
            evt.preventDefault ();
            row = evt.currentTarget.closest ('tr');
            inputs = this.qsa (row,'.spreadsheet-cell input, .spreadsheet-cell select');
            i = 0;
            for (input of inputs) {
                if (input==evt.currentTarget) {
                    p = i;
                }
                i++;
            }
            if (evt.key=='ArrowLeft') {
                // Focus the previous input in the same row
                p--;
            }
            if (evt.key=='ArrowRight') {
                // Focus the next input in the same row
                p++;
            }
            if (p<0) {
                p = i - 1;
            }
            if (p>=i) {
                p = 0;
            }
            tbody = row.closest ('tbody');
            rows = this.qsa (tbody,'tr.result');
            i = 0;
            for (r of rows) {
                if (r==row) {
                    q = i;
                }
                i++;
            }
            if (evt.key=='ArrowUp') {
                // Focus the same input in the previous row
                q--;
            }
            if (evt.key=='ArrowDown') {
                // Focus the same input in the next row
                q++;
            }
            if (q<0) {
                q = i - 1;
            }
            if (q>=i) {
                q = 0;
            }
            row = rows.item (q);
            inputs = this.qsa (row,'.spreadsheet-cell input, .spreadsheet-cell select');
            inputs.item(p).select ();
        }
        // Interfere if necessary
        return true;
    }

    refreshesKeydownInteger (evt) {
        var val;
        if (!(/[0-9]/.test(evt.key))) {
            if (evt.ctrlKey || evt.key=='Backspace' || evt.key=='Delete') {
                // Do not interfere
            }
            else {
                // Suppress
                evt.preventDefault ();
                if (!(/[0-9]/.test(evt.key))) {
                    // Hot key options: use +/- to change integer values
                    if (evt.key=='+' || evt.key=='-') {
                        val = this.refreshesLimitInteger (evt.currentTarget.value);
                        if (evt.key=='+') {
                            val++;
                        }
                        else {
                            val--;
                        }
                        evt.currentTarget.value = this.refreshesLimitInteger (val);
                        this.refreshesCalculate ();
                    }
                }
           }
        }
    }

    refreshesLimitInteger (i) {
        var neg;
        // Sometimes a string, sometimes not
        i = '' + i;
        neg = false;
        if (i.indexOf('-')==0) {
            neg = true;
            i = i.substr (1);
        }
        i = i.replace (/\D/g,'');
        if (i.length==0) {
            i = 0;
        }
        i *= 1;
        if (neg) {
            i = 0 - i;
        }
        if (i>99) {
            i = 99;
        }
        if (i<0) {
            i = 0;
        }
        return i;
    }

    refreshesList (trColumns,tbodyRows) {
        var count,dt,dtp,i,input,j,lk,k,mod,noresults,refreshes,sm,span,team,topleft;
        for (i=0;this.data.whereware.refreshes.skus[i];i++) {
            // Cell:
            k = document.createElement ('th');
            k.classList.add ('sku');
            k.setAttribute ('title','Order '+this.data.whereware.refreshes.skus[i].refresh_order_ref);
            span = document.createElement ('span');
            span.setAttribute ('title','Order '+this.data.whereware.refreshes.skus[i].refresh_order_ref);
            span.textContent = this.data.whereware.refreshes.skus[i].sku;
            k.appendChild (span);
            trColumns.appendChild (k);
        }
        noresults = this.qs (tbodyRows,'tr.no-results');
        count = 0;
        for (j=0;this.data.whereware.teams[j];j++) {
            if (this.data.whereware.teams[j].hidden) {
                continue;
            }
            count++;
            team = document.createElement ('tr');
            team.classList.add ('result');
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('adminer');
            lk = document.createElement ('a');
            lk.classList.add ('whereware-link');
            lk.dataset.action = 'select';
            lk.dataset.table = 'ww_team';
            lk.dataset.column = 'team';
            lk.dataset.operator = '=';
            lk.dataset.value = this.data.whereware.teams[j].team;
            lk.textContent = '↗';
            lk.addEventListener ('click',this.adminerLink.bind(this));
            k.appendChild (lk);
            team.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('team');
            k.textContent = this.data.whereware.teams[j].team;
            team.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('name');
            k.textContent = this.data.whereware.teams[j].name;
            team.appendChild (k);
            // Cell:
            k = document.createElement ('td');
            k.classList.add ('notes');
            dt = document.createElement ('details');
            sm = document.createElement ('summary');
            sm.textContent = 'Notes';
            dt.appendChild (sm);
            dtp = document.createElement ('p');
            dtp.textContent = this.data.whereware.teams[j].notes;
            dtp.addEventListener ('click',function(evt){evt.currentTarget.parentElement.open=false});
            dt.appendChild (dtp);
            k.appendChild (dt);
            team.appendChild (k);
            for (i=0;this.data.whereware.refreshes.skus[i];i++) {
                // Cell:
                k = document.createElement ('td');
                k.classList.add ('spreadsheet-cell');
                input = document.createElement ('input');
                input.classList.add ('spreadsheet-cell-integer');
                input.dataset.team = this.data.whereware.teams[j].team;
                input.dataset.sku = this.data.whereware.refreshes.skus[i].sku;
                input.setAttribute ('value',0);
                input.addEventListener ('focus',this.refreshesFocus.bind(this));
                input.addEventListener ('keydown',this.refreshesKeydown.bind(this));
                input.addEventListener ('keydown',this.refreshesKeydownInteger.bind(this));
                input.addEventListener ('input',this.refreshesInputInteger.bind(this));
                k.appendChild (input);
                team.appendChild (k);
                if (j==0 && i==0) {
                    topleft = input;
                }
            }
            // Append row
            tbodyRows.appendChild (team);
        }
        this.navigatorsListen (tbodyRows);
        if (count>0) {
            noresults.classList.add ('hidden');
        }
        topleft.select ();
        return count;
    }

    async refreshesRequest (btn) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "refreshes"
               ,"arguments" : [
               ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.refreshes = response.returnValue;
            return response.returnValue;
        }
        catch (e) {
            console.log ('refreshesRequest(): could not get refreshes SKU list: '+e.message);
            return false;
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

    async teamsRequest ( ) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "teams"
               ,"arguments" : [
                ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.teams = response.returnValue;
            return response.returnValue;
        }
        catch (e) {
            console.log ('teamsRequest(): could not get teams: '+e.message);
            return false;
        }
    }

}

