{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();

    // Register the service worker manually to handle updates
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', function () {
        navigator.serviceWorker.register('flutter_service_worker.js?v=' + {{flutter_service_worker_version}}).then((reg) => {
          reg.onupdatefound = () => {
            const installingWorker = reg.installing;
            installingWorker.onstatechange = () => {
              if (installingWorker.state === 'installed') {
                if (navigator.serviceWorker.controller) {
                  // New update available, force it to activate
                  console.log('New update available. Activating in background...');
                  installingWorker.postMessage({ type: 'SKIP_WAITING' });
                }
              }
            };
          };
        });
      });

      // Reload the page when the new service worker takes over,
      // but only if you want it to refresh immediately.
      // Since the user asked for update on NEXT start, we don't automatically reload here.
      // The SKIP_WAITING ensures the new SW activates, and serves new assets on next page load.
    }

    await appRunner.runApp();
  }
});
