package conduitApp.performance;

import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.atOnceUsers;
import static io.gatling.javaapi.core.CoreDsl.scenario;
import static io.karatelabs.gatling.KarateDsl.karateFeature;

public class ArticlePerfTest extends Simulation {

    ScenarioBuilder createAndDeleteArticles = scenario("Create And Delete Articles")
            .exec(karateFeature("classpath:conduitApp/feature/Articles.feature"));

    {
        setUp(
                createAndDeleteArticles.injectOpen(atOnceUsers(3))
        ).protocols(KarateProtocol.protocol);
    }
}
