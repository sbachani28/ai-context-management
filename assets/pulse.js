(() => {
  const form = document.getElementById('pulse');
  if (!form) return;
  form.addEventListener('input', () => {
    const status = document.getElementById('pulse-status');
    if (status.dataset.state === 'error') { status.textContent = ''; delete status.dataset.state; }
  });
  form.addEventListener('submit', e => {
    e.preventDefault();
    if (!form.reportValidity()) return;
    const row = Object.fromEntries(new FormData(form));
    const status = document.getElementById('pulse-status');
    if ((row.recent_use === 'No' && row.reentered !== 'Not applicable') ||
        (row.recent_use === 'Yes' && row.reentered === 'Not applicable') ||
        (row.recent_use === 'No' && row.minutes !== '')) {
      status.dataset.state = 'error';
      status.textContent = 'Check questions 3–5. If you did not use AI, choose “I did not use AI” and leave the time blank.';
      return;
    }
    row.schema_version = 'context-pulse-v2';
    row.minutes = row.minutes === '' ? null : Number(row.minutes);
    row.consent = true;
    const url = URL.createObjectURL(new Blob([JSON.stringify(row,null,2)], {type:'application/json'}));
    const a = document.createElement('a'); a.href=url; a.download='ai-context-response.json'; a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    status.dataset.state = 'success';
    status.textContent = 'We saved your answers to your device. We did not send them to the research team.';
  });
})();
