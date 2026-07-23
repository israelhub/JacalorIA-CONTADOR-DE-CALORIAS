{{flutter_js}}
{{flutter_build_config}}

// Auto-update: after each deploy, the next open (or a tab already open)
// picks up version.json and reloads onto the fresh build.
(function () {
  const VERSION_URL = 'version.json';
  const STORAGE_KEY = 'jacaloria_web_version';
  const POLL_MS = 60 * 1000;

  async function fetchDeployVersion() {
    const res = await fetch(VERSION_URL + '?t=' + Date.now(), {
      cache: 'no-store',
      headers: { 'Cache-Control': 'no-cache' },
    });
    if (!res.ok) {
      throw new Error('version.json HTTP ' + res.status);
    }
    const data = await res.json();
    return String(data.version || data.build_number || '');
  }

  function readStoredVersion() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (_) {
      return null;
    }
  }

  function writeStoredVersion(version) {
    try {
      localStorage.setItem(STORAGE_KEY, version);
    } catch (_) {}
  }

  async function clearWebCaches() {
    if (!('caches' in window)) {
      return;
    }
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map(function (key) {
        return caches.delete(key);
      }));
    } catch (_) {}
  }

  async function applyUpdateAndReload(latest) {
    writeStoredVersion(latest);
    await clearWebCaches();
    window.location.reload();
  }

  /**
   * @param {{reloadIfChanged: boolean}} options
   * @returns {Promise<boolean>} true if a reload was triggered
   */
  async function checkForUpdate(options) {
    const reloadIfChanged = options && options.reloadIfChanged;
    try {
      const latest = await fetchDeployVersion();
      if (!latest) {
        return false;
      }
      const current = readStoredVersion();
      if (!current) {
        writeStoredVersion(latest);
        return false;
      }
      if (current !== latest && reloadIfChanged) {
        await applyUpdateAndReload(latest);
        return true;
      }
    } catch (err) {
      // Local `flutter run` may not serve a deploy version.json — ignore.
      console.warn('[JacalorIA] version check skipped:', err);
    }
    return false;
  }

  function startUpdateWatcher() {
    setInterval(function () {
      checkForUpdate({ reloadIfChanged: true });
    }, POLL_MS);

    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') {
        checkForUpdate({ reloadIfChanged: true });
      }
    });

    window.addEventListener('focus', function () {
      checkForUpdate({ reloadIfChanged: true });
    });

    if ('serviceWorker' in navigator) {
      var refreshing = false;
      navigator.serviceWorker.addEventListener('controllerchange', function () {
        if (refreshing) {
          return;
        }
        refreshing = true;
        window.location.reload();
      });

      setInterval(function () {
        navigator.serviceWorker.getRegistrations().then(function (regs) {
          regs.forEach(function (reg) {
            reg.update();
          });
        });
      }, POLL_MS);
    }
  }

  window.addEventListener('load', function () {
    checkForUpdate({ reloadIfChanged: true }).then(function (reloading) {
      if (reloading) {
        return;
      }
      _flutter.loader.load();
      startUpdateWatcher();
    });
  });
})();
