package com.mrdew.dewlingobe.system;

import com.mrdew.dewlingo.api.HealthApi;
import com.mrdew.dewlingo.model.HealthStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController implements HealthApi {

    @Override
    public ResponseEntity<HealthStatus> getHealth() {
        return ResponseEntity.ok(new HealthStatus(HealthStatus.StatusEnum.UP));
    }
}
