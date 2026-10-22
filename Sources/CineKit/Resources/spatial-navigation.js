(() => {
  const CANDIDATES = 'a[href], button, input, select, textarea, [role=button], [role=link], [tabindex]';
  const FOCUS_ATTRIBUTE = 'data-cinekit-focus';
  const TEXT_INPUT_TYPES = ['text', 'search', 'email', 'url', 'tel', 'password', 'number'];
  const DIRECTIONS = {
    ArrowUp: { x: 0, y: -1 },
    ArrowDown: { x: 0, y: 1 },
    ArrowLeft: { x: -1, y: 0 },
    ArrowRight: { x: 1, y: 0 },
  };

  const style = document.createElement('style');
  style.textContent = `[${FOCUS_ATTRIBUTE}] {
    outline: 4px solid white !important;
    outline-offset: 4px !important;
    box-shadow: 0 0 0 8px rgba(0, 0, 0, .6) !important;
  }`;
  // At document start <head> does not exist yet.
  document.documentElement.appendChild(style);

  const isCandidate = (el) => {
    if (!el || !el.matches || !el.matches(CANDIDATES) || el.tabIndex < 0 || el.disabled) return false;
    const rect = el.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0 && getComputedStyle(el).visibility !== 'hidden';
  };

  const isTextField = (el) =>
    el.isContentEditable ||
    el.tagName === 'TEXTAREA' ||
    (el.tagName === 'INPUT' && TEXT_INPUT_TYPES.includes(el.type));

  const visibleArea = (rect) =>
    Math.max(0, Math.min(rect.right, innerWidth) - Math.max(rect.left, 0)) *
    Math.max(0, Math.min(rect.bottom, innerHeight) - Math.max(rect.top, 0));

  // While a video is in the foreground the keys belong to the player.
  const isVideoInForeground = () =>
    document.fullscreenElement ||
    [...document.querySelectorAll('video')].some(
      (video) => !video.paused && visibleArea(video.getBoundingClientRect()) >= 0.5 * innerWidth * innerHeight
    );

  const center = (el) => {
    const rect = el.getBoundingClientRect();
    return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 };
  };

  const candidates = () => [...document.querySelectorAll(CANDIDATES)].filter(isCandidate);

  // Off-axis distance weighs double so the closest item in the same row/column wins.
  const nextInDirection = (from, direction) => {
    const origin = center(from);
    let best = null;
    let bestScore = Infinity;
    for (const el of candidates()) {
      if (el === from) continue;
      const point = center(el);
      const dx = point.x - origin.x;
      const dy = point.y - origin.y;
      const axis = dx * direction.x + dy * direction.y;
      if (axis <= 0) continue;
      const score = axis + 2 * Math.abs(direction.x ? dy : dx);
      if (score < bestScore) {
        best = el;
        bestScore = score;
      }
    }
    return best;
  };

  const firstVisible = () => {
    let best = null;
    let bestScore = Infinity;
    for (const el of candidates()) {
      const rect = el.getBoundingClientRect();
      if (visibleArea(rect) === 0) continue;
      if (rect.top + rect.left < bestScore) {
        best = el;
        bestScore = rect.top + rect.left;
      }
    }
    return best;
  };

  const focus = (el) => {
    document.querySelector(`[${FOCUS_ATTRIBUTE}]`)?.removeAttribute(FOCUS_ATTRIBUTE);
    el.setAttribute(FOCUS_ATTRIBUTE, '');
    el.focus({ preventScroll: true });
    el.scrollIntoView({ block: 'center', inline: 'center', behavior: 'smooth' });
  };

  const scroll = (direction) =>
    window.scrollBy({
      left: direction.x * 0.4 * innerWidth,
      top: direction.y * 0.4 * innerHeight,
      behavior: 'smooth',
    });

  const handle = (event) => {
    if (event.metaKey || event.altKey || event.ctrlKey || event.shiftKey) return false;
    const direction = DIRECTIONS[event.key];
    if (!direction && event.key !== 'Enter') return false;
    if (isVideoInForeground()) return false;

    const active = document.activeElement;
    if (active && isTextField(active) && (event.key === 'Enter' || direction.x)) return false;

    if (event.key === 'Enter') {
      const marked = document.querySelector(`[${FOCUS_ATTRIBUTE}]`);
      if (!marked) return false;
      marked.click();
      return true;
    }

    const next = isCandidate(active) ? nextInDirection(active, direction) : firstVisible();
    if (next) {
      focus(next);
    } else {
      scroll(direction);
    }
    return true;
  };

  window.addEventListener(
    'keydown',
    (event) => {
      if (!handle(event)) return;
      event.preventDefault();
      event.stopPropagation();
    },
    true
  );
})();
