import Foundation

struct OfficialScript: Identifiable {
    let id: String
    let name: String
    let source: String
}

enum OfficialScripts {
    static let all: [OfficialScript] = [genericAds, youtubeAds]

    static func isEnabled(_ script: OfficialScript) -> Bool {
        !disabledIDs.contains(script.id)
    }

    static func setEnabled(_ enabled: Bool, for script: OfficialScript) {
        var ids = disabledIDs
        if enabled {
            ids.remove(script.id)
        } else {
            ids.insert(script.id)
        }
        UserDefaults.standard.set(Array(ids), forKey: disabledKey)
    }

    static var enabledScripts: [OfficialScript] {
        all.filter(isEnabled)
    }

    private static let disabledKey = "afg.officialScripts.disabled"

    private static var disabledIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: disabledKey) ?? [])
    }

    private static let genericAds = OfficialScript(id: "generic-ads", name: "Ad blocking (generic)", source: #"""
    (function () {
      if (window.__afgGenericAds) { return; }
      window.__afgGenericAds = true;

      var selectors = [
        '#banner-ad',
        '.adsbygoogle',
        '.ad-container',
        '.ad-slot',
        '.ad-banner',
        'iframe[src*="doubleclick.net"]',
        'iframe[src*="googlesyndication.com"]',
        'iframe[src*="googleadservices.com"]'
      ];
      var css = selectors.join(',') + '{display:none !important;}';

      function inject() {
        var root = document.head || document.documentElement;
        if (!root || document.getElementById('afg-generic-ads')) { return; }
        var style = document.createElement('style');
        style.id = 'afg-generic-ads';
        style.textContent = css;
        root.appendChild(style);
      }

      inject();
      document.addEventListener('DOMContentLoaded', inject);
      new MutationObserver(inject).observe(document.documentElement, { childList: true, subtree: true });
    })();
    """#)

    private static let youtubeAds = OfficialScript(id: "youtube-ads", name: "YouTube ad blocking", source: #"""
    (function () {
      if (window.__afgYouTubeAds) { return; }
      window.__afgYouTubeAds = true;
      if (location.hostname.indexOf('youtube.com') === -1) { return; }

      var selectors = [
        '#masthead-ad',
        '#player-ads',
        'ytd-ad-slot-renderer',
        'ytd-display-ad-renderer',
        'ytd-promoted-sparkles-web-renderer',
        'ytd-in-feed-ad-layout-renderer',
        'ytd-video-masthead-ad-v3-renderer',
        'ytd-engagement-panel-section-list-renderer[target-id*="ads"]',
        '.ytp-ad-overlay-slot',
        '.ytp-ad-overlay-container',
        '.ytp-ad-progress-list',
        '.ytp-ad-module',
        '.ytp-ad-player-overlay',
        '.ytp-ad-player-overlay-layout'
      ];
      var css = selectors.join(',') + '{display:none !important;}';

      function inject() {
        var root = document.head || document.documentElement;
        if (!root || document.getElementById('afg-youtube-ads')) { return; }
        var style = document.createElement('style');
        style.id = 'afg-youtube-ads';
        style.textContent = css;
        root.appendChild(style);
      }

      function hideFeedAds() {
        var items = document.querySelectorAll('ytd-rich-item-renderer, ytd-compact-promoted-video-renderer');
        for (var i = 0; i < items.length; i++) {
          var item = items[i];
          if (item.querySelector('ytd-ad-slot-renderer, ytd-display-ad-renderer, ytd-in-feed-ad-layout-renderer')) {
            item.style.display = 'none';
          }
        }
      }

      function skipButtons() {
        return document.querySelectorAll(
          '.ytp-ad-skip-button, .ytp-ad-skip-button-modern, .ytp-skip-ad-button, .ytp-ad-skip-button-container button, .ytp-ad-skip-button-slot button'
        );
      }

      var forced = false;
      var savedRate = 1;
      var savedMuted = false;
      var forcedAt = 0;

      function restore(video) {
        forced = false;
        video.playbackRate = savedRate || 1;
        video.muted = savedMuted;
      }

      function handlePlayer() {
        var player = document.getElementById('movie_player');
        var video = document.querySelector('video');
        if (!player || !video) { return; }

        var buttons = skipButtons();
        for (var i = 0; i < buttons.length; i++) { buttons[i].click(); }

        var showing = player.classList.contains('ad-showing');

        if (showing) {
          if (!forced) {
            forced = true;
            forcedAt = Date.now();
            savedRate = video.playbackRate || 1;
            savedMuted = video.muted;
          }
          video.muted = true;
          video.playbackRate = 16;
        } else if (forced && (!showing || Date.now() - forcedAt > 180000)) {
          restore(video);
        }
      }

      inject();
      document.addEventListener('DOMContentLoaded', inject);
      new MutationObserver(inject).observe(document.documentElement, { childList: true, subtree: true });
      window.setInterval(function () {
        handlePlayer();
        hideFeedAds();
      }, 500);
    })();
    """#)
}
