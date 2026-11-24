import bpy, math, sys, os
from mathutils import Vector
argv=sys.argv[sys.argv.index('--')+1:]
GEN=argv[0]; OUT=argv[1]; MODE=argv[2] if len(argv)>2 else 'preview'
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene
def mat(n,c,rough=.55,sss=0):
    m=bpy.data.materials.new(n);m.use_nodes=True;b=m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value=(*c,1);b.inputs['Roughness'].default_value=rough
    return m
def hx(h):h=h.lstrip('#');return tuple((int(h[i:i+2],16)/255)**2.2 for i in (0,2,4))
PELE=mat('pele',hx('e0a37c'),.5);CAB=mat('cab',hx('5a3420') if GEN=='m' else hx('b5562a'),.45)
CAM=mat('camisa',hx('3f8fd1') if GEN=='m' else hx('f2f2f2'));CAL=mat('calca',hx('394a6b') if GEN=='m' else hx('5a7fb5'));SAP=mat('sapato',hx('5a3a22'),.4)
OLHO=mat('olho',hx('1a1a22'),.2);BRANCO=mat('branco',hx('ffffff'),.3);LENCO=mat('lenco',hx('e05a7a'))
def smooth(o,lv=2):
    b=o.modifiers.new('b','BEVEL');b.width=min(o.dimensions)*.42;b.segments=4;b.limit_method='NONE'
    m=o.modifiers.new('s','SUBSURF');m.levels=1;m.render_levels=1
    for p in o.data.polygons:p.use_smooth=True
def cub(n,loc,sc,m,lv=2,par=None,bev=0):
    bpy.ops.mesh.primitive_cube_add(location=loc);o=bpy.context.object;o.name=n;o.scale=sc;bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m);smooth(o,lv)
    if par:o.parent=par;o.matrix_parent_inverse=par.matrix_world.inverted()
    return o
def sph(n,loc,r,m,par=None,sc=(1,1,1)):
    bpy.ops.mesh.primitive_uv_sphere_add(location=loc,radius=r,segments=24,ring_count=16);o=bpy.context.object;o.name=n;o.scale=sc;bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    for p in o.data.polygons:p.use_smooth=True
    if par:o.parent=par;o.matrix_parent_inverse=par.matrix_world.inverted()
    return o
def piv(n,loc,par=None):
    bpy.ops.object.empty_add(location=loc);e=bpy.context.object;e.name=n
    if par:e.parent=par;e.matrix_parent_inverse=par.matrix_world.inverted()
    return e
F=GEN=='f'
root=piv('root',(0,0,0))
hipZ=.82;
quad=piv('quadril',(0,0,hipZ),root)
# pernas (coxa+canela com joelho)
pern={}
for s,x in (('E',.1),('D',-.1)):
    h=piv('coxa'+s,(x,0,hipZ),quad)
    cub('coxaM'+s,(x,0,hipZ-.2),(.1,.105,.22),CAL,2,h)
    k=piv('joelho'+s,(x,0,hipZ-.4),h)
    cub('canela'+s,(x,0,hipZ-.58),(.09,.095,.21),CAL,2,k)
    cub('sapato'+s,(x,-.05,.06),(.1,.16,.065),SAP,2,k)
    pern[s]=(h,k)
tronco=piv('tronco',(0,0,hipZ),quad)
cub('tronco',(0,0,hipZ+.27),(.23 if not F else .19,.14,.3),CAM,2,tronco)
if F:cub('saia',(0,0,hipZ+.0),(.19,.13,.08),CAL,2,tronco)
else:cub('cinto',(0,0,hipZ+.0),(.19,.125,.05),CAL,2,tronco)
bra={}
for s,x in (('E',.3),('D',-.3)):
    sh=piv('ombro'+s,(x,0,hipZ+.47),tronco)
    cub('manga'+s,(x,0,hipZ+.4),(.085,.09,.11),CAM,2,sh)
    cub('braco'+s,(x,0,hipZ+.2),(.065,.07,.16),PELE,2,sh)
    sph('mao'+s,(x,0,hipZ+.03),.07,PELE,sh)
    bra[s]=sh
