import bpy,math,sys,os
from mathutils import Vector,Quaternion
from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.targetservice import TargetService
D='/root/.config/blender/4.2/extensions/.user/user_default/mpfb/data/'
OUT=sys.argv[sys.argv.index('--')+1];os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True);sc=bpy.context.scene
def pessoa(gen,skin,hair,roupa,sapato,brow):
    md=TargetService.get_default_macro_info_dict();md['gender']=gen;md['age']=.45;md['muscle']=.6 if gen>.5 else .5;md['race']={'asian':.2,'caucasian':.5,'african':.3}
    b=HumanService.create_human(macro_detail_dict=md)
    HumanService.set_character_skin(D+'skins/%s/%s.mhmat'%(skin,skin),b,skin_type='MAKESKIN')
    r=HumanService.add_builtin_rig(b,'game_engine')
    for f,t in ((D+'eyes/high-poly/high-poly.mhclo','Eyes'),(D+'eyebrows/%s/%s.mhclo'%(brow,brow),'Eyebrows'),(D+'eyelashes/eyelashes01/eyelashes01.mhclo','Eyelashes'),
                (D+'hair/%s/%s.mhclo'%(hair,hair),'Hair'),(D+'clothes/%s/%s.mhclo'%(roupa,roupa),'Clothes'),(D+'clothes/%s/%s.mhclo'%(sapato,sapato),'Clothes')):
        try:HumanService.add_mhclo_asset(f,b,asset_type=t)
        except Exception as e:print('FALHOU',f,e)
    return r
def mat(c):
    m=bpy.data.materials.new('m');m.use_nodes=True;n=m.node_tree.nodes['Principled BSDF'];n.inputs['Base Color'].default_value=(*c,1);n.inputs['Roughness'].default_value=.35;return m
def moto(loc):
    # moto esportiva no tamanho da moto do jogo (comprimento ~ altura da pessoa)
    objs=[];wht=mat((.85,.86,.88));blk=mat((.03,.03,.035));chr=mat((.55,.55,.58));red=mat((.8,.08,.05))
    def cube(l,s_,m_,rx=0,bev=.04):
        bpy.ops.mesh.primitive_cube_add(location=l,rotation=(math.radians(rx),0,0));o=bpy.context.object;o.scale=s_;o.data.materials.append(m_);bb=o.modifiers.new('b','BEVEL');bb.width=bev;bb.segments=3;objs.append(o);return o
    for y in (-.62,.6):
        bpy.ops.mesh.primitive_torus_add(location=(0,y,.27),rotation=(0,math.radians(90),0),major_radius=.21,minor_radius=.065);o=bpy.context.object;o.data.materials.append(blk);objs.append(o)
        bpy.ops.mesh.primitive_cylinder_add(location=(0,y,.27),rotation=(0,math.radians(90),0),radius=.15,depth=.05);o=bpy.context.object;o.data.materials.append(chr);objs.append(o)
    cube((0,-.42,.55),(.13,.22,.14),wht,25)        # carenagem da frente
    cube((0,-.15,.62),(.14,.17,.1),wht)            # tanque
    cube((0,.12,.58),(.12,.16,.04),blk)            # banco do piloto
    cube((0,.36,.66),(.09,.14,.05),wht,-12)        # rabeta
    cube((0,.03,.38),(.1,.3,.12),blk)              # motor
    cube((0,-.55,.4),(.03,.03,.2),chr,20)          # garfo
    cube((0,-.36,.7),(.24,.02,.02),blk)            # guidão (semi-guidão)
    cube((0,-.6,.6),(.06,.03,.05),red)             # farol
    cube((0,.5,.62),(.05,.02,.03),red)             # lanterna
    for x in (-.17,.17):cube((x,.14,.3),(.06,.03,.015),chr)  # pedaleiras
    for o in objs:o.location+=Vector(loc)
def zera(r):
    for p in r.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0)
