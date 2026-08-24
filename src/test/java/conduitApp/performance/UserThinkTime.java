package conduitApp.performance;

import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.karatelabs.gatling.KarateDsl.*;

import java.time.Duration;

public class UserThinkTime extends Simulation {

    ScenarioBuilder SignUpThenHomePage = scenario("Sign up and, after thinking it over, take a look at the home page.")
            .exec(karateFeature("classpath:conduitApp/feature/SignUp.feature"))
            .pause(Duration.ofSeconds(1), Duration.ofSeconds(3))
            .exec(karateFeature("classpath:conduitApp/feature/HomePage.feature"));

    {
        setUp(
                SignUpThenHomePage.injectOpen(atOnceUsers(3))
        ).protocols(KarateProtocol.protocol);
    }
}
