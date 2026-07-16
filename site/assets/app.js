(() => {
  const input = document.getElementById('doc-search');
  const panel = document.getElementById('search-results');
  if (!input || !panel) return;
  const root = document.body.dataset.siteRoot || '';
  const index = Array.isArray(window.LABKIT_SEARCH_INDEX) ? window.LABKIT_SEARCH_INDEX : [];
  const escape = value => { const node = document.createElement('span'); node.textContent = String(value); return node.innerHTML; };
  const hide = () => { panel.hidden = true; panel.innerHTML = ''; };
  input.addEventListener('input', () => {
    const terms = input.value.toLowerCase().trim().split(/\s+/).filter(Boolean);
    if (!terms.length) { hide(); return; }
    const matches = index.filter(item => terms.every(term => (item.title + ' ' + item.text).toLowerCase().includes(term))).slice(0, 12);
    panel.innerHTML = matches.length ? matches.map(item => `<a href='${root + item.url}'><strong>${escape(item.title)}</strong><small>${escape(item.kind)}</small></a>`).join('') : '<span class=nav-link>No matching documentation.</span>';
    panel.hidden = false;
  });
  input.addEventListener('keydown', event => { if (event.key === 'Escape') { input.value = ''; hide(); } });
  document.addEventListener('click', event => { if (!panel.contains(event.target) && event.target !== input) hide(); });
})();