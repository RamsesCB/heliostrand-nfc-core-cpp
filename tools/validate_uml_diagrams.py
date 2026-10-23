#!/usr/bin/env python3
from __future__ import annotations
import argparse
import base64
import html
import itertools
import json
import math
import re
import sys
import zlib
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
from urllib.parse import unquote

EPS = 0.2
EXPECTED_EDGES = (15, 20, 10, 11, 18, 22)
IGNORED = {'title_banner', 'm_title_banner', 'jd_uc_title', 'ma_uc_title', 'jd_proc_title', 'ma_proc_title', 'jd_sys_boundary', 'ma_sys_boundary'}

def style_map(value):
    return dict(item.split('=', 1) for item in value.split(';') if '=' in item)

def plain(value):
    for _ in range(2):
        value = html.unescape(value)
    value = re.sub(r'<(?:br|hr)\b[^>]*>', '\n', value, flags=re.I)
    return re.sub(r'</?(?:b|i|div|span|p|font|strong|em|u)\b[^>]*>', '', value, flags=re.I).strip()

def distance(a, b):
    return math.hypot(b[0]-a[0], b[1]-a[1])

def same(a, b):
    return distance(a, b) < EPS

def segments(points):
    return [(a, b) for a, b in zip(points, points[1:]) if not same(a, b)]

def intersection(a, b, c, d):
    rx, ry = b[0]-a[0], b[1]-a[1]
    sx, sy = d[0]-c[0], d[1]-c[1]
    denominator = rx*sy-ry*sx
    qx, qy = c[0]-a[0], c[1]-a[1]
    if abs(denominator) < 1e-8:
        if abs(qx*ry-qy*rx) > 1e-6:
            return None
        length = rx*rx+ry*ry
        if length < 1e-8:
            return None
        t, u = (qx*rx+qy*ry)/length, ((d[0]-a[0])*rx+(d[1]-a[1])*ry)/length
        low, high = max(0, min(t,u)), min(1,max(t,u))
        if high < low-1e-8:
            return None
        p = (a[0]+rx*(low+high)/2, a[1]+ry*(low+high)/2)
        overlap = max(0, high-low)*math.sqrt(length)
        return ('overlap' if overlap > EPS else 'touch', p, overlap)
    t, u = (qx*sy-qy*sx)/denominator, (qx*ry-qy*rx)/denominator
    if -1e-8 <= t <= 1+1e-8 and -1e-8 <= u <= 1+1e-8:
        p = (a[0]+t*rx, a[1]+t*ry)
        interior = EPS < t*distance(a,b) < distance(a,b)-EPS and EPS < u*distance(c,d) < distance(c,d)-EPS
        return ('crossing' if interior else 'touch', p, 0)
    return None

def segment_intersects(a, b, rect, inset=1):
    x, y, w, h = rect
    x += inset; y += inset; w -= 2*inset; h -= 2*inset
    if min(w,h) <= 0:
        return False
    dx, dy = b[0]-a[0], b[1]-a[1]
    low, high = 0., 1.
    for p,q in ((-dx,a[0]-x),(dx,x+w-a[0]),(-dy,a[1]-y),(dy,y+h-a[1])):
        if abs(p)<1e-8:
            if q<0:return False
        elif p<0:low=max(low,q/p)
        else:high=min(high,q/p)
        if low>high:return False
    return True

def boxes_overlap(a,b,padding=0):
    return min(a[0]+a[2],b[0]+b[2])-max(a[0],b[0])>padding and min(a[1]+a[3],b[1]+b[3])-max(a[1],b[1])>padding

def boundary_distance(p,box):
    x,y,w,h=box
    if x-EPS<=p[0]<=x+w+EPS and y-EPS<=p[1]<=y+h+EPS:
        return min(abs(p[0]-x),abs(p[0]-x-w),abs(p[1]-y),abs(p[1]-y-h))
    return min(distance(p,(max(x,min(x+w,p[0])),y)),distance(p,(max(x,min(x+w,p[0])),y+h)),distance(p,(x,max(y,min(y+h,p[1])))),distance(p,(x+w,max(y,min(y+h,p[1])))))