def rot(r,n,axis,deg):
    p=r.pose.bones[n];a=(p.bone.matrix_local.to_3x3().inverted()@Vector(axis)).normalized();p.rotation_quaternion=Quaternion(a,math.radians(deg))@p.rotation_quaternion
CAX=eval(os.environ.get('CAX','(0,0,1)'));CS=float(os.environ.get('CS','-1'))
TW=float(os.environ.get('TW','-70'));AB=float(os.environ.get('AB','58'));PR=float(os.environ.get('PR','80'))
def gira(r,n,deg):
    p=r.pose.bones[n];p.rotation_quaternion=p.rotation_quaternion@Quaternion((0,1,0),math.radians(deg))
def dedos(r,deg):
    for p in r.pose.bones:
        if any(k in p.name for k in ('index','middle','ring','pinky')):p.rotation_quaternion=p.rotation_quaternion@Quaternion((1,0,0),math.radians(deg))
def bracos(r,fw=0,cot=0):
    rot(r,'upperarm_l',(0,1,0),AB);rot(r,'upperarm_r',(0,1,0),-AB)
    gira(r,'upperarm_l',TW);gira(r,'upperarm_r',-TW);dedos(r,22)
    if fw:rot(r,'upperarm_l',(1,0,0),-fw);rot(r,'upperarm_r',(1,0,0),-fw)
    if cot:
        for sd,sg in (('l',1),('r',-1)):p=r.pose.bones['lowerarm_'+sd];p.rotation_quaternion=p.rotation_quaternion@Quaternion(Vector(CAX),math.radians(cot*CS*sg))
    for sd,sg in (('l',1),('r',-1)):p=r.pose.bones['lowerarm_'+sd];p.rotation_quaternion=p.rotation_quaternion@Quaternion((0,1,0),math.radians(PR*sg))
def andar(r,t):
    zera(r);s=math.sin(t*2*math.pi);bracos(r,0,6+6*max(0,s))
    for sd,sg in (('l',1),('r',-1)):
        rot(r,'thigh_'+sd,(1,0,0),-24*s*sg);rot(r,'calf_'+sd,(1,0,0),32*max(0,math.sin(t*2*math.pi+(0 if sg>0 else math.pi)+1.7)))
        rot(r,'upperarm_'+sd,(1,0,0),30*s*sg)
    r.pose.bones['pelvis'].location=(0,0,0)
from mathutils import Matrix
def _upd():bpy.context.view_layer.update()
def aim(r,n,d):
    """aponta o osso n na direção d (espaço do esqueleto) com a menor rotação possível a partir da pose de descanso"""
    _upd();pb=r.pose.bones[n];rest=pb.bone.matrix_local.to_3x3();rd=(rest@Vector((0,1,0))).normalized()
    q=rd.rotation_difference(Vector(d).normalized());M=(q.to_matrix()@rest).to_4x4();M.translation=pb.head.copy();pb.matrix=M;_upd()
def ik2(r,a,b,alvo,polo):
    """braço/perna de 2 ossos até o alvo (espaço do esqueleto); polo = para onde aponta o cotovelo/joelho"""
    _upd();S=r.pose.bones[a].head.copy();L1=r.pose.bones[a].bone.length;L2=r.pose.bones[b].bone.length
    T=Vector(alvo);v=T-S;d=min(max(v.length,1e-4),L1+L2-1e-4);u=v.normalized()
    x=(L1*L1+d*d-L2*L2)/(2*d);h=math.sqrt(max(L1*L1-x*x,0));p=Vector(polo);p=(p-u*p.dot(u)).normalized()
    E=S+u*x+p*h;aim(r,a,E-S);aim(r,b,(S+u*d)-E)
