<create>
    <div class="container">
        <h4>Shipyard: Building New Shipment</h4>

        <div class="row">
            <div class="col s6">
                <loading_elm if={ loading } isloading="{ loading }"></loading_elm>
                <dl if="{errors}" each={ key,step in errors }>
                    <dt><h5>Errors with step: { key } </h5></dt>
                    <dd if="{step.length}" each="{error in step}">
                        <p if="{!error.body.map}">{error.body}</p>
                        <p if="{error.body.map}" each="{err in error.body}">
                            <strong>{err.field}</strong>
                            {err.requirement}
                        </p>
                    </dd>
                </dl>
                <div class="shipment" if={shipment_result}>
                    <h5>Created New Shipment {shipment_result.main.name}</h5>
                    <pre>
                        { JSON.stringify(shipment, null, 2); }
                    </pre>
                </div>
            </div>

            <div class="col s6 status right">
                <p each={ messages }><strong>{ date }</strong> { msg }</p>
            </div>
        </div>

    </div>

    <script>
    var self = this,
        d = utils.debug,
        timer;

    self.state;
    self.messages = [];
    self.loading = false;

    function reset() {
        self.errors = null;
        self.update();
    }

    function getNow() {
        return (new Date()).toLocaleString();
    }

    function addMessage(msg) {
        self.messages.push({date: getNow(), msg: msg});
        self.update();
    }

    self.on('mount', function () {
        d('shipyard/create::mount');
    });

    /**
     * main method
     *
     * this is fired once the state is of the app is retrieved and the build page is loaded.
     */
    RiotControl.on('retrieve_state_result', function (state) {

        if (state.page === 'create') {
            d('shipyard/create::retrieve_state_result', state.shipment);

            var msg = 'Building a Shipment';
            self.shipment = state.shipment;
            self.shipment.shipit = true;
            self.loading = true;

            addMessage(msg);

            // Build Shipment
            RiotControl.trigger('build_create_shipment', self.shipment);
        }
    });

    /**
     *
     * Step 4. Container shipment build.
     */
    RiotControl.on('build_create_shipment_result', function (status, data) {
        d('shipyard/create::build_create_shipment_result', status, data);

        var msg;

        if (status === 200 && !data.errors) {
            msg = 'Created shipment %name %environment, will now attempt to trigger the Shipment.';
        } else {
            msg = 'Failed to create shipment %name %environment. Status %status. Aborting.';
        }

        addMessage(msg.replace('%name', self.shipment.main.name).replace('%environment', self.shipment.environment.name).replace('%status', status));

        if (status === 200 && !data.errors) {
            self.shipment_result = data.shipment;
            self.shipment.providers.forEach(function(provider) {
                RiotControl.trigger('build_shipment_trigger', self.shipment.main.name, self.shipment.environment.name, provider.name);
            });
        } else {
            self.errors = data.errors;
        }

        self.loading = false;
        self.update();
    });

    /**
     *
     * Step 5. container shipment build.
     */
    RiotControl.on('build_shipment_trigger_result', function (result, err) {
        d('shipyard/create::build_shipment_trigger_result', result, err);

        var msg,
            url;

        if (err) {
            msg = 'Failed to trigger Shipment %name %env due to %err.'.replace('%err', err);
        } else {
            url = result.message.join(',');
            msg = 'Created Shipment %name %env with endpoint %url.'.replace('%url', url);
        }

        addMessage(msg.replace('%name', self.shipment.main.name).replace('%env', self.shipment.environment.name));

        if (!err) {
            RiotControl.trigger('build_endpoint_wait_start');
        }
    });

    /**
     * Step 6. container shipment build.
     */
    RiotControl.on('build_endpoint_wait_start', function () {
        d('shipyard/create::build_endpoint_wait_start');

        var check = 0;

        addMessage('Waiting on AWS Route53 DNS propagation for your new Shipment, this will take five minutes. Please do not refresh this page, but feel free to navigate away.');

        timer = setInterval(function () {
            // Every 10 secs going to post a little message, after 30 checks, should be good to move along
            check++;
            d('shipyard/create::build_endpoint_wait_start::interval-tick(%d of 30)', check);

            if (check > 30) {
                RiotControl.trigger('build_done');
            } else {
                addMessage('Waiting... ' + (check * 10) + ' secs of 300 secs have transpired.');
            }
        }, 1000 * 10);
    });

    /**
     * Step 7. container shipment build.
     */
    RiotControl.on('build_done', function () {
        d('shipyard/create::build_done');

        clearInterval(timer);

        RiotControl.trigger('clear_state');

        addMessage('Shipment is ready, navigating to Command Bridge in 10 secs.');

        setTimeout(function () {
            d('shipyard/trigger::build_done::setTimeout(riot.route)');

            riot.route('bridge/%name/%env'.replace('%name', self.shipment.main.name).replace('%env', self.shipment.environment.name));
        }, 1000 * 10);
    });

    RiotControl.on('app_changed', function () {
        clearInterval(timer);
        reset();
    });

    </script>

    <style scoped>
    .status {
        background-color: #DCDCDD;
        border: 1px solid #ADBCA5;
        border-radius: 4px;
        padding: 5px 10px;
    }
    .status strong {
        font-weight: normal;
        color: #858275;
    }
    .status p {
        color: #46494C;
        font-family: "Lucida Console", Monaco, monospace;
        font-size: 11px;
        margin: 0;
    }

    </style>
</create>
