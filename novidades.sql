-- NOVIDADES (rodar no Supabase). Vai acumulando a cada etapa.

-- ===== ETAPA A: menos XP por tarefa (agora t.xp/20, mínimo 1) =====
create or replace function public.tarefa_feita() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; extra integer; pago integer; ganho integer; novo_xp integer;
        novo_nivel integer; premio integer := 0; peixes_ganhos integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is null then raise exception 'Você não está trabalhando.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '2.5 seconds' then
    raise exception 'Calma! Uma tarefa de cada vez.';
  end if;
  select * into t from trabalhos where id = m.trabalho;
  extra := greatest(0, m.nivel - t.nivel_min);
  pago  := round(t.salario / 6.0 * (1 + 0.06 * extra));
  ganho := greatest(1, round(t.xp / 20.0 * (1 + 0.04 * extra)));  -- XP reduzido (era /6)
  if t.id = 'pescador' then pago := 0; peixes_ganhos := (random() < 0.6)::integer; end if;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, tarefa_em = now() where id = m.id;
  morreu := _gastar_fome(m.id, t.fome / 6.0);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', pago, 'xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;

-- ===== ETAPA B: Amarok (no lugar da Caminhonete) e Lamborghini (no lugar do Esportivo Neon) =====
update public.loja set nome = 'Amarok', preco = 45000 where id = 'caminhonete' and tipo = 'carro';
update public.produtos set nome = 'Lamborghini', preco = 19.90 where id = 'carro_neon';

-- ===== ETAPA C: emprego novo de Lixeiro(a) =====

-- Emprego novo: Lixeiro(a) (na Prefeitura, nível 4)
insert into public.trabalhos(id, nome, salario, duracao, nivel_min, xp, fome) values
  ('lixeiro', 'Lixeiro(a)', 65, 60, 4, 25, 12)
on conflict (id) do update set nome = excluded.nome, salario = excluded.salario, duracao = excluded.duracao,
  nivel_min = excluded.nivel_min, xp = excluded.xp, fome = excluded.fome;

-- ===== ETAPA D: casas vazias, loja de móveis (com giro) e geladeira =====
-- Cada casa guarda os móveis colocados (tipo, x, y, andar, giro) e o que tem na geladeira.
alter table public.casas add column if not exists moveis jsonb not null default '[]'::jsonb;
alter table public.casas add column if not exists geladeira jsonb not null default '{}'::jsonb;
drop function if exists public.comprar_movel(text, integer, integer, integer);
drop function if exists public.mexer_movel(integer, integer, integer, boolean);

-- Preços dos móveis (dinheiro do jogo). O preço vale aqui, não no jogo.
create or replace function public.preco_movel(p_tipo text) returns integer
language sql immutable as $$
  select case p_tipo
    when 'parede' then 200 when 'porta' then 600
    when 'caixote' then 80 when 'cadeira' then 150 when 'planta' then 250 when 'colchao' then 300
    when 'tapete' then 400 when 'abajur' then 350 when 'criado' then 450 when 'mesinha' then 500
    when 'mesa' then 900 when 'pia' then 1100 when 'estante' then 1200 when 'fogao' then 1300
    when 'poltrona' then 1400 when 'armario' then 1600 when 'geladeira' then 1800 when 'sofa' then 2200
    when 'tv' then 2500 when 'cama' then 3000 when 'somcx' then 3000 when 'led' then 2000
    when 'aquario' then 6000 when 'homet' then 9000 when 'jukebox' then 12000 else null end
$$;

create or replace function public.comprar_movel(p_tipo text, p_x integer, p_y integer, p_andar integer, p_r integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pr integer;
begin
  m := _eu();
  select * into c from casas where dono = m.id;
  if c.id is null then raise exception 'Você precisa ter uma casa.'; end if;
  pr := preco_movel(p_tipo);
  if pr is null then raise exception 'Móvel inválido.'; end if;
  if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_andar not in (0, 1) or p_r not between 0 and 3 then raise exception 'Lugar inválido.'; end if;
  if jsonb_array_length(c.moveis) >= 80 then raise exception 'Sua casa já tem móveis demais (máximo 80).'; end if;
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', pr; end if;
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  update casas set moveis = moveis || jsonb_build_array(jsonb_build_object('t', p_tipo, 'x', p_x, 'y', p_y, 'a', p_andar, 'r', p_r)) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;

-- Mover/girar um móvel (de graça) ou vender de volta (devolve metade do preço)
create or replace function public.mexer_movel(p_i integer, p_x integer, p_y integer, p_r integer, p_vender boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; e jsonb;
begin
  m := _eu();
  select * into c from casas where dono = m.id;
  if c.id is null then raise exception 'Você precisa ter uma casa.'; end if;
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
create or replace function public.geladeira(p_item text, p_guardar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; q integer; g integer;
begin
  m := _eu();
  select * into c from casas where dono = m.id;
  if c.id is null then raise exception 'Você precisa ter uma casa.'; end if;
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

grant execute on function public.comprar_movel(text, integer, integer, integer, integer) to authenticated;
grant execute on function public.mexer_movel(integer, integer, integer, integer, boolean) to authenticated;
grant execute on function public.geladeira(text, boolean) to authenticated;

-- Guardar um móvel no inventário da casa (some do chão) ou tirar de lá (volta ao ser colocado)
create or replace function public.guardar_movel(p_i integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas;
begin
  m := _eu();
  select * into c from casas where dono = m.id;
  if c.id is null then raise exception 'Você precisa ter uma casa.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  update casas set moveis = jsonb_set(moveis, array[p_i::text], (moveis -> p_i) || '{"g": true}'::jsonb) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.guardar_movel(integer) to authenticated;

-- Colocar um móvel guardado no inventário (em qualquer andar)
create or replace function public.colocar_movel(p_i integer, p_x integer, p_y integer, p_r integer, p_andar integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas;
begin
  m := _eu();
  select * into c from casas where dono = m.id;
  if c.id is null then raise exception 'Você precisa ter uma casa.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_r not between 0 and 3 or p_andar not in (0, 1) then raise exception 'Lugar inválido.'; end if;
  update casas set moveis = jsonb_set(moveis, array[p_i::text], ((moveis -> p_i) - 'g') || jsonb_build_object('x', p_x, 'y', p_y, 'r', p_r, 'a', p_andar)) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.colocar_movel(integer, integer, integer, integer, integer) to authenticated;
