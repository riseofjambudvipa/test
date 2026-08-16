/*! coi-serviceworker v0.1.7 | MIT License | https://github.com/gzguidoti/coi-serviceworker */
if (typeof window === 'undefined') {
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", event => event.waitUntil(self.clients.claim()));

    self.addEventListener("fetch", event => {
        if (event.request.cache === "only-if-cached" && event.request.mode !== "same-origin") {
            return;
        }

        event.respondWith(
            fetch(event.request)
                .then(response => {
                    if (response.status === 0) {
                        return response;
                    }

                    const newHeaders = new Headers(response.headers);
                    newHeaders.set("Cross-Origin-Embedder-Policy", "require-corp");
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

                    return new Response(response.body, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders
                    });
                })
                .catch(e => {
                    console.error("coi-serviceworker fetch failed:", e);
                })
        );
    });
} else {
    (() => {
        const script = document.currentScript;
        const coi = {
            shouldRegister: () => true,
            shouldDeregister: () => false,
            doNotCoop: () => false,
            quiet: false,
            ...script ? script.dataset : {}
        };

        if (coi.shouldDeregister()) {
            navigator.serviceWorker.getRegistrations().then(registrations => {
                for (let registration of registrations) {
                    registration.unregister();
                }
            });
        }

        if (coi.doNotCoop() || !window.crossOriginIsolated && coi.shouldRegister()) {
            window.addEventListener("load", () => {
                navigator.serviceWorker.register(new URL("coi-serviceworker.js", document.baseURI).href)
                    .then(registration => {
                        if (!coi.quiet) console.log("COOP/COEP Service Worker registered", registration.scope);
                        registration.addEventListener("updatefound", () => {
                            if (!coi.quiet) console.log("Reloading page to apply COOP/COEP");
                            window.location.reload();
                        });
                        if (registration.active) {
                            if (!coi.quiet) console.log("COOP/COEP Service Worker is active");
                        }
                    })
                    .catch(err => {
                        console.error("COOP/COEP Service Worker registration failed:", err);
                    });
            });
        }
    })();
}
