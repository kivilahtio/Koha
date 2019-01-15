//Package Items
if (typeof Items == "undefined") {
    this.Items = {}; //Set the global package
}

Items.itemGet = function (itemnumber) {
    if (!itemnumber) {
        throw new TypeError("Items.itemGet():> No itemnumber!");
    }

    return new Promise((resolve, reject) => {
        $.ajax("/api/v1/items/"+itemnumber, {
            "method": "GET",
            "accepts": "application/json",
            "contentType": "application/json; charset=utf8",
            "success": function (jqXHR, textStatus, errorThrown) {
                var item = jqXHR;

                if (item.itemnumber) {
                    log.debug(`Items.itemGet(${itemnumber}) :> Got Item `, item);
                    resolve(item);
                }
                else {
                    reject({
                        error: "Missing itemnumber?",
                        item
                    });
                }
            },
            "error": function (jqXHR, textStatus, errorThrown) {
                log.error(`Items.itemGet(${itemnumber}) :> Error `, jqXHR.responseText);
                var responseObject = JSON.parse(jqXHR.responseText);
                reject(responseObject);
            },
        });
    });
};

/**
 * koha.items-row
 *
 * @param {Object} with koha.items-rows columns as attributes
 */
Items.Item = class Item {
    constructor(item) {
        this.itemnumber = item.itemnumber;
        this.biblionumber = item.biblionumber;
        this.biblioitemnumber = item.biblioitemnumber;
        this.barcode = item.barcode;
        this.dateaccessioned = item.dateaccessioned;
        this.datereceived = item.datereceived;
        this.booksellerid = item.booksellerid;
        this.homebranch = item.homebranch;
        this.price = item.price;
        this.replacementprice = item.replacementprice;
        this.replacementpricedate = item.replacementpricedate;
        this.datelastborrowed = item.datelastborrowed;
        this.datelastseen = item.datelastseen;
        this.stack = item.stack;
        this.notforloan = item.notforloan;
        this.damaged = item.damaged;
        this.itemlost = item.itemlost;
        this.itemlost_on = item.itemlost_on;
        this.withdrawn = item.withdrawn;
        this.withdrawn_on = item.withdrawn_on;
        this.itemcallnumber = item.itemcallnumber;
        this.coded_location_qualifier = item.coded_location_qualifier;
        this.issues = item.issues;
        this.renewals = item.renewals;
        this.reserves = item.reserves;
        this.restricted = item.restricted;
        this.itemnotes = item.itemnotes;
        this.itemnotes_nonpublic = item.itemnotes_nonpublic;
        this.holdingbranch = item.holdingbranch;
        this.paidfor = item.paidfor;
        this.timestamp = item.timestamp;
        this.location = item.location;
        this.permanent_location = item.permanent_location;
        this.onloan = item.onloan;
        this.cn_source = item.cn_source;
        this.cn_sort = item.cn_sort;
        this.ccode = item.ccode;
        this.materials = item.materials;
        this.uri = item.uri;
        this.itype = item.itype;
        this.more_subfields_xml = item.more_subfields_xml;
        this.enumchron = item.enumchron;
        this.copynumber = item.copynumber;
        this.stocknumber = item.stocknumber;
        this.new_status = item.new_status;
        this.genre = item.genre;
        this.sub_location = item.sub_location;
        this.circulation_level = item.circulation_level;
        this.reserve_level = item.reserve_level;
        this.holding_id = item.holding_id;

        this._status = item._status || Items.Item.Status.New;

        log.trace(`Items.Item.new():> `, this);
    }

    /**
     * Reload this object from the REST API
     *
     * @returns {Promise}
     */
    reload() {
        this._status = Items.Item.Status.Reloading;
        return new Promise((resolve, reject) => {
            Items.itemGet(this.itemnumber)
            .then((item) => {
                log.debug(`Items.Item.reload(${this.itemnumber}) :> Got item `, item);
                for (let key in item) {
                    this[key] = item[key];
                }
                this._status = Items.Item.Status.Complete;
                resolve(item);
            })
            .catch((error) => {
                log.error(`Items.Item.reload(${this.itemnumber}) :> Reloading a item failed: `, error);
                this._status = error;
                reject(error);
            });
        });
    }
};
Items.Item.cast = function (item) {
    if (typeof item === 'number') {
        return new Items.Item({itemnumber: item, _status: Items.Item.Status.Slim});
    }
    else if (typeof item === 'object') {
        return new Items.Item(item);
    }
    else if (typeof item === 'Item') {
        return item;
    }
    else {
        throw new TypeError(`Cannot cast '${item}' to Item.`);
    }
};
Items.Item.Status = {};
Items.Item.Status.Slim      = 'Slim';
Items.Item.Status.New       = 'New';
Items.Item.Status.Reloading = 'Reloading';
Items.Item.Status.Complete  = 'Complete';