pesc=piv('pescoco',(0,0,hipZ+.55),tronco)
cub('pesc',(0,0,hipZ+.57),(.06,.06,.05),PELE,1,pesc)
hz=hipZ+.82
cab=sph('cabeca',(0,0,hz),.26,PELE,pesc,(1,.95,1.05))
for s,x in (('E',.09),('D',-.09)):
    sph('olhoB'+s,(x,-.225,hz+.02),.065,BRANCO,pesc,(1,.5,1.15))
    sph('olho'+s,(x,-.26,hz+.01),.042,OLHO,pesc,(1,.5,1.2))
sph('nariz',(0,-.26,hz-.06),.03,PELE,pesc)
sph('orelhaE',(.25,0,hz),.05,PELE,pesc,(.5,1,1.2));sph('orelhaD',(-.25,0,hz),.05,PELE,pesc,(.5,1,1.2))
if F:
    sph('cabelo',(0,.07,hz+.07),.275,CAB,pesc,(1.06,1,.95))
    cub('franja',(0,-.17,hz+.2),(.2,.08,.06),CAB,2,pesc)
    sph('coque',(0,.24,hz+.2),.13,CAB,pesc)
    cub('cabeloAtras',(0,.16,hz-.14),(.25,.1,.22),CAB,2,pesc)
    for s2,x2 in (('E',.23),('D',-.23)):cub('mecha'+s2,(x2,.0,hz-.06),(.05,.12,.17),CAB,2,pesc)
    cub('lenco',(0,-.05,hipZ+.6),(.12,.1,.04),LENCO,2,tronco)
else:
    sph('cabelo',(0,.03,hz+.08),.275,CAB,pesc,(1.02,1,.9))
    cub('topete',(0,-.12,hz+.22),(.2,.1,.06),CAB,2,pesc)
# luz e câmera (isométrica do jogo: 2:1)
bpy.ops.object.light_add(type='SUN',location=(3,-4,6));L=bpy.context.object;L.data.energy=3.2;L.rotation_euler=(math.radians(45),0,math.radians(30))
L.data.angle=math.radians(8)
w=bpy.data.worlds.new('w');sc.world=w;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.85,.88,.95,1);w.node_tree.nodes['Background'].inputs[1].default_value=.9
bpy.ops.object.camera_add();C=bpy.context.object;sc.camera=C;C.data.type='ORTHO';C.data.ortho_scale=2.3
el=math.radians(60);C.rotation_euler=(el,0,math.radians(45));d=10
C.location=Vector((math.sin(math.radians(45))*math.sin(el)*d,-math.cos(math.radians(45))*math.sin(el)*d,math.cos(el)*d+.95))
sc.render.film_transparent=True;sc.render.resolution_x=256;sc.render.resolution_y=256
sc.render.engine='CYCLES'
if 0:pass

if sc.render.engine=='CYCLES':sc.cycles.samples=24;sc.cycles.device='CPU';sc.cycles.use_denoising=False
sc.view_settings.view_transform='Standard'
def pose(t,dirang,andando=True):
    root.rotation_euler=(0,0,math.radians(dirang))
    a=math.sin(t*2*math.pi) if andando else 0
    for s,sg in (('E',1),('D',-1)):
        h,k=pern[s];h.rotation_euler=(math.radians(32*a*sg),0,0)
        k.rotation_euler=(math.radians(-45*max(0,math.sin(t*2*math.pi+(0 if sg>0 else math.pi)+1.6)) if andando else 0),0,0)
        bra[s].rotation_euler=(math.radians(-30*a*sg),0,math.radians(6*sg))
    quad.location=(0,0,hipZ+(abs(math.sin(t*2*math.pi))*.03 if andando else 0))
    tronco.rotation_euler=(math.radians(3 if andando else 0),0,math.radians(5*a))
os.makedirs(OUT,exist_ok=True)
if MODE=='preview':
    for i,(t,dr,an) in enumerate([(0,0,False),(0.25,0,True),(0,45,False),(0.25,90,True),(0.6,180,True),(0,-45,False)]):
        pose(t,dr,an);sc.render.filepath=f'{OUT}/p{i}.png';bpy.ops.render.render(write_still=True)
else:
    for di in range(8):
        for f in range(8):
            pose(f/8,di*45,True);sc.render.filepath=f'{OUT}/w{di}_{f}.png';bpy.ops.render.render(write_still=True)
        pose(0,di*45,False);sc.render.filepath=f'{OUT}/i{di}.png';bpy.ops.render.render(write_still=True)
print('ENGINE',sc.render.engine)
