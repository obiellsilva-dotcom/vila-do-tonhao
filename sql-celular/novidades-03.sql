-- novidades- 3 de 5. Rode na ordem.
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

-- ===== ETAPA E: até 1 casa de cada tipo (barata, intermediária, mansão) =====
-- cada jogador pode ter no máximo 1 casa de cada tipo (barata, intermediária, mansão)
alter table public.casas add column if not exists tipo text generated always as (case when preco >= 50000 then 'mansao' when preco >= 10000 then 'media' else 'barata' end) stored;
drop index if exists public.casas_um_dono;
create unique index if not exists casas_um_por_tipo on public.casas(dono, tipo) where dono is not null;

create or replace function public.comprar_casa(p_casa integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; antiga public.casas; volta integer := 0;
begin
  m := _eu();
  select * into c from casas where id = p_casa for update;
  if not found then raise exception 'Essa casa não existe.'; end if;
  if c.dono = m.id then raise exception 'Essa casa já é sua.'; end if;
  if c.dono is not null then raise exception 'Essa casa já tem dono.'; end if;
  if m.nivel < c.nivel_min then raise exception 'Essa casa libera no nível %.', c.nivel_min; end if;
  select * into antiga from casas where dono = m.id and tipo = c.tipo for update;
  if found then volta := antiga.preco / 2; end if;
  if m.dinheiro + volta < c.preco then raise exception 'Dinheiro insuficiente para essa casa.'; end if;
  if antiga.id is not null then
    update casas set dono = null, comprada_em = null, aberta = false where id = antiga.id;
    update vagas set morador = null, carro = null, desde = null where casa = antiga.id;
  end if;
  update casas set dono = m.id, comprada_em = now(), aberta = false where id = c.id;
  update moradores set dinheiro = dinheiro + volta - c.preco, casa_id = c.id where id = m.id;
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;