def W2A(r,w):return r.matrix_world.inverted()@Vector(w)
def bracos_baixo(r,swing=0,cot=12,abre=.06):
    for sd,sx in (('l',1),('r',-1)):
        a=math.radians(swing*sx if False else swing);c=math.radians(cot)
        sw=swing*(1 if sd=='l' else -1);a=math.radians(sw)
        aim(r,'upperarm_'+sd,(sx*abre,-math.sin(a),-math.cos(a)))
        aim(r,'lowerarm_'+sd,(sx*abre*.6,-math.sin(a+c),-math.cos(a+c)))
def andar(r,t):
    zera(r);s=math.sin(t*2*math.pi)
    for sd,sg in (('l',1),('r',-1)):
        rot(r,'thigh_'+sd,(1,0,0),-24*s*sg);rot(r,'calf_'+sd,(1,0,0),32*max(0,math.sin(t*2*math.pi+(0 if sg>0 else math.pi)+1.7)))
    for sd,sg in (('l',-1),('r',1)):
        sw=24*s*sg;a=math.radians(sw);c=math.radians(10+8*max(0,sw)/24);sx=1 if sd=='l' else -1
        aim(r,'upperarm_'+sd,(sx*.06,-math.sin(a),-math.cos(a)));aim(r,'lowerarm_'+sd,(sx*.04,-math.sin(a+c),-math.cos(a+c)))
def parado(r):zera(r);bracos_baixo(r,0,10)
def sentar(r):
    zera(r)
    for sd in 'lr':rot(r,'thigh_'+sd,(1,0,0),-88);rot(r,'calf_'+sd,(1,0,0),84)
    _upd()
    for sd,sx in (('l',1),('r',-1)):
        th=r.pose.bones['thigh_'+sd];k=th.tail.copy();h=th.head.copy();alvo=h+(k-h)*.62+Vector((0,0,.07*(r.pose.bones['thigh_l'].bone.length/.45)));alvo.x=h.x*1.15
        ik2(r,'upperarm_'+sd,'lowerarm_'+sd,alvo,(sx*.4,1,-.2))
def pilotar(r,MOTO_GRIP=None,MOTO_PEG=None):
    zera(r)
    rot(r,'spine_01',(1,0,0),16);rot(r,'spine_02',(1,0,0),14);rot(r,'spine_03',(1,0,0),8);rot(r,'neck_01',(1,0,0),-20);rot(r,'head',(1,0,0),-14)
    _upd()
    for sd,sx in (('l',1),('r',-1)):
        if MOTO_PEG:ik2(r,'thigh_'+sd,'calf_'+sd,W2A(r,(sx*MOTO_PEG[0],MOTO_PEG[1],MOTO_PEG[2])),(sx*.15,-1,.3))
        if MOTO_GRIP:ik2(r,'upperarm_'+sd,'lowerarm_'+sd,W2A(r,(sx*MOTO_GRIP[0],MOTO_GRIP[1],MOTO_GRIP[2])),(sx*.6,.5,-.6))
bpy.ops.object.light_add(type='SUN');L=bpy.context.object;L.data.energy=4;L.rotation_euler=(math.radians(40),0,math.radians(25))
w=bpy.data.worlds.new('w');sc.world=w;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.9,.92,1,1);w.node_tree.nodes['Background'].inputs[1].default_value=1.2
bpy.ops.object.camera_add();C=bpy.context.object;sc.camera=C;C.data.type='ORTHO';C.data.ortho_scale=2.4
sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=False;sc.render.resolution_x=420;sc.render.resolution_y=420;sc.render.film_transparent=True;sc.view_settings.view_transform='Standard'
def cam(tz=.9,az=45):
    a=math.radians(az);e=math.radians(60);d=10;C.rotation_euler=(e,0,a);C.location=Vector((math.sin(a)*math.sin(e)*d,-math.cos(a)*math.sin(e)*d,math.cos(e)*d+tz))
