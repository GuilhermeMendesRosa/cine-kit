
if (!window._flixBypassContentLoaded) {
    window._flixBypassContentLoaded = true;

    const HOUSEHOLD_MODAL_TEXTS = ['household', 'update your netflix household'];

    function removeIfHousehold(element) {
        const text = (element.textContent || '').toLowerCase();
        if (HOUSEHOLD_MODAL_TEXTS.some(kw => text.includes(kw))) {
            console.log('[FlixBypass] Removing household modal');
            element.remove();
            // Remove the background overlay for this specific modal
            const bg = document.querySelector('.nf-modal-background[data-uia="nf-modal-background"]');
            if (bg) bg.remove();
        }
    }

    const observer = new MutationObserver((mutationsList) => {
        // On /watch: do nothing
        if (window.location.pathname.startsWith('/watch')) return;

        for (const mutation of mutationsList) {
            if (mutation.type !== 'childList') continue;
            for (const node of mutation.addedNodes) {
                if (node.nodeType !== Node.ELEMENT_NODE) continue;

                // Only check elements that are the household modal
                if (node.matches && node.matches('.nf-modal.interstitial-full-screen')) {
                    removeIfHousehold(node);
                }
                // Check children too
                if (node.querySelectorAll) {
                    node.querySelectorAll('.nf-modal.interstitial-full-screen').forEach(removeIfHousehold);
                }
            }
        }
    });

    if (document.body) {
        observer.observe(document.body, { childList: true, subtree: true });
    } else {
        // If body isn't ready yet, wait for it
        document.addEventListener('DOMContentLoaded', () => {
            observer.observe(document.body, { childList: true, subtree: true });
        });
    }
}