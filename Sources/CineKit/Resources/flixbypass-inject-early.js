
(function () {
    if (window._flixBypassPatched) return;
    window._flixBypassPatched = true;

    var HOUSEHOLD_MARKERS = [
        'household',
        'in-home',
        'inhome',
        'setlocationcontext',
        'householdstatus',
        'updatememberstate',
        'memberstatus'
    ];

    var HOUSEHOLD_OPERATIONS = [
        'clcsinterstitiallolomo'
    ];

    function containsHouseholdData(text) {
        if (!text) return false;
        var lower = text.toLowerCase();
        for (var i = 0; i < HOUSEHOLD_MARKERS.length; i++) {
            if (lower.indexOf(HOUSEHOLD_MARKERS[i]) !== -1) return true;
        }
        return false;
    }

    function isHouseholdOperation(text) {
        if (!text) return false;
        var lower = text.toLowerCase();
        for (var i = 0; i < HOUSEHOLD_OPERATIONS.length; i++) {
            if (lower.indexOf(HOUSEHOLD_OPERATIONS[i]) !== -1) return true;
        }
        return false;
    }

    function isNetflixGraphQL(url) {
        // Match both full URLs (https://www.netflix.com/graphql)
        // and relative URLs (/graphql) since Netflix uses relative paths
        var path = url.split('?')[0].split('#')[0];
        if (path === '/graphql' || path === 'graphql') return true;
        if (url.indexOf('netflix.com/graphql') !== -1) return true;
        return false;
    }

    var EMPTY_RESPONSE = '{"data":{}}';

    function emptyJsonResponse() {
        return new Response(EMPTY_RESPONSE, {
            status: 200,
            statusText: 'OK',
            headers: { 'Content-Type': 'application/json' }
        });
    }

    // --- Patch fetch ---
    var _origFetch = window.fetch;
    window.fetch = function (input, init) {
        var url = '';
        if (typeof input === 'string') url = input;
        else if (input && input.url) url = input.url;
        else if (input && input.href) url = input.href;

        if (isNetflixGraphQL(url)) {
            var reqBody = (init && init.body) ? init.body : '';
            if (typeof reqBody === 'string') {
                if (isHouseholdOperation(reqBody) || containsHouseholdData(reqBody)) {
                    console.log('[FlixBypass] Blocked household request');
                    return Promise.resolve(emptyJsonResponse());
                }
            }

            return _origFetch.apply(this, arguments).then(function (response) {
                var clone = response.clone();
                return clone.text().then(function (body) {
                    if (containsHouseholdData(body)) {
                        console.log('[FlixBypass] Stripped household data from response');
                        return emptyJsonResponse();
                    }
                    return response;
                }).catch(function () {
                    return response;
                });
            });
        }
        return _origFetch.apply(this, arguments);
    };

    // --- Patch XMLHttpRequest ---
    var _origOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url) {
        this._flixUrl = typeof url === 'string' ? url : '';
        return _origOpen.apply(this, arguments);
    };

    var _origSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.send = function (body) {
        if (this._flixUrl && isNetflixGraphQL(this._flixUrl)) {
            var bodyStr = typeof body === 'string' ? body : '';

            if (isHouseholdOperation(bodyStr) || containsHouseholdData(bodyStr)) {
                console.log('[FlixBypass] Blocked household XHR request');
                return;
            }

            var self = this;
            var interceptor = function () {
                try {
                    var respText = self.responseText || '';
                    if (containsHouseholdData(respText)) {
                        console.log('[FlixBypass] Stripped household data from XHR');
                        Object.defineProperty(self, 'responseText', {
                            value: EMPTY_RESPONSE, writable: true, configurable: true
                        });
                        Object.defineProperty(self, 'response', {
                            value: EMPTY_RESPONSE, writable: true, configurable: true
                        });
                    }
                } catch (e) { }
            };

            this.addEventListener('load', interceptor, { once: true, capture: true });
        }
        return _origSend.apply(this, arguments);
    };

    console.log('[FlixBypass] Response interception active (document.' + document.readyState + ')');
})();
