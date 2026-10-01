document.addEventListener('DOMContentLoaded',()=>{
  const source=document.getElementById('model-data');
  if(!source)return;
  const models=JSON.parse(source.textContent);
  const company=document.getElementById('company-filter'), search=document.getElementById('model-search');
  const input=document.getElementById('input-tokens'),output=document.getElementById('output-tokens');
  const body=document.getElementById('model-rows');
  [...new Set(models.map(m=>m.company))].sort().forEach(c=>{const o=document.createElement('option');o.value=c;o.textContent=c;company.append(o)});
  function render(){
    const n=Number(input.value),k=Number(output.value);
    if(input.value===''||output.value===''||!Number.isInteger(n)||!Number.isInteger(k)||n<0||k<0||n>10000000||k>1000000){body.replaceChildren();document.getElementById('model-count').textContent='Enter whole token counts within the displayed limits (input ≤ 10,000,000; output ≤ 1,000,000).';return;}
    const matches=models.filter(m=>(!company.value||m.company===company.value)&&m.model_id.toLowerCase().includes(search.value.toLowerCase()))
      .map(m=>({...m,cost:(m.input_price*n+m.output_price*k)/1e6})).sort((a,b)=>a.cost-b.cost||a.model_id.localeCompare(b.model_id));
    body.replaceChildren();
    matches.forEach(m=>{const tr=document.createElement('tr');const vals=[m.model_id,m.company,Number(m.context_tokens).toLocaleString(),m.input_price.toFixed(3),m.output_price.toFixed(3),'$'+m.cost.toFixed(5)+(m.has_price_overrides?' *':'')];for(const value of vals){const td=document.createElement('td');td.textContent=value;tr.append(td)}body.append(tr)});
    document.getElementById('model-count').textContent=matches.length+' model versions shown · lowest base cost first';
  }
  [company,search,input,output].forEach(el=>el.addEventListener('input',render));render();
});
