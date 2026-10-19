import Foundation

enum ScrollDamping {
    static let script = #"""
    (function () {
      if (window.__afgScrollDamping) { return; }
      window.__afgScrollDamping = true;

      window.addEventListener('wheel', function (event) {
        if (event.ctrlKey || event.metaKey || event.shiftKey) { return; }
        if (Math.abs(event.deltaY) < 40) { return; }

        var node = event.target;
        while (node && node !== document.body && node !== document.documentElement) {
          var style = window.getComputedStyle(node);
          if (/(auto|scroll)/.test(style.overflowY) && node.scrollHeight > node.clientHeight) {
            return;
          }
          node = node.parentElement;
        }

        event.preventDefault();
        window.scrollBy(0, event.deltaY * 0.5);
      }, { passive: false });
    })();
    """#
}
