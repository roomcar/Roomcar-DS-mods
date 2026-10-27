"""Original procedural instrumental voice. No recorded/game/mod audio used."""
from pathlib import Path
import numpy as np
import wave,json,uuid,xml.etree.ElementTree as ET,argparse
import sys
from datetime import datetime
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from workbench_paths import workbench_root
parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path);parser.add_argument('--work-root',type=Path);parser.add_argument('--timbre',choices=['reed','flute','pluck'],default='pluck')
args=parser.parse_args();OUT=(args.output or workbench_root(args.work_root)/'drafts/ordinary/blue_boy/voice'/('generated-'+datetime.now().strftime('%Y%m%d-%H%M%S'))).resolve();SELECTED=args.timbre
WAV=OUT/'wav'; WAV.mkdir(parents=True,exist_ok=True)
SR=48000
rng=np.random.default_rng(271027)
def note(midi,duration,timbre='reed',bend=0,amp=1):
 t=np.arange(round(duration*SR))/SR
 f=440*2**((midi-69+bend*t/max(duration,.01)+.08*np.sin(2*np.pi*5.2*t))/12)
 phase=2*np.pi*np.cumsum(f)/SR
 if timbre=='reed': x=np.sin(phase)+.28*np.sin(3*phase)+.11*np.sin(5*phase)+.035*np.sin(7*phase)
 elif timbre=='flute':x=np.sin(phase)+.12*np.sin(2*phase)+.035*np.sin(3*phase)
 else:x=np.sin(phase)+.35*np.sin(2.002*phase)+.16*np.sin(3.01*phase)
 attack=.018 if timbre!='pluck' else .004
 env=np.minimum(t/attack,1)*np.minimum((duration-t)/.035,1)
 env=np.maximum(env,0)
 if timbre=='pluck':env*=np.exp(-t*7)
 else:env*=.75+.25*np.exp(-t*12)
 x=x*env*amp
 return x
def phrase(seq,timbre='reed'):
 parts=[]
 for midi,dur,gap,bend in seq:
  parts.extend([note(midi,dur,timbre,bend),np.zeros(round(gap*SR))])
 x=np.concatenate(parts);x-=x.mean();return x/(max(abs(x)) or 1)*.45
