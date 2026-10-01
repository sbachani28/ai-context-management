document.addEventListener('DOMContentLoaded',()=>{
  const source=document.getElementById('retrieval-data');
  if(source){
    const rows=JSON.parse(source.textContent),dataset=document.getElementById('retrieval-dataset'),budget=document.getElementById('retrieval-budget'),target=document.getElementById('retrieval-summary');
    function update(){
      const selected=rows.filter(r=>r.dataset===dataset.value&&r.k===Number(budget.value));
      const table=document.createElement('table');table.className='interactive-table';
      const head=table.createTHead().insertRow();['Method','Evidence recall','All sources found','Mean share of words kept','Questions'].forEach(s=>{const c=document.createElement('th');c.textContent=s;head.append(c)});
      const body=table.createTBody();
      selected.forEach(r=>{const tr=body.insertRow();[r.strategy,...[r.recall,r.all_hit,r.retained_fraction].map(x=>(x*100).toFixed(1)+'%'),r.questions.toLocaleString()].forEach(x=>tr.insertCell().textContent=x)});
      target.replaceChildren(table);
    }
    [dataset,budget].forEach(el=>el.addEventListener('change',update));update();
  }
  const target=document.getElementById('econ-result');
  if(target){
    const ids=['tasks','minutes','wage','fixed','variable'],inputs=ids.map(id=>document.getElementById('econ-'+id));
    const usd=x=>x.toLocaleString('en-US',{style:'currency',currency:'USD',maximumFractionDigits:2});
    function update(){
      if(inputs.some(el=>el.value===''||!el.checkValidity())){target.textContent='Use numbers within the limits shown.';return;}
      const [n,m,w,f,v]=inputs.map(el=>Number(el.value)),gross=n*m*w/60,cost=f+n*v,net=gross-cost;
      const breakeven=w>0?(60*cost/(n*w)).toFixed(2)+' minutes per task':'we cannot compute this when time has zero value';
      const strong=document.createElement('strong');strong.textContent=usd(net)+' / month';
      const p=document.createElement('p');p.textContent='Example: '+usd(gross)+' in time saved minus '+usd(cost)+' in costs. Time needed to break even: '+breakeven+'. The value of time may not turn into cash savings. This assumes the quality of work stays the same.';
      target.replaceChildren(strong,p);
    }
    inputs.forEach(el=>el.addEventListener('input',update));update();
  }
});
