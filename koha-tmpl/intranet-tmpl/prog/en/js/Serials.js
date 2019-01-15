//Package Serials
if (typeof Serials == "undefined") {
    this.Serials = {}; //Set the global package
}
var log = log;
if (!log) {
    log = log4javascript.getDefaultLogger();
}

Serials.serialGet = function (serialid) {
    if (!serialid) {
        throw new TypeError("Serials.serialGet():> No serialid!");
    }

    return new Promise((resolve, reject) => {
        $.ajax("/api/v1/serials/"+serialid, {
            "method": "GET",
            "accepts": "application/json",
            "contentType": "application/json; charset=utf8",
            "success": function (jqXHR, textStatus, errorThrown) {
                var serial = jqXHR;

                if (serial.serialid) {
                    if (log.isDebugEnabled()) log.debug(`Serials.serialGet(${serialid}) :> Got serial '${Serials.stringifyError(serial)}'`);
                    resolve(serial);
                }
                else {
                    reject({
                        error: "Missing serialid?",
                        serial
                    });
                }
            },
            "error": function (jqXHR, textStatus, errorThrown) {
                log.error(`Serials.serialGet(${serialid}) :> Error `, jqXHR.responseText);
                var responseObject = JSON.parse(jqXHR.responseText);
                reject(responseObject);
            },
        });
    });
};

Serials.serialDelete = function (serialid) {
    if (!serialid) {
        throw new TypeError("Serials.serialDelete():> No serialid!");
    }

    return new Promise((resolve, reject) => {
        $.ajax("/api/v1/serials/"+serialid, {
            "method": "DELETE",
            "accepts": "application/json",
            "contentType": "application/json; charset=utf8",
            "success": function (jqXHR, textStatus, errorThrown) {
                var serial = jqXHR;

                if (serial.serialid) {
                    if (log.isDebugEnabled()) log.debug(`Serials.serialDelete(${serialid}) :> Deleted serial '${Serials.stringifyError(serial)}'`);
                    resolve(serial);
                }
                else {
                    reject({
                        error: "Missing serialid?",
                        serial
                    });
                }
            },
            "error": function (jqXHR, textStatus, errorThrown) {
                log.error(`Serials.serialDelete(${serialid}) :> Error `, jqXHR.responseText);
                var responseObject = JSON.parse(jqXHR.responseText);
                reject(responseObject);
            },
        });
    });
};

Serials.serialPost = function (serial) {
    return new Promise((resolve, reject) => {
        $.ajax("/api/v1/serials/", {
            "method": "POST",
            "accepts": "application/json",
            "contentType": "application/json; charset=utf8",
            "processData": false,
            "data": JSON.stringify(serial),
            "success": function (jqXHR, textStatus, errorThrown) {
                var serial = jqXHR;

                if (serial.serialid) {
                    if (log.isDebugEnabled()) log.debug(`Serials.serialPost(${serial.serialid}) :> Got serial '${Serials.stringifyError(serial)}'`);
                    resolve(serial);
                }
                else {
                    reject({
                        error: "Missing serialid?",
                        serial
                    });
                }
            },
            "error": function (jqXHR, textStatus, errorThrown) {
                log.error(`Serials.serialPost(${serial.serialid}) :> Error `, jqXHR.responseText);
                var responseObject = JSON.parse(jqXHR.responseText);
                reject(responseObject);
            },
        });
    });
};

Serials.serialPut = function (serial) {
    return new Promise((resolve, reject) => {
        $.ajax("/api/v1/serials/"+serial.serialid, {
            "method": "PUT",
            "accepts": "application/json",
            "contentType": "application/json; charset=utf8",
            "processData": false,
            "data": JSON.stringify(serial),
            "success": function (jqXHR, textStatus, errorThrown) {
                var serial = jqXHR;

                if (serial.serialid) {
                    if (log.isDebugEnabled()) log.debug(`Serials.serialPut(${serial.serialid}) :> Got serial '${Serials.stringifyError(serial)}'`);
                    resolve(serial);
                }
                else {
                    reject({
                        error: "Missing serialid?",
                        serial
                    });
                }
            },
            "error": function (jqXHR, textStatus, errorThrown) {
                log.error(`Serials.serialPut(${serial.serialid}) :> Error `, jqXHR.responseText);
                var responseObject = JSON.parse(jqXHR.responseText);
                reject(responseObject);
            },
        });
    });
};


/**
 * koha.serial-row with koha.serialitems accessible via the itemnumber-attribute
 *
 * @param {Object} with koha.serial-rows columns as attributes
 */
