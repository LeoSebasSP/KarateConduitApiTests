package conduitApp;

import io.karatelabs.core.Runner;
import io.karatelabs.core.SuiteResult;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class ConduitTest {

    @Test
    void testParallel() {
        SuiteResult result = Runner.path("classpath:conduitApp")
                //.tags("~@ignore")
                .parallel(1);
        assertEquals(0, result.getScenarioFailedCount(), String.join("\n", result.getErrors()));
    }

}
