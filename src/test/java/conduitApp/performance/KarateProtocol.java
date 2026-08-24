package conduitApp.performance;

import io.karatelabs.gatling.KarateProtocolBuilder;
import io.karatelabs.http.HttpRequest;

import java.util.Map;

import static io.karatelabs.gatling.KarateDsl.*;

public class KarateProtocol {

    public static final KarateProtocolBuilder protocol = karateProtocol(
            uri("/api/articles/{slug}").nil(),
            uri("/api/articles/{slug}/favorite")
                    .pauseFor(method("POST", 500))
                    .build(),
            uri("/api/articles/{slug}/comments")
                    .pauseFor(method("GET", 200), method("POST", 500))
                    .build(),
            uri("/api/articles/{slug}/comments/{commentId}").nil()
    )
            // NAME RESOLVER
            .nameResolver((HttpRequest request, Map<String, Object> vars) -> {
                String path = request.getPath();
                String method = request.getMethod();
                if (path != null && path.matches("/api/articles/[^/]+/comments.*")) {
                    if (method.equals("POST")) {
                        return "Create Comment";
                    }
                    if (method.equals("GET")) {
                        return "Get Comment";
                    }
                    if (method.equals("DELETE")) {
                        return "Delete Comment";
                    }
                }
                return null;
            });
}
