package conduitApp.performance;

import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.karatelabs.gatling.KarateDsl.*;

public class FirstPerfTest extends Simulation {

    ScenarioBuilder signUpUsers = scenario("Sign up users")
            .exec(karateFeature("classpath:conduitApp/feature/SignUp.feature"));

    {
        setUp(
                signUpUsers.injectOpen(atOnceUsers(3))
        );
    }
}