Serials.Serial = class Serial {
    constructor(serial) {
        this.serialid       = serial.serialid;
        this.biblionumber   = serial.biblionumber;
        this.itemnumber     = serial.itemnumber;
        this.subscriptionid = serial.subscriptionid;
        this.serialseq      = serial.serialseq;
        this.serialseq_x    = serial.serialseq_x;
        this.serialseq_y    = serial.serialseq_y;
        this.serialseq_z    = serial.serialseq_z;
        this.status         = serial.status;
        this.planneddate    = serial.planneddate;
        this.notes          = serial.notes;
        this.publisheddate  = serial.publisheddate;
        this.publisheddatetext = serial.publisheddatetext;
        this.claimdate      = serial.claimdate;
        this.claims_count   = serial.claims_count;
        this.routingnotes   = serial.routingnotes;

        this._status = serial._status || Serials.Serial.Status.New;

        if (log.isTraceEnabled()) log.trace(`Serials.Serial.new():> '${Serials.stringifyError(this)}'`);
    }

    /**
     * Reload this object from the REST API
     *
     * @returns {Promise}
     */
    reload() {
        this._status = Serials.Serial.Status.Reloading;
        return new Promise((resolve, reject) => {
            Serials.serialGet(this.serialid)
            .then((serial) => {
                log.debug(`Serials.Serial.reload(${this.serialid}) :> Got serial `, serial);
                for (let key in serial) {
                    this[key] = serial[key];
                }
                this._status = Serials.Serial.Status.Complete;
                resolve(serial);
            })
            .catch((error) => {
                log.error(`Serials.Serial.reload(${this.serialid}) :> Reloading a serial failed: `, error);
                this._status = error;
                reject(error);
            });
        });
    }
};
Serials.Serial.cast = function (serial) {
    if (typeof serial === 'number') {
        return new Serials.Serial({serialid: serial, _status: Serials.Serial.Status.Slim});
    }
    else if (typeof serial === 'object') {
        return new Serials.Serial(serial);
    }
    else if (typeof serial === 'Serial') {
        return serial;
    }
    else {
        throw new TypeError(`Cannot cast '${serial}' to Serial.`);
    }
};
Serials.Serial.Status = {};
Serials.Serial.Status.Slim      = 'Slim';
Serials.Serial.Status.New       = 'New';
Serials.Serial.Status.Reloading = 'Reloading';
Serials.Serial.Status.Complete  = 'Complete';


/**
 * var serialEditor = new Serials.SerialEditor(params);
 * @param {Object} params, parameters as an object, valid attributes:
 *            {Object} 'translations' - translation keys and values
 */
