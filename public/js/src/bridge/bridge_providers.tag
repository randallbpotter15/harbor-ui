<bridge_providers>
    <div class="row valign-wrapper">
          <p class="col s4 valign">
              <strong>Replicas:</strong>
          </p>
          <p class="col s4 valign"></p>
          <p class="col s4 valign center-align">
              <input
                  class="replicas provider-{ service.provider }"
                  value="{ service.replicas }"
                  type="number"
                  min="0"
                  onchange="{ updateReplicas }"
              />
          </p>

    </div>
    <div class="row valign-wrapper">
        <p class="col s4 valign">
            <strong>Barge:</strong>
        </p>
        <p class="col s4 valign">{service.barge}</p>
        <p class="col s4">
            <select_barge provider="{service}" callback="{updateBarge}" info="{false}"></select_barge>
        </p>
    </div>

    <script>
    var self = this,
        d = utils.debug,
        mu = utils.makeUrl;

    updateReplicas(evt) {
        var val = Number($('.provider-' + self.service.provider).val()),
            shipment = self.opts.shipment.parentShipment.name,
            environment = self.opts.shipment.name,
            service = self.service,
            url = mu(shipment, 'environment', environment, 'provider', service.provider);

        if (typeof val === 'number' && val != self.service.replicas) {
            self.service.replicas = val;
            self.service.providerObj.replicas = val;
            RiotControl.trigger('shipit_update_value', url, {replicas: val}, 'PUT');
        }

        self.update();
    }

    updateBarge() {
        var shipment = self.opts.shipment.parentShipment.name,
            environment = self.opts.shipment.name,
            service = self.service,
            url = mu(shipment, 'environment', environment, 'provider', service.provider);

        // hack to update provider value
        self.opts.shipment.providers[0].barge = service.barge;
        // save the provider barge value
        RiotControl.trigger('shipit_update_value', url, {barge: service.barge}, 'PUT');
        RiotControl.trigger('get_shipment_status', self.opts.shipment);
    }

    </script>
</bridge_providers>