GEN=os.environ.get('GEN','m');TESTE=os.environ.get('TESTE')
r=pessoa(1.0,'young_caucasian_male','short02','male_casualsuit02','shoes01','eyebrow001') if GEN=='m' else pessoa(0.0,'young_caucasian_female','ponytail01','female_casualsuit01','shoes02','eyebrow010')
arm=r;base=arm.location.copy()
def shot(n):bpy.context.view_layer.update();sc.render.filepath=f'{OUT}/{GEN}_{n}.png';bpy.ops.render.render(write_still=True)
cam()
VID=os.environ.get('VID')
if VID:
    N=int(os.environ.get('N','48'));sc.render.resolution_x=sc.render.resolution_y=int(os.environ.get('RES','320'));sc.cycles.samples=12;C.data.ortho_scale=2.3
    if VID=='sit':
        bpy.ops.mesh.primitive_cube_add(location=(0,.12,.25));bn=bpy.context.object;bn.scale=(.6,.24,.22);bn.data.materials.append(mat((.45,.28,.14)))
    if VID=='moto':moto((0,0,0))
    for f in range(N):
        t=f/N
        if VID=='walk':andar(r,(t*4)%1)
        elif VID=='idle':parado(r)
        elif VID=='sit':sentar(r);bpy.context.view_layer.update();arm.location=base;bpy.context.view_layer.update();hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.5-hip)
        elif VID=='moto':
            zera(r);arm.location=base;_upd();hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.66-hip);arm.location.y=base.y+.14;pilotar(r,(.22,-.36,.72),(.17,.16,.32))
        cam(.85,t*360);C.rotation_euler.x=math.radians(70);a=math.radians(t*360);e=math.radians(70);C.location=Vector((math.sin(a)*math.sin(e)*10,-math.cos(a)*math.sin(e)*10,math.cos(e)*10+.85))
        bpy.context.view_layer.update();sc.render.filepath=f'{OUT}/{VID}_{f:03d}.png';bpy.ops.render.render(write_still=True)
    raise SystemExit
if TESTE:
    C.data.ortho_scale=1.6;sc.render.resolution_x=sc.render.resolution_y=360
    P=TESTE
    if P=='sit':
        bpy.ops.mesh.primitive_cube_add(location=(0,.12,.25));bn=bpy.context.object;bn.scale=(.6,.24,.22)
    if P=='moto':moto((0,0,0))
    for az in (0,90,180,300):
        zera(r);arm.location=base;_upd()
        if P=='idle':parado(r)
        if P=='sit':hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.5-hip);sentar(r)
        if P=='moto':hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.66-hip);arm.location.y=base.y+.14;pilotar(r,(.22,-.36,.72),(.17,.16,.32))
        a=math.radians(az);C.rotation_euler=(math.radians(80),0,a);C.location=Vector((math.sin(a)*math.sin(math.radians(80))*10,-math.cos(a)*math.sin(math.radians(80))*10,math.cos(math.radians(80))*10+.8))
        shot(P+'_az%d'%az)
    raise SystemExit
    C.data.ortho_scale=1.1
    for az in (0,180,90):
        cam(1.15,az);C.rotation_euler.x=math.radians(88);a=math.radians(az);C.location=Vector((math.sin(a)*10,-math.cos(a)*10,1.15));zera(r);bracos(r,0,8);shot('pr%d_az%d'%(PR,az))
    raise SystemExit
for i,t in enumerate((0,.25,.5)):andar(r,t);shot('andar%d'%i)
# sentado num banco
bpy.ops.mesh.primitive_cube_add(location=(0,.12,.25));bn=bpy.context.object;bn.scale=(.6,.24,.22);bn.modifiers.new('b','BEVEL').width=.03;bn.data.materials.append(mat((.45,.28,.14)))
sentar(r);bpy.context.view_layer.update()
hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.5-hip);shot('sentado')
bpy.data.objects.remove(bn);arm.location=base
moto((0,0,0));pilotar(r);bpy.context.view_layer.update()
hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.64-hip);arm.location.y=base.y+.1;cam(.8,60);shot('moto')
