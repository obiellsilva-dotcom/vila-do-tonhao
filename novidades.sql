-- ATUALIZAÇÃO COMPLETA da Cidade do Tonhão. Rode tudo de uma vez no Supabase (SQL Editor > New query > colar > Run).
-- Pode rodar de novo sem perder dados.
-- Inclui: sede e comidas novas, prefeito no nível 20, gasolina, primeira missão, estampas, loja de roupas e joias,
-- nível máximo 50, carros 20% mais caros e oficina para personalizar o carro.

-- ===================== ETAPA 13: sede e comidas novas =====================
alter table public.moradores add column if not exists sede numeric not null default 100;
alter table public.loja add column if not exists sede integer not null default 0;   -- quanto mata a sede

-- bebidas que já existiam agora matam a sede
update public.loja set sede = 25 where id = 'cerveja';
update public.loja set sede = 10 where id = 'pinga';
update public.loja set sede = 30 where id = 'guarana';
update public.loja set sede = 12 where id = 'cafe';
update public.loja set sede = 25 where id = 'rodada';

-- comidas e bebidas novas (baratas)
insert into public.loja(id, tipo, nome, preco, local, fome, sede, nivel_min) values
  ('agua',      'consumo', 'uma garrafa de água',     3, 'mercadinho',  0, 40, 1),
  ('banana',    'consumo', 'um cacho de banana',      3, 'mercadinho', 10,  2, 1),
  ('laranja',   'consumo', 'umas laranjas',           4, 'mercadinho',  8, 15, 1),
  ('melancia',  'consumo', 'uma fatia de melancia',   5, 'mercadinho', 10, 25, 1),
  ('biscoito',  'consumo', 'um pacote de biscoito',   6, 'mercadinho', 15,  0, 1),
  ('queijo',    'consumo', 'um pedaço de queijo',     9, 'mercadinho', 22,  0, 1),
  ('sanduiche', 'consumo', 'um sanduíche natural',   12, 'mercadinho', 32,  5, 1),
  ('suco',      'consumo', 'um suco de laranja',      6, 'padaria',     4, 35, 1),
  ('agua_bar',  'consumo', 'um copo de água',         2, 'bar',         0, 30, 1)
on conflict (id) do update set nome = excluded.nome, preco = excluded.preco, local = excluded.local,
  fome = excluded.fome, sede = excluded.sede;

