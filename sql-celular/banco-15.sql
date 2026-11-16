-- banco- 15 de 16. Rode na ordem.
-- Mover/girar um móvel (de graça) ou vender de volta (devolve metade do preço)
create or replace function public.mexer_movel(p_casa integer, p_i integer, p_x integer, p_y integer, p_r integer, p_vender boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; e jsonb;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  e := c.moveis -> p_i;
  if p_vender then
    update moradores set dinheiro = dinheiro + coalesce(preco_movel(e->>'t'), 0) / 2 where id = m.id;
    update casas set moveis = moveis - p_i where id = c.id;
  else
    if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_r not between 0 and 3 then raise exception 'Lugar inválido.'; end if;
    update casas set moveis = jsonb_set(moveis, array[p_i::text], (e - 'g') || jsonb_build_object('x', p_x, 'y', p_y, 'r', p_r)) where id = c.id;
  end if;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;

-- Geladeira: guarda um item da mochila ou pega de volta para a mochila (só o dono)
create or replace function public.geladeira(p_casa integer, p_item text, p_guardar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; q integer; g integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if not exists (select 1 from jsonb_array_elements(c.moveis) e where e->>'t' = 'geladeira') then
    raise exception 'Sua casa não tem geladeira. Compre uma na loja de móveis!'; end if;
  if not exists (select 1 from loja where id = p_item and tipo = 'consumo') then raise exception 'Item inválido.'; end if;
  q := coalesce((m.mochila->>p_item)::integer, 0);
  g := coalesce((c.geladeira->>p_item)::integer, 0);
  if p_guardar then
    if q <= 0 then raise exception 'Você não tem isso na mochila.'; end if;
    if g >= 30 then raise exception 'A geladeira já tem 30 desse item.'; end if;
    update moradores set mochila = case when q - 1 > 0 then mochila || jsonb_build_object(p_item, q - 1) else mochila - p_item end where id = m.id;
    update casas set geladeira = geladeira || jsonb_build_object(p_item, g + 1) where id = c.id;
  else
    if g <= 0 then raise exception 'A geladeira não tem isso.'; end if;
    if q >= 20 then raise exception 'Sua mochila já tem 20 desse item.'; end if;
    update moradores set mochila = mochila || jsonb_build_object(p_item, q + 1) where id = m.id;
    update casas set geladeira = case when g - 1 > 0 then geladeira || jsonb_build_object(p_item, g - 1) else geladeira - p_item end where id = c.id;
  end if;
  return json_build_object('geladeira', (select geladeira from casas where id = c.id), 'mochila', (select mochila from moradores where id = m.id), 'eu', _estado(m.id));
end $$;

grant execute on function public.comprar_movel(integer, text, integer, integer, integer, integer) to authenticated;
grant execute on function public.mexer_movel(integer, integer, integer, integer, integer, boolean) to authenticated;
grant execute on function public.geladeira(integer, text, boolean) to authenticated;

-- Guardar um móvel no inventário da casa (some do chão) ou tirar de lá (volta ao ser colocado)
create or replace function public.guardar_movel(p_casa integer, p_i integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  update casas set moveis = jsonb_set(moveis, array[p_i::text], (moveis -> p_i) || '{"g": true}'::jsonb) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.guardar_movel(integer, integer) to authenticated;

-- Colocar um móvel guardado no inventário (em qualquer andar)
create or replace function public.colocar_movel(p_casa integer, p_i integer, p_x integer, p_y integer, p_r integer, p_andar integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_r not between 0 and 3 or p_andar not in (0, 1) then raise exception 'Lugar inválido.'; end if;
  update casas set moveis = jsonb_set(moveis, array[p_i::text], ((moveis -> p_i) - 'g') || jsonb_build_object('x', p_x, 'y', p_y, 'r', p_r, 'a', p_andar)) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.colocar_movel(integer, integer, integer, integer, integer, integer) to authenticated;

-- ===== ETAPA F: prefeito pelo nível 30, níveis dos empregos, VIP com Lamborghini e novidades =====
-- Prefeito: não é mais automático. Qualquer um no nível 30+ assume se a cidade estiver sem prefeito
-- (ou se o prefeito sumir por mais de 3 dias). Quem é prefeito pode deixar o cargo.
drop trigger if exists prefeito_top1 on public.moradores;
drop function if exists public._atualiza_prefeito() cascade;
create or replace function public.assumir_prefeitura() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; atual public.moradores;
begin
  m := _eu();
  if m.nivel < 30 then raise exception 'A prefeitura libera no nível 30.'; end if;
  select mo.* into atual from cidade c join moradores mo on mo.id = c.prefeito where c.id = 1;
  if atual.id = m.id then raise exception 'Você já é o prefeito!'; end if;
  if atual.id is not null and not atual.banido and atual.visto_em > now() - interval '3 days' then
    raise exception 'A cidade já tem prefeito: %.', atual.nome; end if;
  insert into cidade(id, prefeito, desde) values (1, m.id, now())
  on conflict (id) do update set prefeito = m.id, desde = now();
  return json_build_object('prefeito', m.id, 'nome', m.nome);
end $$;
