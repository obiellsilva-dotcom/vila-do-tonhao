-- banco- 6 de 16. Rode na ordem.
-- filtro de palavrões (adicione palavras na lista se quiser)
create or replace function public.limpar_texto(t text) returns text
language sql immutable as $$
  select regexp_replace(t,
    '\m(porra|caralho|merda|puta|puto|buceta|boceta|viado|fdp|pqp|arrombado|arrombada|cuzao|cuzão|vagabunda|vagabundo|corno|piranha|desgraçado|desgraçada|otario|otário|babaca|retardado|macaco|cu)\M',
    '***', 'gi')
$$;

create or replace function public.enviar_msg(p_sala integer, p_texto text) returns public.chat
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := btrim(regexp_replace(coalesce(p_texto,''), '\s+', ' ', 'g')); r public.chat;
begin
  m := _eu();
  if char_length(t) = 0 then raise exception 'Mensagem vazia.'; end if;
  t := left(t, 140);
  if m.ultima_msg is not null and now() - m.ultima_msg < interval '1.5 seconds' then
    raise exception 'Calma! Espere um pouquinho para mandar outra.';
  end if;
  if p_sala < 1 or p_sala > 100 then raise exception 'Sala inválida.'; end if;
  update moradores set ultima_msg = now() where id = m.id;
  insert into chat(sala, morador, nome, texto) values (p_sala, m.id, m.nome, limpar_texto(t)) returning * into r;
  return r;
end $$;

create or replace function public.denunciar(p_alvo uuid, p_motivo text) returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_alvo = m.id then raise exception 'Não dá para se denunciar.'; end if;
  if (select count(*) from denuncias where autor = m.id and criado_em > now() - interval '1 hour') >= 10 then
    raise exception 'Muitas denúncias seguidas. Tente mais tarde.';
  end if;
  insert into denuncias(autor, alvo, motivo) values (m.id, p_alvo, left(coalesce(p_motivo,''), 200));
end $$;

-- limpeza: guarda só as últimas 200 mensagens de cada sala
create or replace function public._podar_chat() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  delete from chat where sala = new.sala
    and id not in (select id from chat where sala = new.sala order by id desc limit 200);
  return null;
end $$;
drop trigger if exists podar_chat on public.chat;
create trigger podar_chat after insert on public.chat for each row
  when (new.id % 50 = 0) execute function public._podar_chat();

-- Quem pode chamar as funções: só jogadores logados (inclusive anônimos)
revoke execute on all functions in schema public from public, anon;
grant execute on function
  public.criar_morador(text, text), public.pulso(), public.comecar_trabalho(text), public.terminar_trabalho(),
  public.largar_trabalho(), public.comprar(text), public.vender_peixes(), public.comer_fruta(integer),
  public.comprar_carro(text), public.usar_carro(text), public.estacionar(text, text), public.sair_vaga(),
  public.comprar_casa(integer), public.enviar_msg(integer, text), public.denunciar(uuid, text),
  public.nivel_de(integer), public.xp_do_nivel(integer),
  public.atualizar_perfil(text, text, text, text), public.definir_foto(text), public.sinuca(integer)
to authenticated;
revoke execute on function public._eu(), public._estado(uuid), public._gastar_fome(uuid, numeric), public._podar_chat()
from authenticated;

-- ---------- Tempo real: chat, casas e vagas aparecem na hora ----------
do $$
declare t text;
begin
  foreach t in array array['chat','casas','vagas'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ---------- Fotos de perfil (Supabase Storage) ----------
-- Pasta pública "fotos": cada pessoa só envia, troca ou apaga arquivos dentro da pasta com o próprio id.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', true, 524288, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "fotos: todos veem" on storage.objects;
create policy "fotos: todos veem" on storage.objects for select using (bucket_id = 'fotos');
drop policy if exists "fotos: dono envia" on storage.objects;
create policy "fotos: dono envia" on storage.objects for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "fotos: dono troca" on storage.objects;
create policy "fotos: dono troca" on storage.objects for update to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "fotos: dono apaga" on storage.objects;
create policy "fotos: dono apaga" on storage.objects for delete to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- Limpeza: tira do jogo (e do ranking) os moradores de teste da instalação ----------
-- (desativado para proteger contas) delete from auth.users where id in (select id from public.moradores where nome like 'Teste Claude%');

-- ===================== ETAPA 2: VIP, roupas novas, empregos e carros =====================

-- o estado do jogador agora inclui o VIP
create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;

