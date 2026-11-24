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
    objs=[];red=mat((.7,.05,.04));blk=mat((.03,.03,.03));chr=mat((.6,.6,.62))
    for y in (-.55,.55):
        bpy.ops.mesh.primitive_torus_add(location=(0,y,.3),rotation=(0,math.radians(90),0),major_radius=.24,minor_radius=.07);o=bpy.context.object;o.data.materials.append(blk);objs.append(o)
        bpy.ops.mesh.primitive_cylinder_add(location=(0,y,.3),rotation=(0,math.radians(90),0),radius=.12,depth=.06);o=bpy.context.object;o.data.materials.append(chr);objs.append(o)
    for (l,s,m_) in (((0,0,.52),(.12,.42,.1),red),((0,-.18,.68),(.15,.22,.1),red),((0,.22,.72),(.13,.3,.05),blk),((0,-.5,.85),(.33,.025,.025),chr),((0,-.45,.6),(.03,.03,.25),chr),((0,-.62,.72),(.07,.04,.07),chr)):
        bpy.ops.mesh.primitive_cube_add(location=l);o=bpy.context.object;o.scale=s;o.data.materials.append(m_);b=o.modifiers.new('b','BEVEL');b.width=.03;b.segments=3;objs.append(o)
    for o in objs:o.location+=Vector(loc)
def zera(r):
    for p in r.pose.bones:p.rotation_mode='QUATERNION';p.rotation_quaternion=(1,0,0,0);p.location=(0,0,0)
def rot(r,n,axis,deg):
    p=r.pose.bones[n];a=(p.bone.matrix_local.to_3x3().inverted()@Vector(axis)).normalized();p.rotation_quaternion=Quaternion(a,math.radians(deg))@p.rotation_quaternion
def bracos(r,fw=0,cot=0):
    rot(r,'upperarm_l',(0,1,0),72);rot(r,'upperarm_r',(0,1,0),-72)
    if fw:rot(r,'upperarm_l',(1,0,0),-fw);rot(r,'upperarm_r',(1,0,0),-fw)
    if cot:rot(r,'lowerarm_l',(1,0,0),-cot);rot(r,'lowerarm_r',(1,0,0),-cot)
def andar(r,t):
    zera(r);s=math.sin(t*2*math.pi);bracos(r,0,10)
    for sd,sg in (('l',1),('r',-1)):
        rot(r,'thigh_'+sd,(1,0,0),-28*s*sg);rot(r,'calf_'+sd,(1,0,0),45*max(0,math.sin(t*2*math.pi+(0 if sg>0 else math.pi)+1.7)))
        rot(r,'upperarm_'+sd,(1,0,0),22*s*sg)
    r.pose.bones['pelvis'].location=(0,0,0)
def sentar(r):
    zera(r);bracos(r,25,40)
    for sd in 'lr':rot(r,'thigh_'+sd,(1,0,0),-88);rot(r,'calf_'+sd,(1,0,0),88)
def pilotar(r):
    zera(r);bracos(r,38,30)
    for sd,sg in (('l',1),('r',-1)):rot(r,'thigh_'+sd,(1,0,0),-65);rot(r,'thigh_'+sd,(0,1,0),-12*sg);rot(r,'calf_'+sd,(1,0,0),80)
    rot(r,'spine_02',(1,0,0),14)
bpy.ops.object.light_add(type='SUN');L=bpy.context.object;L.data.energy=4;L.rotation_euler=(math.radians(40),0,math.radians(25))
w=bpy.data.worlds.new('w');sc.world=w;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.9,.92,1,1);w.node_tree.nodes['Background'].inputs[1].default_value=1.2
bpy.ops.object.camera_add();C=bpy.context.object;sc.camera=C;C.data.type='ORTHO';C.data.ortho_scale=2.4
sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=False;sc.render.resolution_x=420;sc.render.resolution_y=420;sc.render.film_transparent=True;sc.view_settings.view_transform='Standard'
def cam(tz=.9,az=45):
    a=math.radians(az);e=math.radians(60);d=10;C.rotation_euler=(e,0,a);C.location=Vector((math.sin(a)*math.sin(e)*d,-math.cos(a)*math.sin(e)*d,math.cos(e)*d+tz))
GEN=os.environ.get('GEN','m')
r=pessoa(1.0,'young_caucasian_male','short02','male_casualsuit02','shoes01','eyebrow001') if GEN=='m' else pessoa(0.0,'young_caucasian_female','ponytail01','female_casualsuit01','shoes02','eyebrow010')
arm=r;base=arm.location.copy()
def shot(n):bpy.context.view_layer.update();sc.render.filepath=f'{OUT}/{GEN}_{n}.png';bpy.ops.render.render(write_still=True)
cam()
for i,t in enumerate((0,.25,.5)):andar(r,t);shot('andar%d'%i)
# sentado num banco
bpy.ops.mesh.primitive_cube_add(location=(0,.12,.25));bn=bpy.context.object;bn.scale=(.6,.28,.25);bn.modifiers.new('b','BEVEL').width=.03;bn.data.materials.append(mat((.45,.28,.14)))
sentar(r);bpy.context.view_layer.update()
hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.52-hip);shot('sentado')
bpy.data.objects.remove(bn);arm.location=base
moto((0,0,0));pilotar(r);bpy.context.view_layer.update()
hip=(arm.matrix_world@arm.pose.bones['thigh_l'].head).z;arm.location.z=base.z+(.8-hip);arm.location.y=base.y-.04;cam(.8,60);shot('moto')