def save(path,x):
 with wave.open(str(path),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes((np.clip(x,-.99,.99)*32767).astype('<i2').tobytes())
 return {'file':path.name,'duration':round(len(x)/SR,3),'peak_dbfs':round(20*np.log10(max(abs(x))+1e-12),2),'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(x*x))+1e-12),2),'dc':float(x.mean()),'clipped_samples':int(np.count_nonzero(abs(x)>=1))}
talk=[(67,.12,.045,1),(70,.09,.03,-1),(65,.18,.07,0),(69,.11,.02,1),(67,.24,.10,-2)]
for timbre,name in [('reed','A-轻簧管'),('flute','B-柔笛'),('pluck','C-拨弦')]:
 save(OUT/(name+'.wav'),phrase(talk,timbre))
events={
 'talk_LP':[talk,[(69,.11,.035,0),(65,.16,.025,-1),(67,.09,.035,1),(72,.14,.07,-1),(67,.2,.1,-2)],[(65,.17,.04,1),(67,.10,.05,0),(70,.13,.03,-1),(64,.23,.12,-1)]],
 'hurt':[[(76,.10,.03,-3),(69,.16,.10,-4)],[(73,.09,.04,2),(67,.2,.08,-2)],[(78,.08,.02,-4),(70,.15,.08,-3)]],
 'death_voice':[[(72,.2,.05,-2),(67,.28,.04,-4),(59,.5,.10,-5)]],
 'yawn':[[(60,.38,.03,7),(67,.5,.06,-8)]],
 'sinking':[[(72,.11,.025,-3),(68,.11,.025,-4),(64,.16,.04,-5),(57,.36,.10,-7)]],
 'ghost_LP':[[(57,.6,.1,3),(60,.7,.12,-3)]],
 'emote':[[(67,.12,.04,1),(72,.14,.025,1),(74,.24,.1,-1)],[(65,.16,.05,-1),(62,.25,.08,-3)]],
 'pose':[[(67,.12,.025,0),(74,.23,.10,-1)]],
 'carol':[[(67,.21,.05,0),(69,.17,.04,0),(72,.26,.06,0),(69,.18,.05,0),(65,.24,.10,-1)]],
 'eye_rub_vo':[[(62,.23,.06,-2),(60,.18,.1,-1)]]}
manifest={};audio={};metrics=[]
for event,seqs in events.items():
 manifest[event]=[]
 for i,seq in enumerate(seqs,1):
  x=phrase(seq,SELECTED);fn=f'{event}_{i:02d}.wav'
  metrics.append(save(WAV/fn,x));manifest[event].append(fn);audio[fn]=x
demo=[];timeline=[];elapsed=0
for event in events:
 x=audio[manifest[event][0]];timeline.append({'event':event,'start':round(elapsed,2),'duration':round(len(x)/SR,2)})
 demo.extend([x,np.zeros(int(.5*SR))]);elapsed+=len(x)/SR+.5
save(OUT/({'reed':'A-轻簧管','flute':'B-柔笛','pluck':'C-拨弦'}[SELECTED]+'-全事件试听.wav'),np.concatenate(demo))
(OUT/'音频检查.json').write_text(json.dumps({'selected_timbre':SELECTED,'sample_rate':SR,'channels':1,'format':'PCM16','events':manifest,'metrics':metrics,'audition_timeline':timeline,'status':'synthetic audition; not in-game validated'},ensure_ascii=False,indent=2),encoding='utf-8')
# Author a minimal FMOD Designer project using documented/observed XML field names.
def add(parent,tag,value):e=ET.SubElement(parent,tag);e.text=str(value);return e
def guid(p):add(p,'guid','{'+str(uuid.uuid4())+'}')
p=ET.Element('project');add(p,'name','roomcar_blueprint_voice');guid(p);add(p,'version',4)
for k,v in {'eventgroup_nextid':1,'soundbank_nextid':1,'sounddef_nextid':len(events),'build_project':1,'build_continue_on_error':0,'currentbank':'roomcar_blueprint_voice','currentlanguage':'default','primarylanguage':'default','language':'default'}.items():add(p,k,v)
cat=ET.SubElement(p,'eventcategory');add(cat,'name','voice');guid(cat);add(cat,'volume_db',0)
folder=ET.SubElement(p,'sounddeffolder');add(folder,'name','master');guid(folder)
group=ET.SubElement(p,'eventgroup');add(group,'name','blueprint');guid(group)
bank=ET.SubElement(p,'soundbank');add(bank,'name','roomcar_blueprint_voice');guid(bank);add(bank,'_PC_banktype','DecompressedSample');add(bank,'_PC_format','PCM');add(bank,'_PC_quality',100)
for event,files in manifest.items():
 sd=ET.SubElement(folder,'sounddef');add(sd,'name',event);guid(sd);add(sd,'type','randomnorepeat');add(sd,'mode',0);add(sd,'volume_db',0)
 for fn in files:
  wf=ET.SubElement(sd,'waveform');add(wf,'filename','wav/'+fn);add(wf,'soundbankname','roomcar_blueprint_voice');add(wf,'weight',100)
  wf=ET.SubElement(bank,'waveform');add(wf,'filename','wav/'+fn);guid(wf);add(wf,'_PC_resamplemode',0);add(wf,'_PC_fixedsamplerate',SR)
 e=ET.SubElement(group,'event');add(e,'name',event);guid(e)
 for k,v in {'volume_db':0,'pitch':0,'pitch_randomization':0.025,'pitch_randomization_units':'Octaves','mode':'x_3d','mindistance':1,'maxdistance':25,'rolloff':'Logarithmic','oneshot':'No' if event in ['talk_LP','ghost_LP','carol'] else 'Yes','maxplaybacks':2,'maxplaybacks_behavior':'Steal_oldest','category':'voice','fadein_time':.01,'fadeout_time':.04}.items():add(e,k,v)
 layer=ET.SubElement(e,'layer');add(layer,'name','voice');s=ET.SubElement(layer,'sound')
 for k,v in {'name':event,'x':0,'width':1,'startmode':0,'loopmode':0 if event in ['talk_LP','ghost_LP','carol'] else 1,'loopcount2':-1,'volume':1}.items():add(s,k,v)
add(p,'_PC_audiosourcedirectory','.');add(p,'_PC_builddirectory','compiled')
ET.indent(p);ET.ElementTree(p).write(OUT/'roomcar_blueprint_voice.fdp',encoding='utf-8',xml_declaration=True)
print(f'Created {len(metrics)} WAV variants, {len(events)} events, three timbre samples.')
