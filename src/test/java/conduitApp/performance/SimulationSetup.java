package conduitApp.performance;

import io.gatling.javaapi.core.FeederBuilder;
import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.karatelabs.gatling.KarateDsl.*;

import java.time.Duration;

public class SimulationSetup extends Simulation {

    FeederBuilder<String> credentials = csv("data/simulationsetup-users.csv").circular();

    ScenarioBuilder LoginThenHomePage = scenario("Login and navigate to HomePage")
            .feed(credentials)
            .exec(karateSet("email", s -> s.getString("email")))
            .exec(karateSet("password", s -> s.getString("password")))
            .exec(karateFeature("classpath:helpers/TokenLogin.feature"))
            .pause(Duration.ofSeconds(1), Duration.ofSeconds(3))
            .exec(karateFeature("classpath:conduitApp/feature/HomePage.feature"));

    {
        setUp(
                LoginThenHomePage.injectOpen(
                        rampUsers(3).during(Duration.ofSeconds(5)),
                        nothingFor(Duration.ofSeconds(2)),
                        rampUsers(2).during(Duration.ofSeconds(5))
                )
        ).protocols(KarateProtocol.protocol)
         .assertions(
                 global().successfulRequests().percent().gt(95.0)
         );
    }
}