Serials.SerialEditor = class SerialEditor {
    constructor(params) {
        this.checkRequirements();
        params = params || {};
        this.translations = params.translations || {};
        this.rootElement;

        log.trace(`Serials.SerialEditor.new():> `, Serials.stringifyError(this));
    }

    /**
     * Load the given serial for editing
     *
     * @param {Object} params, parameters as an object, valid attributes:
     *            {Serial or Integer} 'serial' - The Serial-object being edited. If only the serialid (int) is passed, fetches a matching serial-object via the REST API.
     */
    loadSerial(serialOrId, itemnumber) {
        log.debug("Serials.SerialEditor.loadSerial("+serialOrId+", "+itemnumber+") :> Loading serial");

        if (! this.rootElement) this.render();

        if (serialOrId) {
            this.serial = Serials.Serial.cast(serialOrId);

            new Promise((resolve, reject) => {
                if (this.serial._status === Serials.Serial.Status.Slim) {
                    this.serial.reload()
                    .then((serial) => resolve(serial))
                    .catch((error) => reject(error));
                }
                else {
                    resolve(this.serial);
                }
            })
            .then((serial) => {
                log.debug(`Serials.SerialEditor.loadSerial(${serial}) :> Got the complete serial`);
                this._syncFormValues('toForm');
                this.clearNotifications();
                this.show();
            })
            .catch((error) => {
                log.error(`Serials.SerialEditor.loadSerial(${serialOrId}) :> Reloading a serial failed: `, error);
                this.pushNotification("Failed to load the serial");
            });
        }
        else if (itemnumber) {
            this.pushNotification("<h4>Creating a new serial</h4>");
            log.debug(`Serials.SerialEditor.loadSerial(${serialOrId}, ${itemnumber}) :> Missing Serial, creating a new Serial.`);

            let item = Items.Item.cast(itemnumber);

            new Promise((resolve, reject) => {
                if (item._status === Items.Item.Status.Slim) {
                    item.reload()
                    .then((item) => resolve(item))
                    .catch((error) => reject(error));
                }
                else {
                    resolve(item);
                }
            })
            .then((item) => {
                log.debug(`Serials.SerialEditor.loadSerial(${serialOrId}, ${itemnumber}) :> Got the complete Item`);

                let serialseq_xyz;
                if (item.enumchron) serialseq_xyz = item.enumchron.match(/\d+/g).map(Number);
                this.serial = new Serials.Serial({
                    itemnumber:   item.itemnumber,
                    biblionumber: item.biblionumber,
                    serialseq:    item.enumchron,
                    serialseq_x:  serialseq_xyz ? serialseq_xyz[0] : '',
                    serialseq_y:  serialseq_xyz ? serialseq_xyz[1] : '',
                    serialseq_z:  serialseq_xyz ? serialseq_xyz[2] : '',
                    status:       2,
                    planneddate:  new Date().toISOString().substr(0,10),
                    publisheddate:new Date().toISOString().substr(0,10),
                });
                this._syncFormValues('toForm');
                this.clearNotifications();
                this.show();
            })
            .catch((error) => {
                log.error(`Serials.SerialEditor.loadSerial(${serialOrId}, ${itemnumber}) :> Reloading an Item failed: `, error);
                this.pushNotification("Failed to load the Item");
            });
        }
        else {
            throw new Error(`Serials.SerialEditor.loadSerial(${serialOrId}, ${itemnumber}) :> No serial or item given. Cannot load nothing.`);
        }
    }

    checkRequirements() {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor.checkRequirements(${this}) :>`);
        if(typeof jQuery === 'undefined') {
            throw new Error("jQuery https://jquery.com/ is not available");
        }
        if(! jQuery().datepicker) {
            throw new Error("jQuery DatePicker http://api.jqueryui.com/datepicker/ is not available");
        }
        if(! jQuery().dataTable) {
            throw new Error("jQuery DataTable https://datatables.net/ is not available");
        }
        if(typeof moment === 'undefined') {
            throw new Error("moment.js https://momentjs.com/ is not available");
        }
        if(typeof moment.tz === 'undefined') {
            throw new Error("moment-timezone.js https://momentjs.com/timezone/ is not available");
        }
        if(typeof filterXSS === 'undefined') {
            throw new Error("xss.js https://jsxss.com/en/index.html is not available");
        }
    }

    render() {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor.render(${this}) :>`);
        this.rootElement = this._template();
        this._bindEvents(this.rootElement);
        this.rootElement.appendTo('body').draggable();
    }

    _template() {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor._template(${this}) :>`);
        var html =
        `
        <fieldset id="SerialEditor" style="position: absolute; width: 400px; right: 75px;">
            <legend>${_('Serial editor')}</legend>
            <div id="sedit_notifications"/>
            <button id="sedit_close" style="position: absolute; top: -10px; right: 4px;"> X </button>

            <div>
                <input id="sedit_new_serialid" type="text" width="16" value=""/>
                <label for="sedit_new_serialid">${_('Serial id')}</label>
            </div>
            <div>
                <input id="sedit_new_biblionumber" type="text" width="16" value=""/>
                <label for="sedit_new_biblionumber">${_('Biblionumber')}</label>
            </div>
            <div>
                <input id="sedit_new_itemnumber" type="text" width="16" value=""/>
                <label for="sedit_new_itemnumber">${_('Itemnumber')}</label>
            </div>
            <div>
                <input id="sedit_new_subscriptionid" type="text" width="16" value=""/>
                <label for="sedit_new_subscriptionid">${_('Subscriptionid')}</label>
            </div>
            <div>
                <input id="sedit_new_serialseq" type="text" width="16" value=""/>
                <label for="sedit_new_serialseq">${_('Sequence')}</label>
            </div>
            <div>
                <input id="sedit_new_serialseq_x" type="text" width="16" value=""/>
                <label for="sedit_new_serialseq_x">${_('Seq x')}</label>
            </div>
            <div>
                <input id="sedit_new_serialseq_y" type="text" width="16" value=""/>
                <label for="sedit_new_serialseq_y">${_('Seq y')}</label>
            </div>
            <div>
                <input id="sedit_new_serialseq_z" type="text" width="16" value=""/>
                <label for="sedit_new_serialseq_z">${_('Seq z')}</label>
            </div>
            <div>
                <input id="sedit_new_status" type="text" width="16" value=""/>
                <label for="sedit_new_status">${_('Status')}</label>
            </div>
            <div>
                <input id="sedit_new_planneddate" type="text" width="16" value=""/>
                <label for="sedit_new_planneddate">${_('Planned date')}</label>
            </div>
            <div>
                <input id="sedit_new_notes" type="text" width="16" value=""/>
                <label for="sedit_new_notes">${_('Notes')}</label>
            </div>
            <div>
                <input id="sedit_new_publisheddate" type="text" width="16" value=""/>
                <label for="sfunctionedit_new_publisheddate">${_('Published date')}</label>
            </div>
            <div>
                <input id="sedit_new_publisheddatetext" type="text" width="16" value=""/>
                <label for="sedit_new_publisheddatetext">${_('Published date text')}</label>
            </div>
            <div>
                <input id="sedit_new_claimdate" type="text" width="16" value=""/>
                <label for="sedit_new_claimdate">${_('Claim date')}</label>
            </div>
            <div>
                <input id="sedit_new_claims_count" type="text" width="16" value=""/>
                <label for="sedit_new_claims_count">${_('Claims count')}</label>
            </div>
            <div>
                <input id="sedit_new_routingnotes" type="text" width="16" value=""/>
                <label for="sedit_new_routingnotes">${_('Routing notes')}</label>
            </div>

            <button id="sedit_save">${_('Save')}</button><button id="sedit_delete">${_('Delete')}</button>
        </fieldset>
        `;

        return $(html);
    }

    _bindEvents() {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor._bindEvents(${this}) :>`);
        this._getCloseButton().bind({
            "click": (event) => {
                this.rootElement.hide();
            }
        });
        this._getSaveButton().bind({
            "click": (event) => {
                this._syncFormValues();
                let promise;
                if (this.serial.serialid) promise = Serials.serialPut(this.serial);
                else                      promise = Serials.serialPost(this.serial);
                promise.then((serial) => {
                    this.pushNotification(_('Save succeeded'));
                })
                .catch((error) => {
                    this.pushNotification(_('Save failed'));
                });
            }
        });
        this._getDeleteButton().bind({
            "click": (event) => {
                if (!window.confirm(_("Are you sure you want to delete serial")+" '"+this.serial.serialid+"'?")) return;

                Serials.serialDelete(this.serial.serialid)
                .then((serial) => {
                    this.pushNotification(_('Delete succeeded'));
                })
                .catch((error) => {
                    this.pushNotification(_('Delete failed'));
                });
            }
        });
    }

    /**
     * Synchronizes all public Serial-object attributes.
     *
     * @param {Boolean} toForm Sync values from the loaded Serial to the GUI form inputs? If false, syncs from the GUI form to the loaded Serial.
     */
    _syncFormValues(toForm) {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor._syncFormValues(${toForm}) :>`);
        for (let key in this.serial) {
            if (key.substr(0,1) === '_') continue;

            let input = this.rootElement.find(`input#sedit_new_${key}`);
            if (! input) {
                log.error(`Couldn't find form input field for attribute '${key}'`);
            }
            else {
                if (toForm) {
                    input.val( (this.serial[key] ? filterXSS(this.serial[key]) : undefined) );
                    if (key === 'serialid' || key === 'biblionumber' || key === 'itemnumber') {
                        input.prop('disabled', true);
                    }
                }
                else{
                    this.serial[key] = input.val() ? filterXSS(input.val()) : undefined;
                }
            }
        }
    }

    /**
     * Using globalize.js would be more reasonable, but not doing anything more complicated than absolutely necessary due to Koha not having any modern user interface infrastructure to support dynamic anything.
     *
     * _() might look like a bad naming convention at first, but this is how GNU gettext is used on the serverside.
     * @param {String} msg to translate
     */
    _(msg) {
        if (this.translations[msg]) return this.translations[msg];
        return `UNTRANSLATEABLE"${msg}"`;
    }

    hide() {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor.hide(${this}) :>`);
        this.rootElement.hide();
    }
    show() {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor.show(${this}) :>`);
        this.rootElement.show();
    }
    clearNotifications() {
        this._getNotificationsField().html('');
    }
    pushNotification(msg, level) {
        if (log.isDebugEnabled()) log.debug(`Serials.SerialEditor.pushNotification(${msg}) :>`);
        this._getNotificationsField().prepend(`<div>${msg}</div>`);
    }

    //////////////////////////////
    //// PageObject accessors ////

    _getCloseButton() {
        return $(this.rootElement).find("#sedit_close");
    }
    _getDeleteButton() {
        return $(this.rootElement).find("#sedit_delete");
    }
    _getSaveButton() {
        return $(this.rootElement).find("#sedit_save");
    }
    _getNotificationsField() {
        return $(this.rootElement).find("#sedit_notifications");
    }
};

/**
 * There are many typesof errors and they stringify with varying levels of success and easiness.
 * This static function tries its best to serialize the given errors as something meaningful.
 */
Serials.stringifyError = function (error) {
    // Native errors can stringify themselves
    if (error instanceof Error) {
        return error;
    }
    // If this is a non-simple type, we can probably JSON:ify it.
    else if (typeof error === 'object') {
        return JSON.stringify(error);
    }
    // Simple types concatenate simply.
    else {
        return error;
    }
}