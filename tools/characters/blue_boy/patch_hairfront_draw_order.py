"""Correct hairfront/face draw order in a COPY of ANIM v4 data.
Never changes 2D transforms, image indices, symbols, layers, timing or visibility.
Use at custom-character animation compilation, not as a global vanilla override.
"""
import struct,hashlib,json,argparse
from pathlib import Path
from zipfile import ZipFile

def parse(data):
 p=4
 def take(fmt):
  nonlocal p
  v=struct.unpack_from('<'+fmt,data,p);p+=struct.calcsize('<'+fmt)
  return v[0] if len(v)==1 else v
 def string():
  nonlocal p
  n=take('I');s=data[p:p+n].decode();p+=n;return s
 assert data[:4]==b'ANIM'
 version,refs,nframes,events,count=take('IIIII');assert version==4
 frames=[]
 for _ in range(count):
  name=string();facing,bank,rate,n=take('BIfI')
  for fi in range(n):
   take('ffff');ev=take('I');p+=ev*4;els=[]
   for j in range(take('I')):
    off=p;v=take('IIIfffffff');els.append({'offset':off,'symbol':v[0],'index':v[1],'layer':v[2],'matrix':v[3:],'slot':j})
   frames.append({'animation':name,'facing':facing,'frame':fi,'elements':els})
 names={}
 for _ in range(take('I')):
  h=take('I');names[h]=string()
 assert p==len(data)
 return frames,names

def patch(data):
 frames,names=parse(data);out=bytearray(data);changes=[]
 for fr in frames:
  hs=[e for e in fr['elements'] if names.get(e['symbol'],'').lower()=='hairfront' and e['index'] in [0,1]]
  fs=[e for e in fr['elements'] if names.get(e['symbol'],'').lower()=='face']
  if len(hs)!=1 or len(fs)!=1:continue
  h,f=hs[0],fs[0]
  # ANIM v4 elements are stored foreground first. Swap only if face comes first.
  if h['slot']<=f['slot']:continue
  ho,fo=h['offset'],f['offset'];hb=data[ho:ho+40];fb=data[fo:fo+40]
  out[fo:fo+40]=hb[:36]+fb[36:40];out[ho:ho+40]=fb[:36]+hb[36:40]
  changes.append({k:fr[k] for k in ['animation','facing','frame']}|{'hair_slot':h['slot'],'face_slot':f['slot'],'hair_offset':ho,'face_offset':fo})
 # Exact invariants: each symbol record except depth is byte-identical per frame.
 after,_=parse(out)
 for before,afterfr in zip(frames,after):
  assert sorted(data[e['offset']:e['offset']+36] for e in before['elements'])==sorted(bytes(out[e['offset']:e['offset']+36]) for e in afterfr['elements'])
 return bytes(out),changes

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('input',type=Path);ap.add_argument('output',type=Path);args=ap.parse_args()
 assert args.input.resolve()!=args.output.resolve(),'Source must not be overwritten'
 data=args.input.read_bytes();result,changes=patch(data);args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(result)
 assert patch(result)[0]==result
 args.output.with_suffix('.changes.json').write_text(json.dumps({'source_sha256':hashlib.sha256(data).hexdigest(),'result_sha256':hashlib.sha256(result).hexdigest(),'changes':changes},indent=2),encoding='utf8')
 print(len(changes),'frames reordered; all 2D matrices preserved')
if __name__=='__main__':main()
