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
drop function if exists public.comprar_movel(text, integer, integer, integer, integer);
drop function if exists public.mexer_movel(integer, integer, integer, integer, boolean);
drop function if exists public.geladeira(text, boolean);
drop function if exists public.guardar_movel(integer);
drop function if exists public.colocar_movel(integer, integer, integer, integer, integer);

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

create or replace function public.comprar_movel(p_casa integer, p_tipo text, p_x integer, p_y integer, p_andar integer, p_r integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pr integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
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
create or replace function public.deixar_prefeitura() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  update cidade set prefeito = null, desde = null where id = 1 and prefeito = m.id;
  update moradores set trabalho = null where id = m.id and trabalho = 'prefeito';
  return json_build_object('prefeito', null);
end $$;
grant execute on function public.assumir_prefeitura() to authenticated;
grant execute on function public.deixar_prefeitura() to authenticated;

-- Empregos liberam em níveis mais altos (agora vai até o 50)
update public.trabalhos set nivel_min = v.n from (values
  ('bar',1),('mercadinho',1),('posto',3),('pescador',4),('padaria',5),('lixeiro',6),('barbearia',7),
  ('prefeitura',10),('oficina',12),('banco',15),('concessionaria',18),('fabrica',20),('enfermeiro',21),
  ('policia',23),('gerente',25),('delegado',27),('medico',29),('prefeito',30)) as v(id, n)
where trabalhos.id = v.id;

-- VIP: R$ 15,99 e libera a Lamborghini enquanto estiver ativo
update public.produtos set preco = 15.99 where tipo = 'vip';
create or replace function public._tem_carro(m public.moradores, p_carro text) returns boolean
language sql stable as $$
  select p_carro = any(m.carros) or (p_carro = 'neon' and m.vip_ate is not null and m.vip_ate > now())
$$;
create or replace function public.usar_carro(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_carro is not null and not _tem_carro(m, p_carro) then raise exception 'Esse carro não é seu.'; end if;
  update moradores set carro = p_carro where id = m.id;
  update vagas set carro = p_carro where morador = m.id and p_carro is not null;
  return json_build_object('carro', p_carro);
end $$;

create or replace function public.estacionar(p_vaga text, p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; v public.vagas; dono_casa uuid; visto timestamptz;
begin
  m := _eu();
  if not _tem_carro(m, p_carro) then raise exception 'Esse carro não é seu.'; end if;
  select * into v from vagas where id = p_vaga for update;
  if not found then raise exception 'Essa vaga não existe.'; end if;
  if v.casa is not null then
    select dono into dono_casa from casas where id = v.casa;
    if dono_casa is distinct from m.id then raise exception 'Essa garagem é de outra pessoa.'; end if;
  elsif v.morador is not null and v.morador <> m.id then
    select visto_em into visto from moradores where id = v.morador;
    if visto > now() - interval '30 minutes' then raise exception 'Vaga ocupada.'; end if;
  end if;
  update vagas set morador = null, carro = null, desde = null where morador = m.id and id <> p_vaga;
  update vagas set morador = m.id, carro = p_carro, desde = now() where id = p_vaga;
  return json_build_object('vaga', p_vaga);
end $$;

create or replace function public.cor_carro(p_carro text, p_cor text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not _tem_carro(m, p_carro) then raise exception 'Esse carro não é seu.'; end if;
  if p_cor not in ('#3c78d8','#c0392b','#2b2b30','#eeeeee','#aeb3b8','#f1c40f','#27ae60','#e67e22','#e84393','#7b241c') then
    raise exception 'Cor inválida.'; end if;
  update moradores set carro_cores = carro_cores || jsonb_build_object(p_carro, p_cor) where id = m.id;
  return json_build_object('ok', true);
end $$;

-- Novidades: guarda a última tela de novidades que a pessoa já viu (aparece só 1 vez)
alter table public.moradores add column if not exists novidades text;
create or replace function public.visto_novidades(p_v text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  update moradores set novidades = left(p_v, 20) where id = m.id;
  return json_build_object('novidades', left(p_v, 20));
end $$;
grant execute on function public.visto_novidades(text) to authenticated;
