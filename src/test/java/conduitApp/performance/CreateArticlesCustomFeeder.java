package conduitApp.performance;

import helpers.ArticlesValuesFeeder;
import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.karatelabs.gatling.KarateDsl.*;

import java.time.Duration;
import java.util.Iterator;
import java.util.Map;

public class CreateArticlesCustomFeeder extends Simulation {

    Iterator<Map<String, Object>> articlesValuesWithFaker = new ArticlesValuesFeeder();

    ScenarioBuilder createArticlesFeederCustom = scenario("Create Articles - feeder custom")
            .feed(articlesValuesWithFaker)
            .exec(karateSet("title", s -> s.getString("title")))
            .exec(karateSet("description", s -> s.getString("description")))
            .exec(karateSet("body", s -> s.getString("body")))
            .exec(karateFeature("classpath:conduitApp/feature/CreateArticlesFromFaker.feature"));

    {
        setUp(
                createArticlesFeederCustom.injectOpen(rampUsers(4).during(Duration.ofSeconds(10)))
        ).protocols(KarateProtocol.protocol);
    }
}
