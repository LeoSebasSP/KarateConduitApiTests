package conduitApp.performance;

import io.gatling.javaapi.core.FeederBuilder;
import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.karatelabs.gatling.KarateDsl.*;

import java.time.Duration;

public class CreateArticlesFeederFromFile extends Simulation {

    FeederBuilder<String> articlesValues = csv("data/articles.csv").circular();

    ScenarioBuilder createArticlesFromFie = scenario("Login and then create Articles with Feeder from File CVS")
            .feed(articlesValues)
            .exec(karateSet("title", s -> s.getString("Title")))
            .exec(karateSet("description", s -> s.getString("Description")))
            .exec(karateSet("body", s -> s.getString("Body")))
            .exec(karateFeature("classpath:conduitApp/feature/CreateArticlesFromFile.feature"));

    {
        setUp(
                createArticlesFromFie.injectOpen(rampUsers(4).during(Duration.ofSeconds(10)))
        ).protocols(KarateProtocol.protocol);
    }
}