def midpoint(points, fraction=.5):
    segs=segments(points); total=sum(distance(a,b) for a,b in segs); target=total*fraction
    for a,b in segs:
        length=distance(a,b)
        if target<=length:return (a[0]+(b[0]-a[0])*target/length,a[1]+(b[1]-a[1])*target/length),(a,b)
        target-=length
    return points[-1],segs[-1] if segs else (points[-1],points[-1])

def rectangles(diagram, include_containers=False):
    cells={c.get('id'):c for c in diagram.findall('.//mxCell')}; cache={}
    def locate(cell):
        cid=cell.get('id')
        if cid in cache:return cache[cid]
        g=cell.find('mxGeometry')
        if g is None:raise ValueError('missing geometry: '+str(cid))
        box=[float(g.get(k,0)) for k in ('x','y','width','height')]
        parent=cells.get(cell.get('parent'))
        if parent is not None and parent.get('vertex')=='1':
            pos=locate(parent);box[0]+=pos[0];box[1]+=pos[1]
        cache[cid]=tuple(box);return cache[cid]
    return {cid:locate(c) for cid,c in cells.items() if c.get('vertex')=='1' and (include_containers or (cid not in IGNORED and not cid.startswith('lane_'))) and cells.get(c.get('parent'),ET.Element('x')).get('edge')!='1'}

def endpoints(edge,nodes):
    st=style_map(edge.get('style',''));src=nodes[edge.get('source')];dst=nodes[edge.get('target')]
    start=(src[0]+float(st['exitX'])*src[2],src[1]+float(st['exitY'])*src[3])
    end=(dst[0]+float(st['entryX'])*dst[2],dst[1]+float(st['entryY'])*dst[3])
    return [start,*[(float(p.get('x')),float(p.get('y'))) for p in edge.findall("./mxGeometry/Array[@as='points']/mxPoint")],end]

def load_drawio(path):
    root=ET.parse(path).getroot(); result=[]
    for diagram in root.findall('.//diagram'):
        if diagram.find('mxGraphModel') is None and diagram.text and diagram.text.strip():
            diagram.append(ET.fromstring(unquote(zlib.decompress(base64.b64decode(diagram.text),-15).decode())))
        nodes=rectangles(diagram);all_boxes=rectangles(diagram, True);edges=[];issues=[]
        for edge in diagram.findall('.//mxCell[@edge="1"]'):
            eid=edge.get('id');st=style_map(edge.get('style',''))
            try:
                points=endpoints(edge,nodes)
                parent=all_boxes.get(edge.get('parent'))
                if parent:
                    points=[points[0],*[(x+parent[0],y+parent[1]) for x,y in points[1:-1]],points[-1]]
            except (KeyError,ValueError) as err:
                issues.append({'kind':'invalid_anchor','elements':[eid],'point':None,'detail':str(err),'severity':'error'});continue
            label=plain(edge.get('value',''));label_box=None;geo=edge.find('mxGeometry')
            if label:
                center,pair=midpoint(points,(float(geo.get('x',0))+1)/2)
                offset=geo.find("mxPoint[@as='offset']")
                ox=float(offset.get('x',0)) if offset is not None else 0
                oy=float(offset.get('y',0)) if offset is not None else 0
                a,b=pair;length=distance(a,b) or 1;normal=float(geo.get('y',0))
                center=(center[0]+ox+(b[1]-a[1])*normal/length,center[1]+oy-(b[0]-a[0])*normal/length)
                font=float(st.get('fontSize',12));lines=label.splitlines() or ['']
                width=max(map(len,lines))*font*.65+8;height=len(lines)*font*1.3+6
                label_box=(center[0]-width/2,center[1]-height/2,width,height)
            edges.append({'id':eid,'source':edge.get('source'),'target':edge.get('target'),'points':points,'label':label,'label_box':label_box,'style':st})
        result.append({'name':diagram.get('name'),'nodes':nodes,'edges':edges,'issues':issues,'format':'drawio','shapes':{c.get('id'):c.get('style','') for c in diagram.findall('.//mxCell[@vertex="1"]')},'labels':'estimated text bounds; editor inspection required'})
    return result

