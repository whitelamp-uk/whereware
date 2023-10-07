
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
        // Repurposed function (see below)
        this.data.whereware.settings = this.storageRead ('whereware');
        if (!this.data.whereware.settings) {
            this.data.whereware.settings = {
                whereware_db_name: null,
                whereware_db_user: null
            };
        }
        return true;
        // This stuff was the original function that was not called from anywhere
        /*
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
        */
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

    async blueprintRequest (sku) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Blueprint"
               ,"method" : "blueprint"
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
            console.log ('blueprintRequest(): could not get blueprint for "'+sku+'": '+e.message);
            return false;
        }
    }

    constructor (config) {
        super (config);
        this.data.whereware = {};
        window.addEventListener ('focus',this.tasksFocus.bind(this));
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

    async move ( ) {
        var bid,err,form,generics,i,move,request,response;
        form = this.qs (this.restricted,'#picklist');
        if (form.quantity.value<1) {
            this.statusShow ('Quantity at least 1 must be entered');
            return;
        }
        form.location.value.trim ();
        if (form.location.value=='') {
            this.statusShow ('Target location must be selected');
            return;
        }
        move = {
            composite_quantity: form.quantity.value,
            composite_sku: this.parameters.wherewareSku,
            target_location: form.location.value,
            target_bin: form.bin.value,
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
            this.parameters.wherewareBookingIds = response.returnValue.bookingIds;
            await this.templateFetch ('booked');
            this.insertRender ('booked',this.qs(this.restricted,'#orders'));
        }
        catch (e) {
            console.log ('move(): could not move stock: '+e.message);
            err = e.message.split (' ');
            if (err[1]=='403') {
                this.splash (2,'Error','You do not have permission to execute this process','OK');
            }
            else {
                this.splash (2,'Error','Moving process failed to complete','OK');
            }
        }
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
        return 'a.navigator,button.navigator,.nugget.navigator,td.navigator,.results tr.navigator';
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
            k.classList.add ('destination_last');
            k.textContent = rows[i].destination_last + ' ' + rows[i].destination_last_name;
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

    async projectBookClose (evt) {
        evt.currentTarget.parentElement.classList.remove ('active');
    }

    async projectImport (data) {
        var btn,c,cols,div,e,errors,f,html,i,obj,p,q,r,ppp,rows,section,sku,skus,task,tasks,td,th,tr;
        section = document.getElementById ('projects-import');
        e = [];
        obj = {};
        data = Papa.parse (data,this.cfg.papaparse.import);
        if (data.errors.length) {
            e.push ('CSV parse error');
        }
        data = data.data;
        if (data[0]) {
            obj.project = data[0][3];
        }
        if (!obj.project) {
            div = document.createElement ('div');
            div.innerText = 'No project code was given in cell D1';
            div.classList.add ('error');
            section.appendChild (div);
            return;
        }
        if (obj.project!=this.parameters.wherewareProjectSelect.value) {
            div = document.createElement ('div');
            div.innerText = 'Project code in cell D1 does not match selected project '+this.parameters.wherewareProjectSelect.value;
            div.classList.add ('error');
            section.appendChild (div);
            return;
        }
        if (data[1]) {
            obj.locationPrefix = data[1][1];
        }
        if (!obj.locationPrefix) {
            e.push ('No location code prefix was given in cell B2');
        }
        if (data[2]) {
            obj.teamPrefix = data[2][1];
        }
        if (!obj.teamPrefix) {
            e.push ('No team code prefix was given in cell B3');
        }
        obj.skus = [];
        for (r=0;r in data;r++) {
            for (c=0;c in data[r];c++) {
                if (data[r][c]==null) {
                    data[r][c] = '';
                }
                else if (data[r][c].trim) {
                    data[r][c] = data[r][c].trim ();
                }
            }
        }
        if (data[3]) {
            for (c=5;c in data[3];c++) {
                sku = { sku : data[3][c].replace(' ',''), composite : false, name : data[0][c], bin : data[1][c], column: c };
                if (data[2][c]!='' || data[2][c]!='0') {
                    sku.composite = true;
                }
                f = this.find (obj.skus,'sku',sku.sku,false);
                if (f) {
                    e.push ('SKU '+sku.sku+' is not unique');
                }
                obj.skus.push (sku);
            }
        }
        else {
            e.push ('Bad format - missing row 4 (SKUs)');
        }
        obj.tasks = [];
        for (r=4;r in data;r++) {
            task = {
                team : obj.teamPrefix+data[r][0],
                location : obj.locationPrefix+data[r][1],
                name : data[r][2],
                postcode : data[r][3],
                scheduled_date : null,
                skus : [],
            }
            if (data[r][4]) {
                if (data[r][4].match(/^[0-9]{4}[^0-9][0-9]{2}[^0-9][0-9]{2}/)) {
                    task.scheduled_date = data[r][4].substr (0,4) + '-' + data[r][4].substr (5,2) + '-' + data[r][4].substr (8,2);
                }
                else if (data[r][4].match(/^[0-9]{2}[^0-9][0-9]{2}[^0-9][0-9]{4}/)) {
                    task.scheduled_date = data[r][4].substr (6,4) + '-' + data[r][4].substr (3,2) + '-' + data[r][4].substr (0,2);
                }
                else {
                    e.push ('Invalid date format in cell E'+(r+1));
                }
            }
            for (c=5;c in data[r];c++) {
                if (!data[r][c]) {
                    data[r][c] = 0;
                }
                if (!(''+data[r][c]).match(/^[0-9]+$/)) {
                    e.push ('Invalid quantity in cell '+String.fromCharCode(c+65)+(r+1));
                }
                else if (data[r][c]>0) {
                    sku = this.find (obj.skus,'column',c,false);
                    if (!sku || !sku.sku) {
                        e.push ('Missing SKU in cell '+String.fromCharCode(c+65)+'4 for quantity in cell '+String.fromCharCode(c+65)+(r+1));
                    }
                    sku.quantity = data[r][c];
                    task.skus.push (sku);
                }
            }
            obj.tasks.push (task);
        }
        // Render for review
        tasks = await this.tasksRequest (this.parameters.wherewareProjectSelect.value);
        cols = document.getElementById ('projects-import-columns');
        cols.innerHTML = '';
        rows = document.getElementById ('projects-import-rows');
        rows.innerHTML = '';
        errors = this.qsa (this.restricted,'#projects-import div.error');
        for (div of errors) {
            div.remove ();
        }
        if (e.length) {
            for (r=0;e[r];r++) {
                div = document.createElement ('div');
                div.innerText = e[r];
                div.classList.add ('error');
                section.appendChild (div);
            }
        }
        else {
            // Column headings
            th = document.createElement ('th');
            btn = document.createElement ('button');
            btn.innerText = 'Book';
            btn.addEventListener ('click',this.projectUpdate.bind(this));
            th.appendChild (btn);
            cols.appendChild (th);
            th = document.createElement ('th');
            th.innerText = 'Team';
            cols.appendChild (th);
            th = document.createElement ('th');
            th.innerText = 'Location';
            cols.appendChild (th);
            th = document.createElement ('th');
            th.innerText = 'Location name';
            cols.appendChild (th);
            th = document.createElement ('th');
            th.innerText = 'Postcode';
            cols.appendChild (th);
            th = document.createElement ('th');
            th.innerText = 'Date';
            cols.appendChild (th);
            for (c=0;c in obj.skus;c++) {
                html = obj.skus[c].sku;
                if (obj.skus[c].composite) {
                    html += ' <i>[composite]</i>';
                }
                html += '<br/>'+obj.skus[c].name;
                th = document.createElement ('th');
                th.dataset.skus = '1';
                th.dataset.sku = obj.skus[c].sku;
                if (obj.skus[c].composite) {
                    th.dataset.composite = '1';
                }
                th.dataset.bin = obj.skus[c].bin;
                th.dataset.name = obj.skus[c].name;
                th.innerHTML = html;
                cols.appendChild (th);
            }
            // Rows
            for (r=0;r in obj.tasks;r++) {
                tr = document.createElement ('tr');
                tr.dataset.tasks = '1';
                // Action
                td = document.createElement ('td');
                td.dataset.key = obj.tasks[r].location + '-' + obj.tasks[r].scheduled_date;
                task = this.find2 (tasks,'location',obj.tasks[r].location,'scheduled_date',obj.tasks[r].scheduled_date,false);
                if (task) {
                    skus = obj.tasks[r].skus;
                    obj.tasks[r] = task;
                    if (obj.tasks[r].status=='N') {
                        obj.tasks[r].skus = skus;
                    }
                    obj.tasks[r].postcode = obj.tasks[r].location_postcode;
                    td.innerText = '#' + task.id;
                }
                else {
                    obj.tasks[r].status = 'N';
                }
                if (obj.tasks[r].status=='N') {
                    i = document.createElement ('input');
                    i.type = 'checkbox';
                    i.checked = true;
                    td.appendChild (i);
                }
                else {
                    tr.classList.add ('imported');
                    td.innerText += ' ' + obj.tasks[r].status;
                }
                tr.appendChild (td);
                // Team code
                td = document.createElement ('td');
                td.dataset.team = '1';
                td.innerText = obj.tasks[r].team;
                tr.appendChild (td);
                // Location code
                td = document.createElement ('td');
                td.dataset.location = '1';
                td.innerText = obj.tasks[r].location;
                tr.appendChild (td);
                // Location name
                td = document.createElement ('td');
                td.dataset.name = '1';
                td.innerText = obj.tasks[r].name;
                tr.appendChild (td);
                // Location postcode
                td = document.createElement ('td');
                td.dataset.postcode = '1';
                td.innerText = obj.tasks[r].postcode;
                tr.appendChild (td);
                // Task date
                td = document.createElement ('td');
                td.dataset.date = '1';
                td.innerText = obj.tasks[r].scheduled_date;
                tr.appendChild (td);
                // Quantities
                for (c=0;c in obj.skus;c++) {
                    td = document.createElement ('td');
                    if (task) {
                        sku = this.find (task.skus,'sku',obj.skus[c].sku);
                    }
                    else {
                        sku = this.find (obj.tasks[r].skus,'sku',obj.skus[c].sku);
                    }
                    if (sku) {
                        td.dataset.sku = sku.sku;
                        td.innerText = sku.quantity;
                    }
                    else {
                        td.innerText = ' ';
                    }
                    tr.appendChild (td);
                }
                rows.appendChild (tr);
            }
        }
    }

    async projectNewRequest (evt,failMessage=false) {
        var err,form,request,response;
        form = evt.target;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "projectInsert"
               ,"arguments" : [
                    form.project.value,
                    form.name.value,
                    form.notes.value
                ]
            }
        }
        try {
            response = await this.request (request);
            return true;
        }
        catch (e) {
            console.log ('projectNewRequest(): '+e.message);
            err = e.message.split (' ');
            if (err[1]=='403') {
                err = 'You do not have permission to execute this process';
            }
            else {
                if (failMessage) {
                    err = failMessage;
                }
                else {
                    err = 'Failed to create new project';
                }
            }
            throw new Error (err);
            return false;
        }
    }

    async projectUpdate (evt) {
        var c,div,e,es,i,moves,msg,obj,rtn,section,sku,skus,sqs,table,task,tasks,tbody,td,tr;
        obj = { project : this.parameters.wherewareProjectSelect.value, skus : [], tasks : [] };
        table = evt.currentTarget.closest ('table');
        skus = this.qsa (table,'[data-skus]');
        c = 0;
        for (sku of skus) {
            if (sku.dataset.composite) {
                c = 1;
            }
            obj.skus.push (
                {
                    sku : sku.dataset.sku,
                    composite : c,
                    name : sku.dataset.name,
                    bin : sku.dataset.bin
                }
            );
        }
        tasks = this.qsa (table,'[data-tasks]');
        for (task of tasks) {
            i = this.qs(task,'input');
            if (i && i.checked) {
                sqs = [];
                skus = this.qsa (task,'[data-sku]');
                for (sku of skus) {
                    sqs.push (
                        {
                            sku : sku.dataset.sku,
                            quantity : sku.innerText,
                        }
                    );
                }
                obj.tasks.push (
                    {
                        team : this.qs(task,'[data-team]').innerText,
                        location : this.qs(task,'[data-location]').innerText,
                        name : this.qs(task,'[data-name]').innerText,
                        postcode : this.qs(task,'[data-postcode]').innerText,
                        scheduled_date : this.qs(task,'[data-date]').innerText,
                        skus : sqs
                    }
                );
            }
        }
        try {
            rtn = await this.projectUpdateRequest (obj);
        }
        catch (e) {
            msg = e.message;
        }
        if (rtn && rtn.moves) {
            // Stuff happened so all tasks in the update can be changed in the view
            for (i=0;rtn.tasks[i];i++) {
                // Checkbox/status in first column
                td = this.qs (table,'[data-key="'+rtn.tasks[i].location+'-'+rtn.tasks[i].scheduled_date+'"]');
                td.innerHTML = '';
                td.innerText = '#' + rtn.tasks[i].id + ' P';
                td.closest('tr').classList.add ('imported');
            }
        }
        // Report results
        section = this.qs (this.restricted,'#projects-booked');
        table = this.qs (section,'table.results');
        tbody = this.qs (table,'tbody');
        tbody.innerHTML = '';
        es = this.qsa (section,'div.error');
        for (e of es) {
            e.remove ();
        }
        if (rtn && rtn.tasks.length>0) {
            if (rtn.moves) {
                table.classList.add ('active');
                for (i=0;rtn.moves[i];i++) {
                    tr = document.createElement ('tr');
                    // booking ID
                    td = document.createElement ('td');
                    td.innerText = '#' + rtn.moves[i].booking_id;
                    tr.appendChild (td);
                    // team
                    td = document.createElement ('td');
                    td.innerText = rtn.moves[i].team;
                    tr.appendChild (td);
                    // task
                    td = document.createElement ('td');
                    td.innerText = '#' + rtn.moves[i].task_id;
                    tr.appendChild (td);
                    // status
                    td = document.createElement ('td');
                    td.innerText = rtn.moves[i].status;
                    tr.appendChild (td);
                    // quantity
                    td = document.createElement ('td');
                    td.innerText = rtn.moves[i].quantity;
                    tr.appendChild (td);
                    // sku
                    td = document.createElement ('td');
                    td.innerText = rtn.moves[i].sku;
                    tr.appendChild (td);
                    // from
                    td = document.createElement ('td');
                    td.innerText = rtn.moves[i].from_location + ' / ' + rtn.moves[i].from_bin;
                    tr.appendChild (td);
                    // to
                    td = document.createElement ('td');
                    td.innerText = rtn.moves[i].to_location + ' / ' + rtn.moves[i].to_bin;
                    tr.appendChild (td);
                    // append row
                    tbody.appendChild (tr);
                }
            }
            else {
                table.classList.remove ('active');
                div = document.createElement ('div');
                div.classList.add ('error');
                div.innerText = msg;
                section.appendChild (div);
            }
        }
        else {
            table.classList.remove ('active');
            div = document.createElement ('div');
            div.classList.add ('error');
            div.innerText = msg;
            section.appendChild (div);
        }
        section.classList.add ('active');
    }

    async projectUpdateRequest (obj) {
        var err,request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "projectUpdate"
               ,"arguments" : [
                    obj
               ]
            }
        }
        try {
            response = await this.request (request);
            return response.returnValue;
        }
        catch (e) {
            console.log ('projectUpdateRequest(): '+e.message);
            err = e.message.split (' ');
            if (err[1]=='403') {
                err = 'You do not have permission to execute this process';
            }
            else {
                err = 'Booking process failed to complete';
            }
            throw new Error (err);
            return false;
        }
    }

    projectUpload (evt) {
        var fn,sp,target;
        target          = evt.currentTarget;
        fn              = this.projectImport.bind (this);
        sp              = this.splash.bind (this);
        this.fileRead (target.files[0],'text/csv')
            .then (
                (rtn) => {
                    fn (rtn);
                }
            )
            .catch (
                (err) => {
                    sp (2,err.message,'Error','OK');
                }
            )
        ;
    }

    projectView (evt) {
        var button,input,project;
        if (evt.currentTarget.value) {
            project = this.find (this.data.whereware.projects,'project',evt.currentTarget.value,false);
        }
        input = document.getElementById ('projects-tasks-import');
        button = document.getElementById ('projects-tasks-import-button');
        if (input && button) {
            if (project) {
                input.disabled = false;
                button.disabled = false;
            }
            else {
                input.disabled = true;
                button.disabled = true;
            }
        }
    }

    projectsOptions (projectSelect,csvInput,closeButton) {
        var i,o;
        for (i=(this.data.whereware.projects.length-1);i>=0;i--) {
            o = document.createElement ('option');
            o.value = this.data.whereware.projects[i].project;
            o.innerText = this.data.whereware.projects[i].project + ' ' + this.data.whereware.projects[i].name;
            projectSelect.appendChild (o);
        }
        projectSelect.addEventListener ('change',this.projectView.bind(this));
        csvInput.addEventListener ('change',this.projectUpload.bind(this));
        closeButton.addEventListener ('click',this.projectBookClose.bind(this));
        this.parameters.wherewareProjectSelect  = projectSelect;
    }

    async projectsRequest (btn) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "projects"
               ,"arguments" : [
                    null
               ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.projects = response.returnValue;
            return response.returnValue;
        }
        catch (e) {
            console.log ('projectsRequest(): could not get projects list: '+e.message);
            return false;
        }
    }

    returnsOptions (teamSelect,bookButton,closeButtonSkus,closeButtonBooked) {
        var i,o;
        for (i=0;this.data.whereware.teams[i];i++) {
            o = document.createElement ('option');
            o.value = this.data.whereware.teams[i].team;
            o.innerText = this.data.whereware.teams[i].name;
            teamSelect.appendChild (o);
        }
        teamSelect.addEventListener ('change',this.returnsTasks.bind(this));
        bookButton.addEventListener ('click',this.returnsBook.bind(this));
        closeButtonSkus.addEventListener ('click',this.returnsClose.bind(this));
        closeButtonBooked.addEventListener ('click',this.returnsClose.bind(this));
        this.parameters.wherewareTeamSelect  = teamSelect;
    }

    async returnsBook (evt) {
        var bin,div,e,es,i,locn,msg,qty,row,rows,rtn,returns,scn,scn2,sku,table,tbody,td,tid,tr;
        table = evt.currentTarget.closest ('table');
        scn = table.closest ('section');
        tbody = this.qs (table,'tbody');
        rows = this.qsa (tbody,'tr');
        returns = {
            task_id : null,
            team : null,
            moves : []
        }
        for (row of rows) {
            if (this.qs(row,'input[type="checkbox"]').checked) {
                qty = this.qs(row,'[name="quantity"]').value;
                sku = this.qs(row,'[data-sku]').dataset.sku;
                locn = this.qs(row,'[name="location"]').value;
                bin = this.qs(row,'[name="bin"]').value;
                if (qty && locn && bin) {
                    returns.task_id = row.dataset.task_id;
                    returns.team = row.dataset.team;
                    returns.moves.push (
                        {
                            quantity: qty,
                            sku : sku,
                            from_location: row.dataset.from_location,
                            to_location: locn,
                            to_bin: bin
                        }
                    );
                }
                else {
                    this.splash (2,'Selected items must have quantity, location and bin','Missing data');
                    return;
                }
            }
        }
        if (returns.moves.length>0) {
            try {
                rtn = await this.returnsRequest (returns);
            }
            catch (e) {
                msg = e.message;
            }
        }
        else {
            this.splash (2,'No returns were selected','Missing data');
            return;
        }
        // Close view
        scn.classList.remove ('active');
        // Report results
        scn = this.qs (this.restricted,'#returns-booked');
        table = this.qs (scn,'table');
        tbody = this.qs (table,'tbody');
        tbody.innerHTML = '';
        if (rtn) {
            table.classList.add ('active');
            for (i=0;rtn[i];i++) {
                tr = document.createElement ('tr');
                // booking ID
                td = document.createElement ('td');
                td.innerText = '#' + rtn[i].booking_id;
                tr.appendChild (td);
                // team
                td = document.createElement ('td');
                td.innerText = rtn[i].team;
                tr.appendChild (td);
                // task
                td = document.createElement ('td');
                td.innerText = '#' + rtn[i].task_id;
                tr.appendChild (td);
                // status
                td = document.createElement ('td');
                td.innerText = rtn[i].status;
                tr.appendChild (td);
                // quantity
                td = document.createElement ('td');
                td.innerText = rtn[i].quantity;
                tr.appendChild (td);
                // sku
                td = document.createElement ('td');
                td.innerText = rtn[i].sku;
                tr.appendChild (td);
                // from
                td = document.createElement ('td');
                td.innerText = rtn[i].from_location + ' / ' + rtn[i].from_bin;
                tr.appendChild (td);
                // to
                td = document.createElement ('td');
                td.innerText = rtn[i].to_location + ' / ' + rtn[i].to_bin;
                tr.appendChild (td);
                // append row
                tbody.appendChild (tr);
            }
        }
        else {
            table.classList.remove ('active');
            es = this.qsa (scn,'div.error');
            for (e of es) {
                e.remove ();
            }
            div = document.createElement ('div');
            div.classList.add ('error');
            div.innerText = msg;
            scn.appendChild (div);
        }
        scn.classList.add ('active');
    }

    async returnsClose (evt) {
        evt.currentTarget.parentElement.classList.remove ('active');
    }

    async returnsRequest (returns) {
        var err,request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "returns"
               ,"arguments" : [
                    returns
                ]
            }
        }
        try {
            response = await this.request (request);
            return response.returnValue;
        }
        catch (e) {
            console.log ('projectUpdateRequest(): '+e.message);
            err = e.message.split (' ');
            if (err[0]=='611') {
                err.shift ();
                err.shift ();
                err = err.join(' ') + ' - this could be because either (a) the return has already been recorded or (b) the task fulfilment was never recorded.';
            }
            else if (err[1]=='403') {
                err = 'You do not have permission to execute this process';
            }
            else {
                err = 'Booking process failed to complete';
            }
            throw new Error (err);
            return false;
        }
    }

    async returnsTasks (evt) {
        var btn,cnt,i,task,tasks,td,team,tr,rows,section;
        team = evt.currentTarget.value;
        if (!team) {
            return;
        }
        await this.teamRequest (team);
        section = this.qs (this.restricted,'#returns-tasks');
        section.classList.remove ('active');
        rows = this.qs (this.restricted,'#returns-tasks-rows');
        rows.innerHTML = '';
        cnt = 0;
        for (i=0;this.data.whereware.team.tasks[i];i++) {
            task = this.data.whereware.team.tasks[i];
            if (!task.rebooks_task_id) {
                // Create row
                tr = document.createElement ('tr');
                tr.dataset.team = this.data.whereware.team.team;
                // Team
                td = document.createElement ('td');
                td.innerText = this.data.whereware.team.name;
                tr.appendChild (td);
                // Location
                td = document.createElement ('td');
                td.innerText = task.location_name;
                tr.appendChild (td);
                // Task date
                td = document.createElement ('td');
                td.innerText = task.scheduled_date;
                tr.appendChild (td);
                // Button
                td = document.createElement ('td');
                btn = document.createElement ('button');
                btn.dataset.id = task.id;
                btn.innerText = 'Returns';
                btn.addEventListener ('click',this.returnsSkus.bind(this));
                td.appendChild (btn);
                tr.appendChild (td);
                // Append row
                rows.appendChild (tr);
                cnt++;
            }
        }
        if (cnt>0) {
            section.classList.add ('active');
        }
    }

    async returnsSkus (evt) {
        var b,i,ip,h3,j,opt,rows,section,sel,task,td,tn,tr;
        task = this.find (this.data.whereware.team.tasks,'id',evt.currentTarget.dataset.id,false);
        section = this.qs (this.restricted,'#returns-skus');
        h3 = this.qs (section,'h3');
        h3.innerText = task.location_name + ' ' + task.scheduled_date;
        section.classList.remove ('active');
        rows = this.qs (this.restricted,'#returns-skus-rows');
        rows.innerHTML = '';
        for (i=0;task.skus[i];i++) {
            // Create row
            tr = document.createElement ('tr');
            tr.dataset.task_id = task.id;
            tr.dataset.from_location = task.location;
            tr.dataset.team = this.data.whereware.team.team;
            // Quantity
            td = document.createElement ('td');
            ip = document.createElement ('input');
            ip.classList.add ('quantity');
            ip.setAttribute ('type','number');
            ip.setAttribute ('min',1);
            ip.setAttribute ('max',task.skus[i].quantity);
            ip.setAttribute ('step',1);
            ip.setAttribute ('name','quantity');
            ip.setAttribute ('value',1);
            td.appendChild (ip);
            tr.appendChild (td);
            // SKU
            td = document.createElement ('td');
            td.dataset.sku = task.skus[i].sku;
            td.innerText = task.skus[i].sku;
            tr.appendChild (td);
            // Return location
            td = document.createElement ('td');
            ip = document.createElement ('input');
            ip.classList.add ('location');
            ip.setAttribute ('type','text');
            ip.setAttribute ('name','location');
            ip.setAttribute ('value',this.data.config.constants.WHEREWARE_RETURNS_LOCATION.value);
            td.appendChild (ip);
            tn = document.createTextNode (' / ');
            td.appendChild (tn);
            sel = document.createElement ('select');
            sel.classList.add ('bin');
            sel.setAttribute ('name','bin');
            opt = document.createElement ('option');
            opt.setAttribute ('value','');
            opt.innerText = 'Select:';
            sel.appendChild (opt);
            for (j=0;j<this.data.config.constants.WHEREWARE_RETURNS_BINS.value.length;j++) {
                b = this.data.config.constants.WHEREWARE_RETURNS_BINS.value[j];
                opt = document.createElement ('option');
                opt.setAttribute ('value',b);
                opt.innerText = b;
                sel.appendChild (opt);
            }
            td.appendChild (sel);
            tr.appendChild (td);
            // Select by checkbox
            td = document.createElement ('td');
            ip = document.createElement ('input');
            ip.setAttribute ('type','checkbox');
            td.appendChild (ip);
            tr.appendChild (td);
            // Append row
            rows.appendChild (tr);
        }
        section.classList.add ('active');
    }

    skuList (container,response) {
        var count,dt,dtp,i,lk,k,mod,noresults,sm,sku,skus;
        noresults = this.qs (container,'tr.no-results');
        skus = this.qsa (container,'tr.result');
        for (sku of skus) {
            sku.remove ();
        }
        count = 0;
        if ('skus' in response) {
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
                k.dataset.sku = response.skus[i].sku
                k.textContent = response.skus[i].sku;
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
                k.classList.add ('in_bins');
                k.textContent = response.skus[i].in_bins;
                sku.appendChild (k);
                // Cell:
                k = document.createElement ('td');
                k.classList.add ('available');
                k.textContent = response.skus[i].available;
                sku.appendChild (k);
                // Cell:
                k = document.createElement ('td');
                k.classList.add ('location-bin');
                k.textContent = response.skus[i].location_bin;
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
        }
        if (count>0) {
            noresults.classList.add ('hidden');
        }
        else {
            noresults.classList.remove ('hidden');
        }
        return count;
    }

    async skusRequest (searchTerms,composites,components) {
        var request,response;
        if (!composites && !components) {
            console.log ('skusRequest(): SKUs searches are for composites, components or both');
            return false;
        }
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "skus"
               ,"arguments" : [
                    searchTerms,
                    composites,
                    components
                ]
            }
        }
        response = await this.request (request);
        this.data.whereware.sql = response.returnValue.sql;
        this.data.whereware.composites = response.returnValue.skus;
        return response.returnValue;
    }

    tasksFocus (evt) {
        if (evt.currentTarget==window) {
            this.tasksFocusInhibit = true;
            setTimeout (this.tasksFocusEnable.bind(this),100);
            return;
        }
        if (!this.tasksFocusInhibit) {
            evt.currentTarget.select ();
        }
    }

    tasksFocusEnable (evt) {
        this.tasksFocusInhibit = false;
    }

    tasksInputInteger (evt) {
        evt.currentTarget.value = this.tasksLimitInteger (evt.currentTarget.value);
    }

    tasksKeydown (evt) {
        // Use arrow keys for spreadsheet-like navigation
        if (['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(evt.key) && !evt.shiftKey && !evt.ctrlKey) {
            var i,input,inputs,move,p,q,r,row,rows,tbody;
            evt.preventDefault ();
            row = evt.currentTarget.closest ('tr');
            inputs = this.qsa (row,'.spreadsheet-cell a, .spreadsheet-cell button, .spreadsheet-cell input, .spreadsheet-cell select');
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
            inputs = this.qsa (row,'.spreadsheet-cell a, .spreadsheet-cell button, .spreadsheet-cell input, .spreadsheet-cell select');
            input = inputs.item(p);
            input.focus ();
            if (input.classList.contains('spreadsheet-cell-integer')) {
                input.select ();
            }
            return true;
        }
        if (['ArrowUp','ArrowDown'].includes(evt.key) && evt.shiftKey && evt.currentTarget.tagName.toLowerCase()=='select') {
            // Roll through select options
            var i;
            i = evt.currentTarget.selectedIndex;
            if (evt.key=='ArrowDown' && (evt.currentTarget.selectedIndex+1)<evt.currentTarget.options.length) {
                i++;
            }
            else if (evt.key=='ArrowDown' && evt.currentTarget.selectedIndex>0) {
                i--;
            }
            evt.currentTarget.selectedIndex = i;
            return true;
        }
        return true;
    }

    tasksKeydownInteger (evt) {
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
                        val = this.tasksLimitInteger (evt.currentTarget.value);
                        if (evt.key=='+') {
                            val++;
                        }
                        else {
                            val--;
                        }
                        evt.currentTarget.value = this.tasksLimitInteger (val);
                    }
                }
           }
        }
    }

    tasksLimitInteger (i) {
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

    async tasksMatrix ( ) {
        var btn,count,dt,dtp,i,input,j,lk,k,task,tasks,mod,noresults,n,o,p,projects,s,si,sku,skus,sm,span,t,topleft;
        // Clear the old results
        tasks = this.qsa (this.parameters.wherewareRowsElmt,'tr.result');
        for (task of tasks) {
            task.remove ();
        }
        skus = this.qsa (this.parameters.wherewareHeadingsElmt,'th.sku');
        for (sku of skus) {
            sku.remove ();
        }
        // Find the SKUs for the project
        skus = [];
        if (this.parameters.wherewareProjectSelect.value) {
            skus = this.find(this.data.whereware.projects,'project',this.parameters.wherewareProjectSelect.value,false).skus;
        }
        noresults = this.qs (this.parameters.wherewareRowsElmt,'tr.no-results');
        count = 0;
        if (this.parameters.wherewareProjectSelect.value!='') {
            await this.tasksRequest ();
            for (j=0;this.data.whereware.tasks[j];j++) {
                if (this.data.whereware.tasks[j].hidden) {
                    continue;
                }
                count++;
                task = document.createElement ('tr');
                task.classList.add ('result');
                // Adminer link
                k = document.createElement ('td');
                k.classList.add ('spreadsheet-cell');
                k.classList.add ('adminer');
                lk = document.createElement ('button');
                lk.classList.add ('whereware-link');
                lk.dataset.action = 'select';
                lk.dataset.table = 'ww_task';
                lk.dataset.column = 'location';
                lk.dataset.operator = '=';
                lk.dataset.value = this.data.whereware.tasks[j].location;
                lk.setAttribute ('title','View in Adminer');
                lk.textContent = '↗';
                lk.addEventListener ('keydown',this.tasksKeydown.bind(this));
                lk.addEventListener ('click',this.adminerLink.bind(this));
                k.appendChild (lk);
                task.appendChild (k);
                // Raise button
                k = document.createElement ('td');
                k.classList.add ('spreadsheet-cell');
                k.classList.add ('raise');
                btn = document.createElement ('button');
                btn.classList.add ('whereware-tasks-raise');
                btn.innerText = "Raise";
                btn.dataset.taskid = this.data.whereware.tasks[j].id;
//                btn.disabled = true;
                btn.addEventListener ('keydown',this.tasksKeydown.bind(this));
                k.appendChild (btn);
                task.appendChild (k);
                // Update button
                k = document.createElement ('td');
                k.classList.add ('spreadsheet-cell');
                k.classList.add ('update');
                btn = document.createElement ('button');
                btn.classList.add ('whereware-tasks-update');
                btn.innerText = "Update";
                btn.dataset.taskid = this.data.whereware.tasks[j].id;
//                btn.disabled = true;
                btn.addEventListener ('keydown',this.tasksKeydown.bind(this));
                k.appendChild (btn);
                task.appendChild (k);
                // Location
                k = document.createElement ('td');
                k.classList.add ('location');
                k.textContent = this.data.whereware.tasks[j].location + ' ' + this.data.whereware.tasks[j].location_name;
                task.appendChild (k);
                // Scheduled date
                k = document.createElement ('td');
                k.classList.add ('spreadsheet-cell');
                k.classList.add ('scheduled_date');
                input = document.createElement ('input');
                input.type = 'date';
                input.name = 'scheduled_date';
                input.value = this.data.whereware.tasks[j].scheduled_date;
                input.setAttribute ('placeholder','Scheduled date');
                input.addEventListener ('keydown',this.tasksKeydown.bind(this));
                k.appendChild (input);
                task.appendChild (k);
                // Team select
                k = document.createElement ('td');
                k.classList.add ('spreadsheet-cell');
                k.classList.add ('team');
                s = document.createElement ('select');
                s.name = 'team';
                o = document.createElement ('option');
                o.value = '';
                o.innerText = 'Unassigned';
                s.appendChild (o);
                si = 0;
                for (n=0;this.data.whereware.teams[n];n++) {
                    o = document.createElement ('option');
                    o.value = this.data.whereware.teams[n].team;
                    o.innerText = this.data.whereware.teams[n].team + ' ' + this.data.whereware.teams[n].name;
                    s.appendChild (o);
                    if (this.data.whereware.teams[n].team==this.data.whereware.tasks[j].team) {
                        si = n + 1;
                    }
                }
                s.selectedIndex = si;
                s.addEventListener ('keydown',this.tasksKeydown.bind(this));
                k.appendChild (s);
                task.appendChild (k);
                // Notes
                k = document.createElement ('td');
                k.classList.add ('notes');
                if (this.data.whereware.tasks[j].notes) {
                    dt = document.createElement ('details');
                    sm = document.createElement ('summary');
                    sm.textContent = 'Notes';
                    dt.appendChild (sm);
                    dtp = document.createElement ('p');
                    dtp.textContent = this.data.whereware.tasks[j].notes;
                    dtp.addEventListener ('click',function(evt){evt.currentTarget.parentElement.open=false});
                    dt.appendChild (dtp);
                    k.appendChild (dt);
                }
                else {
                    k.innerHTML = '&nbsp;';
                }
                task.appendChild (k);
                for (i=0;skus[i];i++) {
                    if (skus[i].hidden) {
                        continue;
                    }
                    // SKU quantity
                    k = document.createElement ('td');
                    k.classList.add ('spreadsheet-cell');
                    input = document.createElement ('input');
                    input.classList.add ('spreadsheet-cell-integer');
                    input.dataset.location = this.data.whereware.tasks[j].location;
                    input.dataset.sku = skus[i].sku;
                    input.setAttribute ('value',0);
                    input.addEventListener ('focus',this.tasksFocus.bind(this));
                    input.addEventListener ('keydown',this.tasksKeydown.bind(this));
                    input.addEventListener ('keydown',this.tasksKeydownInteger.bind(this));
                    input.addEventListener ('input',this.tasksInputInteger.bind(this));
                    k.appendChild (input);
                    task.appendChild (k);
                    if (j==0 && i==0) {
                        topleft = input;
                    }
                }
                if (!skus.length) {
                    k = document.createElement ('td');
                    k.classList.add ('spreadsheet-cell');
                    k.innerText = 'No SKUs for project';
                    task.appendChild (k);
                }
                // Append row
                this.parameters.wherewareRowsElmt.appendChild (task);
            }
        }
        this.navigatorsListen (this.parameters.wherewareRowsElmt);
        if (count>0) {
            noresults.classList.add ('hidden');
        }
        else {
            noresults.classList.remove ('hidden');
        }
        // SKU headings
        for (i=0;skus[i];i++) {
            if (skus[i].hidden) {
                continue;
            }
            // Cell:
            k = document.createElement ('th');
            k.classList.add ('sku');
            span = document.createElement ('span');
            span.textContent = skus[i].sku;
            k.appendChild (span);
            this.parameters.wherewareHeadingsElmt.appendChild (k);
        }
        if (topleft) {
            topleft.select ();
        }
        return count;
    }

    tasksOptions (projectSelect,headingsElmt,rowsElmt) {
        var i,o;
        for (i=0;this.data.whereware.projects[i];i++) {
            o = document.createElement ('option');
            o.value = this.data.whereware.projects[i].project;
            o.innerText = this.data.whereware.projects[i].name;
            projectSelect.appendChild (o);
        }
        projectSelect.addEventListener ('change',this.tasksMatrix.bind(this));
        this.parameters.wherewareProjectSelect  = projectSelect;
        this.parameters.wherewareHeadingsElmt   = headingsElmt;
        this.parameters.wherewareRowsElmt       = rowsElmt;
    }

    async tasksRequest (project) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "tasks"
               ,"arguments" : [
                    project
                ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.tasks = response.returnValue;
            return response.returnValue;
        }
        catch (e) {
            console.log ('tasksRequest(): could not get tasks for project '+project+': '+e.message);
            return false;
        }
    }

    async teamRequest (team) {
        var request,response;
        request     = {
            "email" : this.access.email.value
           ,"method" : {
                "vendor" : "whereware"
               ,"package" : "whereware-server"
               ,"class" : "\\Whereware\\Whereware"
               ,"method" : "team"
               ,"arguments" : [
                    team
                ]
            }
        }
        try {
            response = await this.request (request);
            this.data.whereware.team = response.returnValue;
            return response.returnValue;
        }
        catch (e) {
            console.log ('teamRequest(): could not get team: '+e.message);
            return false;
        }
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