-- fome e sede caem juntas (a sede um pouco mais rápido). Se uma das duas zerar, desmaia.
create or replace function public._gastar_fome(p_id uuid, p_custo numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare m public.moradores; f numeric; s numeric; seg numeric; base integer; ritmo numeric;
begin
  select * into m from moradores where id = p_id for update;
  ritmo := case when m.vip_ate > now() then 0.7 else 1 end;
  seg := least(extract(epoch from (now() - m.fome_em)), 90);
  f := m.fome - seg / 120.0 * ritmo - p_custo;
  s := m.sede - seg / 90.0 * ritmo - p_custo * 0.8;
  if f <= 0 or s <= 0 then
    base := xp_do_nivel(m.nivel);
    update moradores set fome = 50, sede = 50, fome_em = now(), visto_em = now(),
      xp = base + floor((m.xp - base) * 0.7), dinheiro = greatest(0, dinheiro - 30),
      mortes = mortes + 1, trabalho = null, trabalho_inicio = null
    where id = p_id;
    return true;
  end if;
  update moradores set fome = least(100, f), sede = least(100, s), fome_em = now(), visto_em = now() where id = p_id;
  return false;
end $$;
revoke execute on function public._gastar_fome(uuid, numeric) from authenticated, anon, public;

create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'sede', round(sede, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;
revoke execute on function public._estado(uuid) from authenticated;

create or replace function public.comprar(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; morreu boolean;
begin
  m := _eu();
  select * into i from loja where id = p_item and tipo = 'consumo';
  if not found then raise exception 'Isso não está à venda.'; end if;
  if m.nivel < i.nivel_min then raise exception 'Libera no nível %.', i.nivel_min; end if;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente. Vai trabalhar! 😅'; end if;
  morreu := _gastar_fome(m.id, 0);
  update moradores set dinheiro = dinheiro - i.preco, fome = least(100, fome + i.fome), sede = least(100, sede + i.sede) where id = m.id;
  return json_build_object('item', i.id, 'preco', i.preco, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

create or replace function public.usar_item(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; q integer; morreu boolean;
begin
  m := _eu();
  q := coalesce((m.mochila->>p_item)::integer, 0);
  if q <= 0 then raise exception 'Você não tem isso na mochila.'; end if;
  select * into i from loja where id = p_item;
  morreu := _gastar_fome(m.id, 0);
  update moradores set fome = least(100, fome + coalesce(i.fome, 0)), sede = least(100, sede + coalesce(i.sede, 0)),
    mochila = case when q > 1 then mochila || jsonb_build_object(p_item, q - 1) else mochila - p_item end
  where id = m.id;
  return json_build_object('item', p_item, 'mochila', (select mochila from moradores where id = m.id), 'morreu', morreu, 'eu', _estado(m.id));
end $$;
grant execute on function public.usar_item(text) to authenticated;

-- ===================== ETAPA 14: prefeito só no nível 20 =====================
update public.trabalhos set nivel_min = 20 where id = 'prefeito';

drop trigger if exists prefeito_top1 on public.moradores;
drop function if exists public._atualiza_prefeito() cascade;

create function public._atualiza_prefeito() returns trigger
language plpgsql security definer set search_path = public as $$
declare novo uuid;
begin
  select id into novo from moradores
   where nivel >= 20 and not coalesce(banido, false)
   order by xp desc, id limit 1;
  insert into cidade(id, prefeito, desde) values (1, novo, case when novo is null then null else now() end)
  on conflict (id) do update set prefeito = excluded.prefeito,
    desde = case when cidade.prefeito is distinct from excluded.prefeito then excluded.desde else cidade.desde end
  where cidade.prefeito is distinct from excluded.prefeito;
  return null;
end $$;
revoke execute on function public._atualiza_prefeito() from authenticated, anon, public;

create trigger prefeito_top1 after insert or update of xp, nivel, banido or delete on public.moradores
for each statement execute function public._atualiza_prefeito();



-- ===================== ETAPA 15: gasolina =====================
alter table public.moradores add column if not exists gasolina numeric not null default 100;

-- preço do tanque cheio de cada carro
create or replace function public._preco_tanque(p_carro text) returns integer
language sql immutable as $$
  select case when p_carro = 'moto' then 120
              when p_carro in ('fusca','kombi','fusca_ouro') then 220
              when p_carro in ('opala','caminhonete','kombi_tonhao') then 300
              else 380 end
$$;

-- o jogo avisa quanto de gasolina sobrou (só pode diminuir)
create or replace function public.salvar_gasolina(p_nivel numeric) returns void
language plpgsql security definer set search_path = public as $$
begin
  update moradores set gasolina = greatest(0, least(gasolina, coalesce(p_nivel, gasolina))) where id = auth.uid();
end $$;
grant execute on function public.salvar_gasolina(numeric) to authenticated;

-- encher o tanque no posto
create or replace function public.abastecer(p_nivel numeric) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; g numeric; custo integer;
begin
  m := _eu();
  if coalesce(array_length(m.carros, 1), 0) = 0 then raise exception 'Você não tem carro.'; end if;
  g := greatest(0, least(m.gasolina, coalesce(p_nivel, m.gasolina)));
  if g >= 99 then raise exception 'O tanque já está cheio.'; end if;
  custo := greatest(2, ceil(_preco_tanque(coalesce(m.carro, m.carros[1])) * (100 - g) / 100.0));
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', custo; end if;
  update moradores set dinheiro = dinheiro - custo, gasolina = 100 where id = m.id;
  return json_build_object('custo', custo, 'eu', _estado(m.id));
end $$;
grant execute on function public.abastecer(numeric) to authenticated;

create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'sede', round(sede, 1), 'gasolina', round(gasolina, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;
revoke execute on function public._estado(uuid) from authenticated;


-- ===================== ETAPA 12: coluna da primeira missão (0, 1, 2) =====================
do $$ begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'moradores' and column_name = 'missao') then
    alter table public.moradores add column missao smallint not null default 0;
    update public.moradores set missao = 2 where xp > 0 or nivel > 1;
  end if;
end $$;

-- ===================== ETAPA 16: bônus da primeira missão = R$ 100 =====================
create or replace function public.missao_passo(p_passo integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; bonus integer := 0;
begin
  m := _eu();
  if p_passo = 1 then
    if m.missao <> 0 then raise exception 'Essa missão já foi feita.'; end if;
    if m.xp <= 0 then raise exception 'Faça uma tarefa de trabalho primeiro.'; end if;
    bonus := 100;
    update moradores set dinheiro = dinheiro + bonus, missao = 1 where id = m.id;
  else
    if m.missao >= 2 then raise exception 'Essa missão já foi feita.'; end if;
    update moradores set missao = 2 where id = m.id;
  end if;
  return json_build_object('missao', (select missao from moradores where id = m.id), 'bonus', bonus, 'eu', _estado(m.id));
end $$;
grant execute on function public.missao_passo(integer) to authenticated;

select c.prefeito, m.nome, m.nivel from public.cidade c left join public.moradores m on m.id = c.prefeito;

-- ===================== ETAPA 17: estampas, loja de roupas e joias =====================
-- visual maior (campo novo Estampa e os próximos)
alter table public.moradores drop constraint if exists moradores_visual_check;
alter table public.moradores add constraint moradores_visual_check check (visual ~ '^(TH[0-9]{7,30}|TJ[0-9]{20,60})$') not valid;
-- (a função criar_morador com a regra de 60 dígitos vai junto na etapa 13, com a conferência do guarda-roupa)

-- guarda-roupa: peças compradas na Tonhão Wear
create table if not exists public.guarda_roupa (
  morador uuid not null references public.moradores(id) on delete cascade,
  peca text not null,          -- roupa_m, roupa_f, calca_m, calca_f, calcado_m, calcado_f, chapeu_m, chapeu_f, extra_m, extra_f (joias), estampa
  item integer not null,
  comprado_em timestamptz not null default now(),
  primary key (morador, peca, item)
);
alter table public.guarda_roupa enable row level security;
drop policy if exists "ver meu guarda-roupa" on public.guarda_roupa;
create policy "ver meu guarda-roupa" on public.guarda_roupa for select to authenticated using (morador = auth.uid());
revoke insert, update, delete on public.guarda_roupa from anon, authenticated;

-- preço igual ao do jogo: as 4 primeiras grátis (2 na estampa), depois R$ 30 subindo 15% por peça; joias e coroa (itens 40 a 49) com preço fixo
create or replace function public.preco_roupa(p_peca text, p_item integer) returns integer
language sql immutable as $$
  select case
    when p_item >= 40 then coalesce((case p_peca
      when 'chapeu_m' then array[50000] when 'chapeu_f' then array[50000]
      when 'extra_m' then array[3000,10000,8000,6000] when 'extra_f' then array[3000,10000,8000,4000,15000,20000,7000] end)[p_item - 39], 999999)
    when p_item < (case when p_peca = 'estampa' then 2 else 4 end) then 0
    else (round(30 * power(1.15, p_item - (case when p_peca = 'estampa' then 2 else 4 end)) / 10) * 10)::integer end
$$;

create or replace function public.comprar_roupa(p_peca text, p_item integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; pr integer;
begin
  m := _eu();
  if p_peca not in ('roupa_m','roupa_f','calca_m','calca_f','calcado_m','calcado_f','chapeu_m','chapeu_f','extra_m','extra_f','estampa') then raise exception 'Peça inválida.'; end if;
  if p_item < 0 or p_item >= 50 then raise exception 'Peça inválida.'; end if;
  if exists (select 1 from guarda_roupa where morador = m.id and peca = p_peca and item = p_item) then return json_build_object('ok', true, 'eu', _estado(m.id)); end if;
  pr := preco_roupa(p_peca, p_item);
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente.'; end if;
  insert into guarda_roupa(morador, peca, item) values (m.id, p_peca, p_item);
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  return json_build_object('ok', true, 'eu', _estado(m.id));
end $$;
grant execute on function public.comprar_roupa(text, integer) to authenticated;

-- ===================== ETAPA 18: nível máximo 50 =====================
create or replace function public.nivel_de(p_xp integer) returns integer
language plpgsql immutable as $$
declare n integer := greatest(1, floor((1 + sqrt(1 + 4.0 * greatest(p_xp, 0) / 25)) / 2)::integer);
begin
  while public.xp_do_nivel(n + 1) <= p_xp loop n := n + 1; end loop;
  while n > 1 and public.xp_do_nivel(n) > p_xp loop n := n - 1; end loop;
  return least(n, 50);  -- nível máximo
end $$;

-- quem estava travado no 20 sobe conforme o XP que já tem
update public.moradores set nivel = public.nivel_de(xp) where public.nivel_de(xp) > nivel;

-- confere: quantos jogadores em cada nível
select nivel, count(*) as jogadores from public.moradores group by nivel order by nivel desc;

-- ===================== ETAPA 19: carros 20% mais caros =====================
update public.loja set preco = 2200 where id = 'moto' and tipo = 'carro';
update public.loja set preco = 3600 where id = 'fusca' and tipo = 'carro';
update public.loja set preco = 6600 where id = 'kombi' and tipo = 'carro';
update public.loja set preco = 14400 where id = 'opala' and tipo = 'carro';
update public.loja set preco = 30000 where id = 'caminhonete' and tipo = 'carro';
update public.loja set preco = 54000 where id = 'sedan' and tipo = 'carro';
update public.loja set preco = 84000 where id = 'jipe' and tipo = 'carro';
update public.loja set preco = 144000 where id = 'esportivo' and tipo = 'carro';

-- ===================== ETAPA 20: oficina (personalizar o carro) =====================
alter table public.moradores add column if not exists carro_mods jsonb not null default '{}'::jsonb;

-- preços iguais aos do jogo; só paga o que mudou
create or replace function public.personalizar_carro(p_carro text, p_cor text, p_roda integer, p_vidro integer, p_pintura integer, p_som boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; at jsonb; custo integer := 0;
  pr_roda integer[] := array[0,2000,4000,8000,3000]; pr_vidro integer[] := array[0,800,1500,2500]; pr_pint integer[] := array[0,2500,4000,6000];
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  if p_roda not between 0 and 4 or p_vidro not between 0 and 3 or p_pintura not between 0 and 3 then raise exception 'Opção inválida.'; end if;
  if p_cor is not null and p_cor !~ '^#[0-9a-fA-F]{6}$' then raise exception 'Cor inválida.'; end if;
  at := coalesce(m.carro_mods->p_carro, '{}'::jsonb);
  if p_cor is not null and p_cor is distinct from (m.carro_cores->>p_carro) then custo := custo + 1000; end if;
  if p_roda <> coalesce((at->>'roda')::int, 0) then custo := custo + pr_roda[p_roda + 1]; end if;
  if p_vidro <> coalesce((at->>'vidro')::int, 0) then custo := custo + pr_vidro[p_vidro + 1]; end if;
  if p_pintura <> coalesce((at->>'pintura')::int, 0) then custo := custo + pr_pint[p_pintura + 1]; end if;
  if p_som and not coalesce((at->>'som')::boolean, false) then custo := custo + 5000; end if;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente.'; end if;
  update moradores set dinheiro = dinheiro - custo,
    carro_cores = case when p_cor is null then carro_cores else carro_cores || jsonb_build_object(p_carro, p_cor) end,
    carro_mods = carro_mods || jsonb_build_object(p_carro, jsonb_build_object('roda', p_roda, 'vidro', p_vidro, 'pintura', p_pintura, 'som', coalesce(p_som, false)))
  where id = m.id;
  return json_build_object('custo', custo, 'eu', _estado(m.id));
end $$;
grant execute on function public.personalizar_carro(text, text, integer, integer, integer, boolean) to authenticated;

-- quem vende o carro perde a personalização dele
create or replace function public._limpa_mods() returns trigger language plpgsql as $$
begin
  new.carro_mods := coalesce((select jsonb_object_agg(k, v) from jsonb_each(new.carro_mods) e(k, v) where k = any(new.carros)), '{}'::jsonb);
  return new;
end $$;
drop trigger if exists limpa_mods on public.moradores;
create trigger limpa_mods before update of carros on public.moradores for each row execute function public._limpa_mods();

select nome, preco from public.loja where tipo = 'carro' order by preco;
