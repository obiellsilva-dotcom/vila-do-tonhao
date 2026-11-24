import bpy,math,sys,os
from mathutils import Vector
from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.targetservice import TargetService
D='/root/.config/blender/4.2/extensions/.user/user_default/mpfb/data/'
argv=sys.argv[sys.argv.index('--')+1:];OUT=argv[0]
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene
def pessoa(gen,x,skin,hair,roupa,sapato,brow):
    md=TargetService.get_default_macro_info_dict();md['gender']=gen;md['age']=.45;md['muscle']=.6 if gen>.5 else .5;md['race']={'asian':.2,'caucasian':.5,'african':.3}
    b=HumanService.create_human(macro_detail_dict=md)
    HumanService.set_character_skin(D+'skins/%s/%s.mhmat'%(skin,skin),b,skin_type='MAKESKIN')
    for f,t in ((D+'eyes/high-poly/high-poly.mhclo','Eyes'),(D+'eyebrows/%s/%s.mhclo'%(brow,brow),'Eyebrows'),(D+'eyelashes/eyelashes01/eyelashes01.mhclo','Eyelashes'),
                (D+'hair/%s/%s.mhclo'%(hair,hair),'Hair'),(D+'clothes/%s/%s.mhclo'%(roupa,roupa),'Clothes'),(D+'clothes/%s/%s.mhclo'%(sapato,sapato),'Clothes')):
        try:HumanService.add_mhclo_asset(f,b,asset_type=t,set_up_rigging=False,interpolate_weights=False,import_subrig=False,import_weights=False)
        except Exception as e:print('FALHOU',f,e)
    for o in bpy.data.objects:
        if o.parent==b or o==b:o.location.x+=x if o==b else 0
    b.location.x=x
    return b
pessoa(0.0,-.5,'young_caucasian_female','ponytail01','female_casualsuit01','shoes02','eyebrow010')
pessoa(1.0,.5,'young_caucasian_male','short02','male_casualsuit02','shoes01','eyebrow001')
bpy.ops.object.light_add(type='SUN');L=bpy.context.object;L.data.energy=4;L.rotation_euler=(math.radians(40),0,math.radians(25))
w=bpy.data.worlds.new('w');sc.world=w;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.9,.92,1,1);w.node_tree.nodes['Background'].inputs[1].default_value=1.2
bpy.ops.object.camera_add();C=bpy.context.object;sc.camera=C;C.data.type='ORTHO';C.data.ortho_scale=2.3
sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=False;sc.render.resolution_x=512;sc.render.resolution_y=512;sc.render.film_transparent=True;sc.view_settings.view_transform='Standard'
os.makedirs(OUT,exist_ok=True)
for i,(az,el) in enumerate([(0,90),(45,60),(180,90)]):
    a=math.radians(az);e=math.radians(el);d=10;tz=.9
    C.rotation_euler=(e,0,a);C.location=Vector((math.sin(a)*math.sin(e)*d,-math.cos(a)*math.sin(e)*d,math.cos(e)*d+tz))
    sc.render.filepath=f'{OUT}/v{i}.png';bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/mh.blend')