def load_astah(path):
    diagrams={}
    for line in Path(path).read_text().splitlines():
        f=line.split('\t')
        if f[0]=='DIAGRAM':diagrams[f[1]]={'name':f[2],'nodes':{},'edges':[],'issues':[],'format':'astah','labels':'unavailable from TSV; editor inspection required'}
        elif f[0]=='N' and f[3] not in ('Frame','Swimlane'):
            diagrams[f[1]]['nodes'][f[2]]=tuple(map(float,f[5:9]))
        elif f[0]=='E':
            diagrams[f[1]]['edges'].append({'id':f[2],'source':f[5],'target':f[6],'points':[tuple(map(float,p.split(','))) for p in f[7:]],'label':f[4],'label_box':None,'style':{},'type':f[3]})
    for d in diagrams.values():
        for e in d['edges']:
            source=d['nodes'].get(e['source']);target=d['nodes'].get(e['target'])
            if source and target:
                center=lambda box:(box[0]+box[2]/2,box[1]+box[3]/2)
                p,q=e['points'][0],e['points'][-1]
                if distance(p,center(source))+distance(q,center(target))>distance(q,center(source))+distance(p,center(target)):
                    e['points'].reverse();e['reversed_points']=True
            e['points']=clip_astah_endpoints(e['points'],source,target)
    return list(diagrams.values())

def clip_astah_endpoints(points,source,target):
    def clip(pts,box):
        if box is None or len(pts)<2:return pts
        x,y,w,h=box
        inside=lambda p:x-EPS<=p[0]<=x+w+EPS and y-EPS<=p[1]<=y+h+EPS
        if not inside(pts[0]):return pts
        for i,(a,b) in enumerate(zip(pts,pts[1:])):
            if inside(b):continue
            hits=[]
            corners=[(x,y),(x+w,y),(x+w,y+h),(x,y+h),(x,y)]
            for c,d in zip(corners,corners[1:]):
                hit=intersection(a,b,c,d)
                if hit:hits.append(hit[1])
            if hits:return [min(hits,key=lambda p:distance(a,p)),*pts[i+1:]]
        return pts
    return list(reversed(clip(list(reversed(clip(points,source))),target)))

def audit(diagram):
    nodes,edges=diagram['nodes'],diagram['edges'];issues=list(diagram.get('issues',[]));seen=set()
    def add(kind,ids,p,detail='',severity='error'):
        key=(kind,tuple(sorted(ids)),tuple(round(v,1) for v in p) if p else None)
        if key not in seen:
            seen.add(key);issues.append({'kind':kind,'elements':ids,'point':list(p) if p else None,'detail':detail,'severity':severity})
    for a,b in itertools.combinations(nodes,2):
        if boxes_overlap(nodes[a],nodes[b],1):add('node_overlap',[a,b],(max(nodes[a][0],nodes[b][0]),max(nodes[a][1],nodes[b][1])))
    for edge in edges:
        eid=edge['id'];points=edge['points']
        for field,p in [('source',points[0]),('target',points[-1])]:
            box=nodes.get(edge[field])
            if box is None:add('missing_endpoint',[eid,edge[field]],p)
            else:
                shape=diagram.get('shapes',{}).get(edge[field],'')
                x,y,w,h=box;nx=abs((p[0]-x-w/2)/(w/2));ny=abs((p[1]-y-h/2)/(h/2))
                delta=abs(nx*nx+ny*ny-1) if 'ellipse' in shape else abs(nx+ny-1) if 'rhombus' in shape else None
                if (delta is not None and delta>.04) or (delta is None and boundary_distance(p,box)>2):add('anchor_off_boundary',[eid,edge[field]],p)
        for a,b in segments(points):
            if abs(a[0]-b[0])>EPS and abs(a[1]-b[1])>EPS:add('diagonal',[eid],midpoint([a,b])[0])
            for nid,rect in nodes.items():
                if nid not in (edge['source'],edge['target']) and segment_intersects(a,b,rect):add('line_node',[eid,nid],midpoint([a,b])[0])
        for p in (points[0],points[-1]):
            symbol=(p[0]-6,p[1]-6,12,12)
            for nid,rect in nodes.items():
                if nid not in (edge['source'],edge['target']) and boxes_overlap(symbol,rect):add('symbol_node',[eid,nid],p)
        label=edge.get('label_box')
        if label:
            for nid,rect in nodes.items():
                if boxes_overlap(label,rect):add('label_node',[eid,nid],(label[0],label[1]))
    for e,f in itertools.combinations(edges,2):
        for a,b in segments(e['points']):
            for c,d in segments(f['points']):
                hit=intersection(a,b,c,d)
                if not hit:continue
                kind,p,length=hit
                shared=any(e[x]==f[y] and same(p,e['points'][0 if x=='source' else -1]) and same(p,f['points'][0 if y=='source' else -1]) for x in ('source','target') for y in ('source','target'))
                if kind=='overlap':add('line_overlap',[e['id'],f['id']],p,f'{length:.2f} px')
                elif not shared:
                    end=any(same(p,q) for q in (e['points'][0],e['points'][-1],f['points'][0],f['points'][-1]))
                    add('endpoint_on_line' if end else 'line_crossing',[e['id'],f['id']],p)
        for owner,other in ((e,f),(f,e)):
            box=owner.get('label_box')
            if box and any(segment_intersects(a,b,box,0) for a,b in segments(other['points'])):add('label_line',[owner['id'],other['id']],(box[0],box[1]))
        if e.get('label_box') and f.get('label_box') and boxes_overlap(e['label_box'],f['label_box']):add('label_label',[e['id'],f['id']],(e['label_box'][0],e['label_box'][1]))
    return {'diagram':diagram['name'],'format':diagram['format'],'nodes':len(nodes),'relations':len(edges),'label_validation':diagram['labels'],'counts':dict(Counter(i['kind'] for i in issues)),'issues':issues}

