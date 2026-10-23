#!/usr/bin/env node
"use strict";
/** Dependency-free UI-flow smoke test. No actual browser or human claims.
 * It emulates only the DOM surface used by choice-lab.html and catches broken
 * choice locking, result exposure, feedback, review and JSON export wiring.
 */
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");
const assert=require("node:assert/strict");
const html=fs.readFileSync(path.join(__dirname,"choice-lab.html"),"utf8");
const fixtureMatch=html.match(/<script type="application\/json" id="studyFixture">([\s\S]*?)<\/script>/);
const jsMatch=html.match(/<script>\s*"use strict";([\s\S]*?)<\/script>/);
assert.ok(fixtureMatch&&jsMatch,"embedded offline fixture and program exist");
const fixture=JSON.parse(fixtureMatch[1]);
assert.equal(fixture.arms.length,3);
const keys=fixture.arms.map(a=>a.id);
assert.deepEqual(keys,["BASIC","CHAIN","ORDINARY"]);
let checked=0;
class Element {
  constructor(id){this.id=id;this.children=[];this.attributes={};this.value="";this.textContent="";
    this.disabled=false;this.checked=false;this.hidden=false}
  setAttribute(k,v){this.attributes[k]=String(v)}
  getAttribute(k){return this.attributes[k]}
  append(...v){this.children.push(...v)}
  appendChild(v){this.children.push(v);return v}
  replaceChildren(...v){this.children=[...v]}
  click(){this.wasClicked=true}
}
function trial(tester,option,expectCost,expectNet,expectMana,regression=null){
  const nodes=Object.create(null);
  const get=id=>nodes[id]||(nodes[id]=new Element(id));
  get("studyFixture").textContent=fixtureMatch[1];
  get("participant").value=tester;
  get("experience").value="new";
  get("confidence").value="3";
  get("understood").value="4";
  get("enjoyed").value="4";
  get("wantMore").value="yes";
  get("skillRecall").value="no";
  let exported="",now=1000,downloaded=0;
  class BlobMock{constructor(parts){this.content=parts.join("")}}
  const url={createObjectURL:obj=>{exported=obj.content;return "blob:test"},revokeObjectURL:()=>{}};
  const context={document:{hidden:false,getElementById:get,createElement:id=>new Element(id),
        createElementNS:(ns,id)=>new Element(id),addEventListener:()=>{}},
    window:{scrollTo:()=>{}},performance:{now:()=>now},Blob:BlobMock,URL:url,
    setTimeout:()=>{},confirm:()=>true,console};
  vm.runInNewContext('"use strict";'+jsMatch[1],context,{timeout:2000});
  assert.equal(get("welcome").hidden,false);
  get("consent").checked=true;get("consent").onchange();
  assert.equal(get("start").disabled,false);
  get("start").onclick();now+=1300;
  assert.equal(get("outcome").hidden,true,"No outcome before choice");
  assert.equal(get("planCards").children.length,3);
  assert.ok(get("choiceBoard").children.length>100,"board and pieces rendered");
  const labels=get("planCards").children.map(x=>x.children[1].textContent);
  const index=labels.findIndex(x=>x.includes(option==="CHAIN"?"連鎖換位":option==="BASIC"?"盜賊換位":"落兵") &&
     (option!=="ORDINARY"|| !x.includes("換位")));
  assert.ok(index>=0,"candidate option visible");
  get("planCards").children[index].onclick();
  if(regression==="preview"){
    // Reviewed CHAIN action contract: F3, then D3→C3; still only two AP.
    const rings=get("choiceBoard").children.filter(e=>e.id==="circle"&&e.attributes["stroke-width"]==="3");
    assert.deepEqual(rings.map(e=>[Number(e.attributes.cx),Number(e.attributes.cy)]),
      [[226.5,117],[153.5,117],[117,117]],"CHAIN preview must include F3, D3 and C3");
    const labels=get("choiceBoard").children.filter(e=>e.id==="text"&&e.attributes["font-size"]==="10");
    assert.deepEqual(labels.map(e=>e.textContent),["1","2a","2b"],"two-step action labels must not imply three AP");
  }
  assert.equal(get("confirmChoice").disabled,false);
  get("confirmChoice").onclick();
  assert.equal(get("outcome").hidden,true,"no results leaked before rationale");
  get("reason").value="我要以現在的行動換取位置的好處";
  get("expect").value="對手可能補兵";
  get("showOutcome").onclick();
  assert.equal(get("resultCost").textContent,expectCost);
  assert.equal(get("resultNet").textContent,expectNet);
  assert.equal(get("resultMana").textContent,expectMana);
  assert.equal(get("outcome").hidden,false);
  assert.equal(get("compareChoices").children.length,3);
  get("compareChoices").children.find(b=>!b.disabled).onclick();
  get("finishChoice").onclick();
  assert.equal(get("survey").hidden,false);
  get("export").onclick();downloaded++;
  const data=JSON.parse(exported);
  assert.equal(data.schema,"TG12_P1H_EXPORT_V1");
  assert.equal(data.offline,true);
  assert.equal(data.observation.participant,tester);
  assert.equal(data.observation.firstChoice,option);
  assert.equal(data.observation.otherPlansViewedCount,1);
  assert.ok(data.observation.events.some(x=>x.kind==="download_requested"));
  assert.ok(data.observation.firstChoiceSeconds>0);
  assert.ok(!Object.keys(data.observation).some(x=>/email|lastName|firstName|address/i.test(x)));
  assert.equal(downloaded,1);
  if(regression==="reset"){
    get("experience").value="experienced";
    get("tradeoff").value="synthetic first participant only";
    get("reset").onclick();
    assert.equal(get("welcome").hidden,false);
    assert.equal(get("start").disabled,true);
    assert.equal(get("consent").checked,false);
    for(const id of ["understood","enjoyed","wantMore","skillRecall","confidence"])
      assert.equal(get(id).value,"unknown",`${id} must not carry over to next participant`);
    for(const id of ["reason","expect","tradeoff"])assert.equal(get(id).value,"");
    assert.equal(get("experience").value,"new");
    assert.match(get("exportStatus").textContent,/只存在此分頁記憶體/);
    get("participant").value="T06";
    get("consent").checked=true;get("consent").onchange();get("start").onclick();
    get("planCards").children[0].onclick();get("confirmChoice").onclick();
    get("showOutcome").onclick();get("finishChoice").onclick();get("export").onclick();
    const second=JSON.parse(exported).observation;
    assert.equal(second.participant,"T06");
    assert.equal(second.rationale,"");assert.equal(second.anticipatedReply,"");
    assert.equal(second.confidence,"unknown");assert.equal(second.otherPlansViewedCount,0);
    assert.deepEqual(second.survey,{understood:"unknown",enjoyed:"unknown",wantMore:"unknown",energyRecall:"unknown",tradeoff:""});
  }
  checked++;
  return {tester,selected:option,firstChoiceLabel:data.observation.firstChoiceLabel,order:data.observation.order};
}
if(process.argv[2]==="--reset-regression"){
  trial("T01","CHAIN",4,"+2",3,"reset");
  console.log("PASS synthetic same-tab reset and second-participant export isolation");
}else if(process.argv[2]==="--preview-regression"){
  trial("T01","CHAIN",4,"+2",3,"preview");
  console.log("PASS CHAIN preview includes F3, D3, C3 with two-action labels");
}else{
const first=trial("T01","CHAIN",4,"+2",3);
const second=trial("T02","BASIC",2,"+0",5);
const third=trial("T03","ORDINARY",0,"+0",6);
assert.deepEqual(first.order,["BASIC","CHAIN","ORDINARY"]);
assert.deepEqual(second.order,["CHAIN","ORDINARY","BASIC"]);
assert.deepEqual(third.order,["ORDINARY","BASIC","CHAIN"]);
console.log("PASS 3 simulated offline flows: no early reveal, legal cards, choice lock, resource feedback, exploration, anonymous export");
trial("T01","CHAIN",4,"+2",3,"reset");
trial("T01","CHAIN",4,"+2",3,"preview");
console.log("PASS 2 regressions: same-tab participant reset/export isolation; complete two-step chain preview");
}
console.log("NO HUMAN TESTS performed; results are synthetic DOM smoke checks.");
