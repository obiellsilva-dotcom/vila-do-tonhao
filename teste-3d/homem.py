import bpy,math,os,glob,sys
from mathutils import Vector,Quaternion
OUT=sys.argv[sys.argv.index('--')+1]
exec(open('/tmp/claude-0/mk/walk.py').read().split("A=[o for o in bpy.data.objects if o.type=='ARMATURE'][0]")[0].replace("argv=sys.argv[sys.argv.index('--')+1:];MODE=argv[0];OUT=argv[1]",""))
A=[o for o in bpy.data.objects if o.type=='ARMATURE'][0];sc.frame_set(1);A.animation_data.action=None;P=A.pose.bones
HOMEM=os.environ.get('HOMEM')=='1'
if HOMEM:
    def s(n,v):P['mixamorig:'+n].scale=v
    s('Hips',(.9,1,.82))
    s('Spine1',(1.1,1,.84));s('Spine2',(1.16,1.04,.76))
    s('Neck',(1.35,1,1.25));s('Head',(.93,.97,.95))
    for sd in('Left','Right'):s(sd+'Shoulder',(1.15,1.15,1.15));s(sd+'UpLeg',(1.08,1,1.08))
    hair=bpy.data.objects.get('PM3D_Sphere3D2');
    if hair:hair.hide_render=True
    bpy.context.view_layer.update()
    hb=P['mixamorig:Head'];hm=A.matrix_world@hb.matrix;top=A.matrix_world@P['mixamorig:HeadTop_End'].head
    ctr=hm.translation*.42+top*.58
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1,location=ctr,segments=32,ring_count=16);c=bpy.context.object
    r=(top-hm.translation).length*.56;c.scale=(r*1.0,r*1.08,r*.82);c.location=ctr+Vector((0,r*.12,r*.18))
    m=bpy.data.materials.new('cab');m.use_nodes=True;bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(.05,.03,.02,1);bs.inputs['Roughness'].default_value=.7;c.data.materials.append(m)
    for p in c.data.polygons:p.use_smooth=True
    # corta a parte da frente-baixo (testa e rosto ficam livres)
    import bmesh;bm=bmesh.new();bm.from_mesh(c.data)
    for v in [v for v in bm.verts if v.co.z< -.15 or (v.co.y< -.45 and v.co.z<.35)]:bm.verts.remove(v)
    bm.to_mesh(c.data);bm.free()
    bpy.context.view_layer.update();mw=c.matrix_world.copy();c.parent=A;c.parent_type='BONE';c.parent_bone='mixamorig:Head';bpy.context.view_layer.update();c.matrix_world=mw
bpy.ops.object.light_add(type='SUN');L=bpy.context.object;L.data.energy=4.5;L.rotation_euler=(math.radians(40),0,math.radians(25))
w=bpy.data.worlds.new('w');sc.world=w;w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.9,.92,1,1);w.node_tree.nodes['Background'].inputs[1].default_value=1.3
bpy.ops.object.camera_add();C=bpy.context.object;sc.camera=C;C.data.type='ORTHO';H=.17;C.data.ortho_scale=H*1.2
sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=False;sc.render.resolution_x=400;sc.render.resolution_y=400;sc.render.film_transparent=True;sc.view_settings.view_transform='Standard'
os.makedirs(OUT,exist_ok=True)
for i,(az,el) in enumerate([(0,90),(45,60),(90,90),(180,90)]):
    a=math.radians(az);e=math.radians(el);d=2;tz=H*.5
    C.rotation_euler=(e,0,a);C.location=Vector((math.sin(a)*math.sin(e)*d,-math.cos(a)*math.sin(e)*d,math.cos(e)*d+tz))
    sc.render.filepath=f'{OUT}/v{i}.png';bpy.ops.render.render(write_still=True)