def check(path,report_path=None,expected=None):
    diagrams=load_astah(path) if Path(path).suffix=='.tsv' else load_drawio(path)
    if not diagrams or any(not d['nodes'] or not d['edges'] for d in diagrams):
        raise ValueError('empty or missing diagram content')
    if Path(path).name == 'Heliostrand_Diagramas_Completos.drawio':
        expected = 6 if expected is None else expected
        if tuple(len(d['edges']) + len(d['issues']) for d in diagrams) != EXPECTED_EDGES:
            raise ValueError('master relation counts differ from expected 15/20/10/11/18/22')
    for d in diagrams:
        if len({e['id'] for e in d['edges']}) != len(d['edges']):
            raise ValueError('duplicate relation IDs')
        for box in d['nodes'].values():
            if not all(math.isfinite(v) for v in box) or box[2] <= 0 or box[3] <= 0:
                raise ValueError('invalid node geometry')
        for e in d['edges']:
            if len(e['points']) < 2 or not all(math.isfinite(v) for p in e['points'] for v in p):
                raise ValueError('invalid connector geometry')
    reports=[audit(d) for d in diagrams]
    if expected is not None and len(diagrams)!=expected:raise ValueError(f'expected {expected} diagrams; got {len(diagrams)}')
    result={'file':str(path),'diagrams':reports,'relations':sum(r['relations'] for r in reports),'issues':sum(len(r['issues']) for r in reports),'status':'FAIL' if any(r['issues'] for r in reports) else 'GEOMETRY_CLEAR_VISUAL_REVIEW_REQUIRED'}
    if report_path:Path(report_path).write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    for r in reports:print(f"{r['diagram']}: {r['relations']} relaciones; {r['counts']}")
    print(f"{result['status']}: {len(diagrams)} diagramas; {result['relations']} relaciones; {result['issues']} incidencias")
    return result

def main():
    parser=argparse.ArgumentParser(description='Audita geometría explícita Draw.io o exportación TSV Astah; no certifica renderizado de editores.')
    parser.add_argument('file',nargs='?',default='docs/diagrams/Heliostrand_Diagramas_Completos.drawio')
    parser.add_argument('--json',dest='report')
    parser.add_argument('--expected-diagrams',type=int)
    args=parser.parse_args()
    try:result=check(Path(args.file),args.report,args.expected_diagrams)
    except (ValueError,OSError,ET.ParseError,KeyError,IndexError) as err:print('FAIL:',err,file=sys.stderr);return 2
    return 1 if result['issues'] else 0

if __name__=='__main__':sys.exit(main())