/**
 * Resolves the availability of the given Item and returns a nice html-representation of the Item's availability statuses.
 */
Items.getAvailability = function (item) {

    var html = [];

    if (item.iss_date_due) {
        html.push(
        '<span class="datedue">Checked out to <a href="/cgi-bin/koha/members/moremember.pl?borrowernumber='+item.iss_borrowernumber+'">'+
        item.iss_cardnumber+'</a> : '+MSG_DUE_DATE+' '+item.iss_date_due+"</span>"
        );
    }
    if (item.transfertwhen) {
        html.push(
        '<span class="intransit">'+MSG_IN_TRANSIT+': '+item.transfertfrom+' -> '+item.transfertto+'. '+MSG_TRANSFER_STARTED+' '+item.transfertwhen+"</span>"
        );
    }
    if (item.c_withdrawn) {
        html.push(
        '<span class="wdn">'+MSG_WITHDRAWN+'</span>'
        );
    }
    if (item.c_notforloan) {
        html.push(
        '<span>'+MSG_NOT_FOR_LOAN+''+(item.c_notforloan ? ' ('+item.c_notforloan+')' : "")
        );
    }
    if (item.res_borrowernumber) {
        html.push(
        '<span>'+MSG_HOLD_FOR+' <a href="/cgi-bin/koha/members/moremember.pl?borrowernumber='+item.res_borrowernumber+'">'+item.res_cardnumber+'</a></span>'
        );
    }
    if (item.res_waitingdate) {
        html.push(
        '<span>'+MSG_HOLD_WAITING_SINCE+' '+item.res_waitingdate+'</span>'
        );
    }
    if (item.restricted) {
        html.push(
        '<span class="restricted">('+item.restricted+')</span>'
        );
    }
    if (item.c_itemlost) {
        html.push(
        '<span class="lost">('+item.c_itemlost+')</span>'
        );
    }
    if (item.c_damaged) {
        html.push(
        '<span class="dmg">('+item.c_damaged+')</span>'
        );
    }
    if (html.length == 0) {
        html.push(
        '<span>'+MSG_AVAILABLE+'</span>'
        );
    }

    return html.join('<br/>');
}

/**
 * Adds a Subscriber to the events of this Item. When events occur,
 * Item calls the publish()-function of the Listener with the following parameters:
 *        {Item} this object which initiated the call.
 *        {data} data related to the event
 *        {event} data related to the event.
 *
 * @param {Item-object} this Publisher-object
 * @param {Listener-object} Any object which is configured to subscribe to a Item
 */
Items.subscribe = function(item, subscriber) {
    if (!item._subscribers) {
        item._subscribers = [];
    }
    item._subscribers.push( subscriber );
}
Items.unsubscribe = function(item, subscriber) {
    for (var i=0 ; i<item._subscribers.length ; i++) {
        var subscribingSubscriber = item._subscribers[i];
        if (subscriber === subscribingSubscriber) {
            item._subscribers.splice(i,1);
            break;
        }
    }
}
/**
 * Publishes a publication to all subscribers.
 */
Items.publicate = function (item, data, event) {
    for (var i=0 ; i<item._subscribers.length ; i++) {
        var subscriber = item._subscribers[i];
        subscriber.publish(item, data, event );
    }
}



//Package Items.Cache
if (typeof Items.Cache == "undefined") {
    this.Items.Cache = {}; //Set the global package
}

Items.Cache.map = {};
/**
 * Gets an Item from the local cache.
 * @param {Int} itemnumber
 */
Items.Cache.getLocalItem = function (itemnumber) {
    return Items.Cache.map[itemnumber];
}

/**
 * Adds an Item to the local cache.
 * @param {Item}
 */
Items.Cache.addLocalItem = function (item) {
    Items.Cache.map[item.itemnumber] = item;
}

/**
 * Adds a set of Items to the local cache.
 * @param {Array|Map of Items}
 */
Items.Cache.addLocalItems = function (items) {
    for(var key in items) {
        var item = items[key];
        Items.Cache.map[item.itemnumber] = item;
    }
}

/**
 * Clears the cache or a single Item from it.
 * @param {Int} itemnumber
 */
Items.Cache.clear = function (itemnumber) {
    if (itemnumber) {
        delete Items.Cache.map[itemnumber];
    }
    else {
        Items.Cache.map = {};
    }
}
