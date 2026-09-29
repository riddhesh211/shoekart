/* ================================================
   ShoeKart - Client-side JavaScript
   ================================================ */

document.addEventListener('DOMContentLoaded', function () {

    // Auto-dismiss flash messages after 4 seconds
    document.querySelectorAll('.alert').forEach(function (alert) {
        setTimeout(function () {
            const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
            bsAlert.close();
        }, 4000);
    });

    // Live search suggestions (used on the navbar search box, if present)
    const searchInput = document.querySelector('input[name="q"]');
    if (searchInput) {
        let debounceTimer;
        searchInput.addEventListener('input', function () {
            clearTimeout(debounceTimer);
            const value = this.value.trim();
            if (value.length < 2) return;
            debounceTimer = setTimeout(function () {
                fetch('/api/search-suggestions?q=' + encodeURIComponent(value))
                    .then(function (res) { return res.json(); })
                    .catch(function () { /* fail silently */ });
            }, 300);
        });
    }

    // Confirm before destructive admin actions (backup, in case inline onclick is stripped)
    document.querySelectorAll('[data-confirm]').forEach(function (el) {
        el.addEventListener('click', function (e) {
            if (!confirm(el.getAttribute('data-confirm'))) {
                e.preventDefault();
            }
        });
    });

});
